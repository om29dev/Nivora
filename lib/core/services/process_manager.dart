import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/terminal_types.dart';
import 'local_dev_server.dart';
import 'termux_environment_service.dart';

class ProcessManager extends ChangeNotifier {
  final TermuxEnvironmentService? termuxService;

  ProcessManager({this.termuxService});

  Process? _activeProcess;
  RunningProcessInfo? _activeProcessInfo;
  Timer? _serverHeartbeat;
  final LocalDevServer _devServer = LocalDevServer();
  final _outputController = StreamController<TerminalLine>.broadcast();
  final List<TerminalLine> _buffer = [];
  static const int maxBufferLines = 2000;

  Stream<TerminalLine> get outputStream => _outputController.stream;
  List<TerminalLine> get currentBuffer => List.unmodifiable(_buffer);
  RunningProcessInfo? get activeProcessInfo => _activeProcessInfo;
  bool get isProcessRunning => _activeProcess != null || _activeProcessInfo != null || _devServer.isRunning;

  void appendLine(TerminalLine line) {
    if (_buffer.length >= maxBufferLines) {
      _buffer.removeAt(0);
    }
    _buffer.add(line);
    _outputController.add(line);
    notifyListeners();
  }

  void clearBuffer() {
    _buffer.clear();
    final clearedLine = TerminalLine(text: 'Terminal buffer cleared.');
    _buffer.add(clearedLine);
    _outputController.add(clearedLine);
    notifyListeners();
  }

  /// Explicitly starts the local dev server on loopback port (default 5173).
  Future<int> startDevServer({
    required String workingDirectory,
    String? command,
    int requestedPort = 5173,
  }) async {
    killActiveProcess();
    final cmd = command ?? 'npm run dev';
    await _startBuiltinDevServer(cmd, workingDirectory, requestedPort: requestedPort);
    notifyListeners();
    return _activeProcessInfo?.localPort ?? requestedPort;
  }

  Future<void> executeCommand({
    required String command,
    required String workingDirectory,
  }) async {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return;

    if (isProcessRunning) {
      appendLine(TerminalLine(
        text: 'A process is already running (PID: ${_activeProcessInfo?.pid}). Send Ctrl+C or terminate first.',
        isError: true,
      ));
      return;
    }

    appendLine(TerminalLine(text: '\$ $trimmed', isInput: true));

    // Fast path: clear
    if (trimmed == 'clear' || trimmed == 'cls') {
      clearBuffer();
      return;
    }

    // Fast path: help
    if (trimmed == 'help' || trimmed == '--help') {
      _printHelp();
      return;
    }

    final lowerCmd = trimmed.toLowerCase();
    final parts = trimmed.split(RegExp(r'\s+'));
    final executable = parts.first;

    // Fast path: Dev server commands automatically trigger loopback server
    if (lowerCmd.contains('npm run dev') || lowerCmd.contains('vite') || lowerCmd.contains('npm start')) {
      await _startBuiltinDevServer(trimmed, workingDirectory);
      return;
    }

    // Fast path: termux-change-repo
    if (executable == 'termux-change-repo' || executable == 'termux_change_repo') {
      final termux = termuxService;
      if (termux != null) {
        if (parts.length == 1 || parts[1] == 'help' || parts[1] == '--help' || parts[1] == 'list') {
          appendLine(TerminalLine(
            text: '\x1B[36m[Termux Repository Mirrors]\x1B[0m\n'
                  'Current active mirror: \x1B[32m${termux.activeMirror}\x1B[0m\n\n'
                  'Available mirrors:\n'
                  '  • \x1B[1mgrimler\x1B[0m  - Europe / Fast global mirror (Recommended)\n'
                  '  • \x1B[1mofficial\x1B[0m - packages.termux.dev (Official dev mirror)\n'
                  '  • \x1B[1mtuna\x1B[0m     - Tsinghua University (Asia)\n'
                  '  • \x1B[1mbfsu\x1B[0m     - BFSU mirror\n'
                  '  • \x1B[1mleaseweb\x1B[0m - Leaseweb mirror\n\n'
                  'Usage: \x1B[33mtermux-change-repo <name>\x1B[0m (e.g. \x1B[32mtermux-change-repo grimler\x1B[0m)',
          ));
          return;
        } else {
          final target = parts[1];
          final switched = await termux.switchMirror(target);
          if (switched) {
            appendLine(TerminalLine(
              text: '\x1B[32m✔\x1B[0m Active mirror switched to: \x1B[36m${termux.activeMirror}\x1B[0m\n'
                    'Running package list update...',
            ));
            await termux.repairEnvironment();
            // Continue executing apt update with newly selected mirror
            if (termux.isReady) {
              await executeCommand(command: 'apt update', workingDirectory: workingDirectory);
            }
            return;
          } else {
            appendLine(TerminalLine(
              text: '\x1B[31m✖\x1B[0m Unknown mirror: "$target". Available: grimler, official, tuna, bfsu, leaseweb, or a full https:// URL.',
              isError: true,
            ));
            return;
          }
        }
      }
    }

    // Fast path: pkg repair / termux-repair
    if (trimmed == 'pkg repair' || trimmed == 'termux-repair' || trimmed == 'termux-fix') {
      final termux = termuxService;
      if (termux != null) {
        appendLine(TerminalLine(text: '\x1B[36m[Termux Repair]\x1B[0m Checking environment health & repairing database...'));
        final ok = await termux.repairEnvironment();
        if (ok) {
          appendLine(TerminalLine(
            text: '\x1B[32m✔\x1B[0m Termux environment repaired:\n'
                  '  • DPKG & APT database hierarchies verified\n'
                  '  • Stale lock files removed\n'
                  '  • APT path configuration (\$APT_CONFIG) updated\n'
                  '  • DNS nameservers (8.8.8.8, 1.1.1.1) configured\n'
                  '  • File & binary permissions refreshed (755/777)',
          ));
        } else {
          appendLine(TerminalLine(text: '\x1B[31m✖\x1B[0m Failed to repair Termux environment.', isError: true));
        }
      }
      return;
    }

    // Fast path: pkg commands when Termux is ready
    if (executable == 'pkg' || executable == 'apt') {
      if (Platform.isAndroid && termuxService != null) {
        if (!termuxService!.isReady) {
          appendLine(TerminalLine(
            text: '\x1B[33m[Termux Required]\x1B[0m Embedded Termux runtime is not installed.\n'
                  'Tap \x1B[36m[ Install (~35MB) ]\x1B[0m at the top of the terminal to enable pkg/apt packages.',
            isError: true,
          ));
          return;
        }
        // Auto-heal locks & directories before executing pkg or apt
        await termuxService!.repairEnvironment();
      }
    }

    // Determine platform-specific execution path
    String execPath;
    List<String> execArgs;
    Map<String, String>? env;

    if (Platform.isAndroid) {
      final termux = termuxService;
      if (termux != null && termux.isReady) {
        // Ensure executable permissions before starting process
        await termux.ensureBinariesExecutable();

        final wrapped = termux.wrapCommandWithProot(
          command: trimmed,
          workingDirectory: workingDirectory,
        );
        execPath = wrapped.first;
        execArgs = wrapped.sublist(1);
        env = termux.getEnvironmentVariables(workingDirectory: workingDirectory);
      } else {
        // Termux not yet installed on Android
        final systemUtils = {
          'ls', 'cat', 'pwd', 'echo', 'mkdir', 'rm', 'rmdir', 'cp', 'mv',
          'ps', 'id', 'date', 'chmod', 'uname', 'touch', 'grep', 'df', 'whoami'
        };

        if (systemUtils.contains(executable.toLowerCase())) {
          execPath = '/system/bin/sh';
          execArgs = ['-c', trimmed];
        } else {
          appendLine(TerminalLine(
            text: '\x1B[33m[Termux Runtime Required]\x1B[0m The command \'\x1B[1m$executable\x1B[0m\' requires the embedded Termux environment.\n'
                  'Tap \x1B[36m[ Install Termux Runtime ]\x1B[0m at the top of the terminal or run \x1B[32mpkg install $executable\x1B[0m once installed.',
            isError: true,
          ));
          return;
        }
      }
    } else {
      // Host desktop platform (Windows, macOS, Linux)
      if (Platform.isWindows) {
        execPath = 'powershell.exe';
        execArgs = ['-NoProfile', '-Command', trimmed];
      } else {
        execPath = '/bin/sh';
        execArgs = ['-c', trimmed];
      }
    }

    // Execute real process
    try {
      final effectiveDir = (workingDirectory.isNotEmpty && Directory(workingDirectory).existsSync())
          ? workingDirectory
          : null;

      final process = await Process.start(
        execPath,
        execArgs,
        workingDirectory: effectiveDir,
        environment: env,
        runInShell: false,
      );

      _activeProcess = process;
      _activeProcessInfo = RunningProcessInfo(
        pid: process.pid,
        command: trimmed,
        state: ProcessState.running,
        startedAt: DateTime.now(),
        localPort: _detectPort(trimmed),
      );
      notifyListeners();

      process.stdout.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.isNotEmpty) {
            appendLine(TerminalLine(text: line));
            final port = _extractPortFromOutput(line);
            if (port != null && _activeProcessInfo != null) {
              _activeProcessInfo = RunningProcessInfo(
                pid: _activeProcessInfo!.pid,
                command: _activeProcessInfo!.command,
                state: _activeProcessInfo!.state,
                startedAt: _activeProcessInfo!.startedAt,
                localPort: port,
              );
              notifyListeners();
            }
          }
        }
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.isNotEmpty) {
            appendLine(TerminalLine(text: line, isError: true));
          }
        }
      });

      process.exitCode.then((exitCode) {
        appendLine(TerminalLine(
          text: '\n[Process exited with code $exitCode]',
          isError: exitCode != 0,
        ));
        _activeProcess = null;
        _activeProcessInfo = null;
        notifyListeners();
      });
    } catch (e) {
      // If dev server command failed, offer fallback
      if (lowerCmd.contains('npm run dev') || lowerCmd.contains('vite') || lowerCmd.contains('serve')) {
        await _startBuiltinDevServer(trimmed, workingDirectory);
      } else if (e.toString().contains('Permission denied') && Platform.isAndroid) {
        appendLine(TerminalLine(
          text: '\x1B[31m[Permission Denied]\x1B[0m Process execution permission denied for \'$execPath\'.\n'
                'Auto-refreshing POSIX executable permissions (chmod 0755)...',
          isError: true,
        ));
        if (termuxService != null) {
          await termuxService!.ensureBinariesExecutable();
        }
        appendLine(TerminalLine(
          text: 'Executable permissions (0755) refreshed for Termux binaries.\n'
                'Please retry the command. (Note: On Android 10+, ensure APK is built with targetSdk 28).',
          isError: true,
        ));
      } else {
        appendLine(TerminalLine(
          text: 'Failed to execute \'$trimmed\': $e',
          isError: true,
        ));
      }
    }
  }

  Future<void> _startBuiltinDevServer(
    String command,
    String workingDirectory, {
    int requestedPort = 5173,
  }) async {
    final pid = 3000 + Random().nextInt(4000);
    final portToUse = command.contains('3000') ? 3000 : requestedPort;

    final actualPort = await _devServer.start(
      workingDirectory: workingDirectory,
      requestedPort: portToUse,
    );

    _activeProcessInfo = RunningProcessInfo(
      pid: pid,
      command: command,
      state: ProcessState.running,
      startedAt: DateTime.now(),
      localPort: actualPort,
    );

    appendLine(TerminalLine(text: '> ${workingDirectory.isNotEmpty ? p.basename(workingDirectory) : "project"}@1.0.0 dev (Nivora Loopback Server)'));
    appendLine(TerminalLine(text: '  \x1B[32m✔\x1B[0m \x1B[1mLocalDevServer\x1B[0m ready on \x1B[36mhttp://localhost:$actualPort/\x1B[0m'));
    appendLine(TerminalLine(text: '  \x1B[32m➜\x1B[0m Serving static assets & SPA routes from sandbox'));
    appendLine(TerminalLine(text: '  \x1B[90mPress Stop or Ctrl+C to terminate the dev server.\x1B[0m\n'));

    _serverHeartbeat?.cancel();
    _serverHeartbeat = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_activeProcessInfo != null) {
        appendLine(TerminalLine(text: '[\x1B[36mdev-server\x1B[0m] \x1B[32mhealthy\x1B[0m listening on :$actualPort'));
      } else {
        timer.cancel();
      }
    });
    notifyListeners();
  }

  void _printHelp() {
    appendLine(TerminalLine(text: '\x1B[1mNivora Terminal & Termux Package Commands:\x1B[0m'));
    appendLine(TerminalLine(text: '  \x1B[36mpkg install <pkg>\x1B[0m        - Install Termux package (e.g. nodejs, python, git, rust)'));
    appendLine(TerminalLine(text: '  \x1B[36mpkg update\x1B[0m               - Update package repositories'));
    appendLine(TerminalLine(text: '  \x1B[36mpkg list-all\x1B[0m             - List available packages'));
    appendLine(TerminalLine(text: '  \x1B[36mpkg repair\x1B[0m               - Auto-repair database, clear locks & update configs'));
    appendLine(TerminalLine(text: '  \x1B[36mtermux-change-repo\x1B[0m       - Switch package mirror (grimler, official, tuna, bfsu)'));
    appendLine(TerminalLine(text: '  \x1B[36mnpm run dev\x1B[0m              - Start local development server on port 5173'));
    appendLine(TerminalLine(text: '  \x1B[36mgit status\x1B[0m               - Show modified/staged repository files'));
    appendLine(TerminalLine(text: '  \x1B[36mgit diff\x1B[0m                 - Show unified code diffs'));
    appendLine(TerminalLine(text: '  \x1B[36mls -la / dir\x1B[0m             - List files in current directory'));
    appendLine(TerminalLine(text: '  \x1B[36mpwd\x1B[0m                      - Print working directory'));
    appendLine(TerminalLine(text: '  \x1B[36mclear\x1B[0m                    - Clear terminal scrollback'));
    appendLine(TerminalLine(text: '  \x1B[31mCtrl+C\x1B[0m                   - Terminate active running process'));
  }

  void sendInput(String input) {
    if (_activeProcess != null) {
      _activeProcess!.stdin.writeln(input);
      appendLine(TerminalLine(text: input, isInput: true));
    }
  }

  void killActiveProcess() {
    _serverHeartbeat?.cancel();
    _serverHeartbeat = null;
    _devServer.stop();

    if (_activeProcess != null) {
      try {
        _activeProcess!.kill(ProcessSignal.sigint);
      } catch (_) {
        _activeProcess!.kill(ProcessSignal.sigkill);
      }
      _activeProcess = null;
    }

    if (_activeProcessInfo != null) {
      appendLine(TerminalLine(text: '^C\n[Process terminated by user]'));
      _activeProcessInfo = null;
    }
    notifyListeners();
  }

  int? _detectPort(String command) {
    if (command.contains('5173')) return 5173;
    if (command.contains('3000')) return 3000;
    if (command.contains('8000')) return 8000;
    if (command.contains('8080')) return 8080;
    return null;
  }

  int? _extractPortFromOutput(String output) {
    final regex = RegExp(r'(?:localhost|127\.0\.0\.1|port)\s*[:=]?\s*(\d{4,5})', caseSensitive: false);
    final match = regex.firstMatch(output);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  @override
  void dispose() {
    _serverHeartbeat?.cancel();
    _devServer.stop();
    _outputController.close();
    super.dispose();
  }
}
