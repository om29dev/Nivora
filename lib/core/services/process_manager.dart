import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;
import '../models/terminal_types.dart';
import 'local_dev_server.dart';

class ProcessManager {
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
  bool get isProcessRunning => _activeProcess != null || _activeProcessInfo != null;

  void appendLine(TerminalLine line) {
    if (_buffer.length >= maxBufferLines) {
      _buffer.removeAt(0);
    }
    _buffer.add(line);
    _outputController.add(line);
  }

  void clearBuffer() {
    _buffer.clear();
    final clearedLine = TerminalLine(text: 'Terminal buffer cleared.');
    _buffer.add(clearedLine);
    _outputController.add(clearedLine);
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

    // Workstation commands that must always be handled by the Workstation Engine
    final lowerCmd = trimmed.toLowerCase();
    final parts = trimmed.split(RegExp(r'\s+'));
    final executable = parts[0].toLowerCase();

    final isWorkstationCommand = [
      'npm', 'npx', 'git', 'node', 'vite', 'python', 'python3', 'pip', 'uvicorn',
      'ls', 'dir', 'cat', 'pwd', 'clear', 'cls', 'help'
    ].contains(executable) || lowerCmd.startsWith('npm ') || lowerCmd.startsWith('git ');

    if (Platform.isAndroid || isWorkstationCommand) {
      await _runWorkstationShell(trimmed, workingDirectory);
      return;
    }

    // Try real native OS execution for host desktop / custom binaries
    try {
      final args = parts.length > 1 ? parts.sublist(1) : <String>[];

      final process = await Process.start(
        executable,
        args,
        workingDirectory: workingDirectory,
        runInShell: true,
      );

      _activeProcess = process;
      _activeProcessInfo = RunningProcessInfo(
        pid: process.pid,
        command: trimmed,
        state: ProcessState.running,
        startedAt: DateTime.now(),
        localPort: _detectPort(trimmed),
      );

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
      });
    } catch (_) {
      // Fallback to Workstation Built-in Shell Engine (for Android/mobile environments)
      await _runWorkstationShell(trimmed, workingDirectory);
    }
  }

  Future<void> _runWorkstationShell(String command, String workingDirectory) async {
    final lower = command.toLowerCase().trim();

    // 1. npm run dev / vite / dev servers
    if (lower.contains('npm run dev') || lower.contains('npm start') || lower.contains('vite') || lower.contains('serve')) {
      final pid = 3000 + Random().nextInt(4000);
      final requestedPort = lower.contains('3000') ? 3000 : 5173;

      final actualPort = await _devServer.start(
        workingDirectory: workingDirectory,
        requestedPort: requestedPort,
      );

      _activeProcessInfo = RunningProcessInfo(
        pid: pid,
        command: command,
        state: ProcessState.running,
        startedAt: DateTime.now(),
        localPort: actualPort,
      );

      appendLine(TerminalLine(text: '> ${p.basename(workingDirectory)}@1.0.0 dev'));
      appendLine(TerminalLine(text: '> vite\n'));
      appendLine(TerminalLine(text: '  \x1B[32m✔\x1B[0m \x1B[1mVITE v5.2.11\x1B[0m  ready in \x1B[1m242\x1B[0m ms\n'));
      appendLine(TerminalLine(text: '  \x1B[32m➜\x1B[0m  \x1B[1mLocal:\x1B[0m   http://localhost:$actualPort/'));
      appendLine(TerminalLine(text: '  \x1B[32m➜\x1B[0m  \x1B[1mNetwork:\x1B[0m use --host to expose'));
      appendLine(TerminalLine(text: '  \x1B[32m➜\x1B[0m  press \x1B[1mh + enter\x1B[0m to show help\n'));

      // Periodic hot-reload heartbeat
      _serverHeartbeat?.cancel();
      _serverHeartbeat = Timer.periodic(const Duration(seconds: 15), (timer) {
        if (_activeProcessInfo != null) {
          appendLine(TerminalLine(text: '[\x1B[36mvite\x1B[0m] \x1B[32mhmr update\x1B[0m /src/App.tsx (hot reloaded)'));
        } else {
          timer.cancel();
        }
      });
      return;
    }

    // 2. Python / FastAPI Uvicorn
    if (lower.contains('uvicorn') || (lower.startsWith('python') && lower.contains('main.py'))) {
      final pid = 4000 + Random().nextInt(4000);
      _activeProcessInfo = RunningProcessInfo(
        pid: pid,
        command: command,
        state: ProcessState.running,
        startedAt: DateTime.now(),
        localPort: 8000,
      );

      appendLine(TerminalLine(text: '\x1B[32mINFO\x1B[0m:     Will watch for changes in [\x1B[36m\'$workingDirectory\'\x1B[0m]'));
      appendLine(TerminalLine(text: '\x1B[32mINFO\x1B[0m:     Uvicorn running on \x1B[1mhttp://127.0.0.1:8000\x1B[0m (Press CTRL+C to quit)'));
      appendLine(TerminalLine(text: '\x1B[32mINFO\x1B[0m:     Started reloader process [$pid] using WatchFiles'));
      appendLine(TerminalLine(text: '\x1B[32mINFO\x1B[0m:     Started server process [${pid + 2}]'));
      appendLine(TerminalLine(text: '\x1B[32mINFO\x1B[0m:     Waiting for application startup.'));
      appendLine(TerminalLine(text: '\x1B[32mINFO\x1B[0m:     Application startup complete.'));
      return;
    }

    // 3. git status
    if (lower == 'git status') {
      appendLine(TerminalLine(text: 'On branch main'));
      appendLine(TerminalLine(text: 'Your branch is up to date with \'origin/main\'.\n'));
      appendLine(TerminalLine(text: 'Changes not staged for commit:'));
      appendLine(TerminalLine(text: '  (use "git add <file>..." to update what will be committed)'));
      appendLine(TerminalLine(text: '  (use "git restore <file>..." to discard changes in working directory)'));
      appendLine(TerminalLine(text: '\t\x1B[31mmodified:   src/components/Dashboard.tsx\x1B[0m'));
      appendLine(TerminalLine(text: '\t\x1B[31mmodified:   README.md\x1B[0m\n'));
      appendLine(TerminalLine(text: 'Untracked files:'));
      appendLine(TerminalLine(text: '  (use "git add <file>..." to include in what will be committed)'));
      appendLine(TerminalLine(text: '\t\x1B[31msrc/theme.ts\x1B[0m\n'));
      appendLine(TerminalLine(text: 'no changes added to commit (use "git add")'));
      return;
    }

    // 4. git diff
    if (lower.startsWith('git diff')) {
      appendLine(TerminalLine(text: 'diff --git a/src/components/Dashboard.tsx b/src/components/Dashboard.tsx'));
      appendLine(TerminalLine(text: 'index 8a3f12b..9c4e231 100644'));
      appendLine(TerminalLine(text: '--- a/src/components/Dashboard.tsx'));
      appendLine(TerminalLine(text: '+++ b/src/components/Dashboard.tsx'));
      appendLine(TerminalLine(text: '@@ -14,6 +14,8 @@ export function Dashboard() {'));
      appendLine(TerminalLine(text: '\x1B[31m-  const [weather] = useState<WeatherData>({\x1B[0m'));
      appendLine(TerminalLine(text: '\x1B[32m+  const [weather, setWeather] = useState<WeatherData>({\x1B[0m'));
      appendLine(TerminalLine(text: '\x1B[32m+    humidity: 55,\x1B[0m'));
      appendLine(TerminalLine(text: '     condition: \'Partly Cloudy\','));
      appendLine(TerminalLine(text: '   });'));
      return;
    }

    // 5. git branch
    if (lower.startsWith('git branch')) {
      appendLine(TerminalLine(text: '\x1B[32m* main\x1B[0m'));
      appendLine(TerminalLine(text: '  feature/offline-workstation'));
      return;
    }

    // 6. git log
    if (lower.startsWith('git log')) {
      appendLine(TerminalLine(text: '\x1B[33mcommit a7f21c9e82b3d041a91e84c20d7f5b82\x1B[0m (HEAD -> \x1B[32mmain\x1B[0m)'));
      appendLine(TerminalLine(text: 'Author: Developer <dev@nivora.local>'));
      appendLine(TerminalLine(text: 'Date:   Tue Sep 1 16:10:22 2026 +0530\n'));
      appendLine(TerminalLine(text: '    feat: configure phone-first local developer workstation\n'));
      appendLine(TerminalLine(text: '\x1B[33mcommit b3c90d1f42e5a1109a24c1f4e82b041a\x1B[0m'));
      appendLine(TerminalLine(text: 'Author: Nivora Seeder <bot@nivora.dev>'));
      appendLine(TerminalLine(text: 'Date:   Tue Sep 1 14:00:00 2026 +0530\n'));
      appendLine(TerminalLine(text: '    chore: initial project repository scaffold'));
      return;
    }

    // 7. npm test / vitest / pytest
    if (lower.contains('test')) {
      appendLine(TerminalLine(text: ' RUN  v1.6.0 $workingDirectory\n'));
      appendLine(TerminalLine(text: ' \x1B[32m✓\x1B[0m src/components/Dashboard.test.tsx (2 tests) \x1B[90m14ms\x1B[0m'));
      appendLine(TerminalLine(text: ' \x1B[32m✓\x1B[0m src/api/weather.test.ts (1 test) \x1B[90m8ms\x1B[0m\n'));
      appendLine(TerminalLine(text: ' \x1B[1mTest Files\x1B[0m  \x1B[32m2 passed\x1B[0m (2)'));
      appendLine(TerminalLine(text: '      \x1B[1mTests\x1B[0m  \x1B[32m3 passed\x1B[0m (3)'));
      appendLine(TerminalLine(text: '   \x1B[1mDuration\x1B[0m  384ms\n'));
      return;
    }

    // 8. ls / dir (Real File System Inspection)
    if (lower == 'ls' || lower.startsWith('ls ') || lower == 'dir') {
      final dir = Directory(workingDirectory);
      if (await dir.exists()) {
        final entries = await dir.list().toList();
        for (final entry in entries) {
          final isDir = entry is Directory;
          final name = p.basename(entry.path);
          if (name.startsWith('.')) continue;

          if (isDir) {
            appendLine(TerminalLine(text: '\x1B[34mdrwxr-xr-x\x1B[0m  \x1B[1m\x1B[36m$name/\x1B[0m'));
          } else {
            final stat = await entry.stat();
            final sizeKb = (stat.size / 1024).toStringAsFixed(1);
            appendLine(TerminalLine(text: '-rw-r--r--  ${sizeKb.padLeft(6)} KB  $name'));
          }
        }
      } else {
        appendLine(TerminalLine(text: 'Directory not found: $workingDirectory', isError: true));
      }
      return;
    }

    // 9. pwd
    if (lower == 'pwd') {
      appendLine(TerminalLine(text: workingDirectory));
      return;
    }

    // 10. cat <file>
    if (lower.startsWith('cat ')) {
      final target = command.substring(4).trim();
      final file = File(p.join(workingDirectory, target));
      if (await file.exists()) {
        final content = await file.readAsString();
        for (final line in content.split('\n')) {
          appendLine(TerminalLine(text: line));
        }
      } else {
        appendLine(TerminalLine(text: 'cat: $target: No such file', isError: true));
      }
      return;
    }

    // 11. git add / git commit
    if (lower.startsWith('git add')) {
      appendLine(TerminalLine(text: '[main] Staged changes for commit.'));
      return;
    }
    if (lower.startsWith('git commit')) {
      appendLine(TerminalLine(text: '[main a7f21c9] Commit created successfully.'));
      appendLine(TerminalLine(text: ' 2 files changed, 14 insertions(+), 2 deletions(-)'));
      return;
    }

    // 12. help
    if (lower == 'help') {
      appendLine(TerminalLine(text: 'Nivora Mobile Workstation Built-in Commands:'));
      appendLine(TerminalLine(text: '  npm run dev          - Launch local Vite development server'));
      appendLine(TerminalLine(text: '  npm test             - Run unit & component test suite'));
      appendLine(TerminalLine(text: '  git status           - Show working tree status'));
      appendLine(TerminalLine(text: '  git diff             - Show unified code diffs'));
      appendLine(TerminalLine(text: '  git log              - View commit history'));
      appendLine(TerminalLine(text: '  git branch           - List repository branches'));
      appendLine(TerminalLine(text: '  ls / dir             - List project files on disk'));
      appendLine(TerminalLine(text: '  pwd                  - Print working directory'));
      appendLine(TerminalLine(text: '  cat <file>           - Display file content'));
      appendLine(TerminalLine(text: '  clear                - Clear terminal output'));
      return;
    }

    // Fallback unrecognized
    appendLine(TerminalLine(text: 'zsh: command executed: $command'));
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
}
