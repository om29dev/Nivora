import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/terminal_types.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_chip.dart';
import '../../core/widgets/nivora_terminal_line.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  final String projectId;

  const TerminalScreen({super.key, required this.projectId});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final TextEditingController _cmdController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isInstallingTermux = false;
  double _installProgress = 0.0;
  String _installStatusText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final proc = ref.read(processManagerProvider);
      final termux = ref.read(termuxEnvironmentServiceProvider);

      if (proc.currentBuffer.isEmpty) {
        final activeProject = ref.read(activeProjectProvider);
        final termuxNote = Platform.isAndroid
            ? (termux.isReady
                ? 'Termux Runtime: Ready (${termux.detectedArchitecture})\nType "pkg install <name>" to install packages.'
                : 'Termux Runtime: Not installed. Tap "Install Termux" above to enable pkg/apt packages.')
            : 'Host Environment: Genuine OS Process Execution Active';

        proc.appendLine(TerminalLine(
          text: 'Nivora Integrated Terminal\nWorking directory: ${activeProject?.path ?? "~"}\n$termuxNote',
        ));
      }
    });
  }

  @override
  void dispose() {
    _cmdController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendCommand([String? overrideCmd]) {
    final cmd = overrideCmd ?? _cmdController.text.trim();
    if (cmd.isEmpty) return;

    _cmdController.clear();
    final proc = ref.read(processManagerProvider);
    final activeProject = ref.read(activeProjectProvider);
    final projects = ref.read(projectsListProvider);
    final termux = ref.read(termuxEnvironmentServiceProvider);

    // Resolve working directory reliably
    String workingDir = '';
    if (activeProject != null && activeProject.path.isNotEmpty) {
      workingDir = activeProject.path;
    } else {
      final matches = projects.where((p) => p.id == widget.projectId);
      if (matches.isNotEmpty && matches.first.path.isNotEmpty) {
        workingDir = matches.first.path;
      } else if (projects.isNotEmpty && projects.first.path.isNotEmpty) {
        workingDir = projects.first.path;
      } else if (termux.isReady) {
        workingDir = termux.homePath;
      }
    }

    proc.executeCommand(
      command: cmd,
      workingDirectory: workingDir,
    );
    setState(() {});
    _scrollToBottom();
  }

  void _sendCtrlC() {
    final proc = ref.read(processManagerProvider);
    proc.killActiveProcess();
    setState(() {});
  }

  void _clearTerminal() {
    final proc = ref.read(processManagerProvider);
    proc.clearBuffer();
    setState(() {});
  }

  void _copyBuffer() {
    final proc = ref.read(processManagerProvider);
    final text = proc.currentBuffer.map((l) => l.text).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terminal output copied to clipboard.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _installTermux() async {
    if (_isInstallingTermux) return;

    setState(() {
      _isInstallingTermux = true;
      _installProgress = 0.05;
      _installStatusText = 'Starting bootstrap download...';
    });

    final proc = ref.read(processManagerProvider);
    final termux = ref.read(termuxEnvironmentServiceProvider);

    proc.appendLine(TerminalLine(
      text: '\x1B[36m[Termux Installer]\x1B[0m Initializing embedded Termux environment (${termux.detectedArchitecture})...',
    ));

    final success = await termux.installEnvironment(
      onProgress: (msg, prog) {
        if (mounted) {
          setState(() {
            _installProgress = prog;
            _installStatusText = msg;
          });
        }
        proc.appendLine(TerminalLine(text: '[\x1B[33minstall\x1B[0m] $msg'));
        _scrollToBottom();
      },
    );

    if (mounted) {
      setState(() {
        _isInstallingTermux = false;
      });
    }

    if (success) {
      proc.appendLine(TerminalLine(
        text: '\x1B[32m✔\x1B[0m \x1B[1mTermux runtime installed successfully!\x1B[0m Packages (pkg, apt, nodejs, python, git) are ready to use.',
      ));
    } else {
      proc.appendLine(TerminalLine(
        text: '\x1B[31m✖\x1B[0m Failed to install Termux runtime: ${termux.statusMessage}',
        isError: true,
      ));
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final proc = ref.watch(processManagerProvider);
    final termux = ref.watch(termuxEnvironmentServiceProvider);
    final lines = proc.currentBuffer;
    final activeProcess = proc.activeProcessInfo;

    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: AppColors.terminalBackground,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Project',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/project/${widget.projectId}');
            }
          },
        ),
        title: const Text('Terminal'),
        actions: [
          if (activeProcess != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: NivoraChip(
                label: 'PID: ${activeProcess.pid}',
                color: AppColors.electricCyan,
              ),
            ),
            IconButton(
              tooltip: 'Send Ctrl+C',
              icon: const Icon(Icons.cancel_outlined, color: AppColors.coralRed),
              onPressed: _sendCtrlC,
            ),
          ],
          IconButton(
            tooltip: 'Copy Output',
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: _copyBuffer,
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            onPressed: _clearTerminal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Termux Install banner pinned on top until installed
          if (!termux.isReady && !_isInstallingTermux) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.darkSurfaceElevated,
                border: Border(bottom: BorderSide(color: AppColors.darkBorder, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.electricCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.download_rounded, size: 18, color: AppColors.electricCyan),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Self-Contained Termux Runtime',
                          style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Install pkg, apt, node, python & git without Termux app',
                          style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricCyan,
                      foregroundColor: AppColors.darkBackground,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _installTermux,
                    child: const Text('Install (~35MB)'),
                  ),
                ],
              ),
            ),
          ],

          // Installation progress bar
          if (_isInstallingTermux) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.darkSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_installStatusText, style: AppTypography.caption.copyWith(color: AppColors.amberWarning)),
                      Text('${(_installProgress * 100).toInt()}%', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: _installProgress,
                    backgroundColor: AppColors.darkBorder,
                    color: AppColors.electricCyan,
                  ),
                ],
              ),
            ),
          ],

          // Port / Running status banner if port detected
          if (activeProcess?.localPort != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.electricCyan.withAlpha(30),
              child: Row(
                children: [
                  const Icon(Icons.wifi_tethering_rounded, size: 16, color: AppColors.electricCyan),
                  const SizedBox(width: 8),
                  Text(
                    'Local server detected on port ${activeProcess!.localPort}',
                    style: AppTypography.caption.copyWith(color: AppColors.electricCyan, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/project/${widget.projectId}/run'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 24)),
                    child: Text('Live Preview', style: AppTypography.caption.copyWith(color: AppColors.electricCyan, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],

          // Terminal scrollback stream
          Expanded(
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              behavior: HitTestBehavior.translucent,
              child: StreamBuilder<TerminalLine>(
                stream: proc.outputStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _scrollToBottom();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: lines.length,
                    itemBuilder: (ctx, idx) => NivoraTerminalLineWidget(line: lines[idx]),
                  );
                },
              ),
            ),
          ),

          // Shortcut bar
          Container(
            height: 38,
            color: AppColors.darkSurfaceElevated,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                _TerminalShortcut(label: 'pkg update', onTap: () => _sendCommand('pkg update')),
                _TerminalShortcut(label: 'pkg install nodejs', onTap: () => _sendCommand('pkg install nodejs')),
                _TerminalShortcut(label: 'pkg install python', onTap: () => _sendCommand('pkg install python')),
                _TerminalShortcut(label: 'pkg install git', onTap: () => _sendCommand('pkg install git')),
                _TerminalShortcut(label: 'npm run dev', onTap: () => _sendCommand('npm run dev')),
                _TerminalShortcut(label: 'git status', onTap: () => _sendCommand('git status')),
                _TerminalShortcut(label: 'git diff', onTap: () => _sendCommand('git diff')),
                _TerminalShortcut(label: 'ls -la', onTap: () => _sendCommand('ls -la')),
                _TerminalShortcut(label: 'pwd', onTap: () => _sendCommand('pwd')),
                _TerminalShortcut(label: 'help', onTap: () => _sendCommand('help')),
                _TerminalShortcut(label: 'clear', onTap: () => _sendCommand('clear')),
                _TerminalShortcut(label: 'Ctrl+C', onTap: _sendCtrlC, isDanger: true),
              ],
            ),
          ),

          // Interactive input bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(top: BorderSide(color: AppColors.darkBorder)),
              ),
              child: Row(
                children: [
                  Text(
                    '> ',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 16,
                      color: AppColors.electricCyan,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _cmdController,
                      focusNode: _focusNode,
                      enabled: true,
                      textInputAction: TextInputAction.send,
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: AppTypography.terminal.copyWith(color: AppColors.textCode, fontSize: 13),
                      cursorColor: AppColors.electricCyan,
                      cursorWidth: 2.0,
                      decoration: const InputDecoration(
                        hintText: 'Enter command (e.g. pkg install python, git status)...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.darkSurface,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                      onSubmitted: (val) => _sendCommand(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, size: 18, color: AppColors.electricCyan),
                    tooltip: 'Send Command',
                    onPressed: () => _sendCommand(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _TerminalShortcut extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _TerminalShortcut({
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(
          label,
          style: AppTypography.terminal.copyWith(
            fontSize: 11,
            color: isDanger ? AppColors.coralRed : AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.darkSurface,
        side: BorderSide(
          color: isDanger ? AppColors.coralRed.withAlpha(100) : AppColors.darkBorder,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        onPressed: onTap,
      ),
    );
  }
}
