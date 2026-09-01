import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    final proc = ref.read(processManagerProvider);
    if (proc.currentBuffer.isEmpty) {
      final activeProject = ref.read(activeProjectProvider);
      proc.appendLine(TerminalLine(
        text: 'Nivora Integrated Terminal (Android)\nWorking directory: ${activeProject?.path ?? "~"}\nType commands or use shortcuts below.',
      ));
    }
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
    final activeProject = ref.read(activeProjectProvider);
    final proc = ref.read(processManagerProvider);

    if (activeProject != null) {
      proc.executeCommand(
        command: cmd,
        workingDirectory: activeProject.path,
      );
      setState(() {});
      _scrollToBottom();
    }
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

  @override
  Widget build(BuildContext context) {
    final proc = ref.watch(processManagerProvider);
    final lines = proc.currentBuffer;
    final activeProcess = proc.activeProcessInfo;

    return Scaffold(
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
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                  Text('Live Preview Ready', style: AppTypography.caption),
                ],
              ),
            ),
          ],

          // Terminal scrollback stream
          Expanded(
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

          // Shortcut bar
          Container(
            height: 38,
            color: AppColors.darkSurfaceElevated,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                _TerminalShortcut(label: 'npm run dev', onTap: () => _sendCommand('npm run dev')),
                _TerminalShortcut(label: 'git status', onTap: () => _sendCommand('git status')),
                _TerminalShortcut(label: 'git diff', onTap: () => _sendCommand('git diff')),
                _TerminalShortcut(label: 'npm test', onTap: () => _sendCommand('npm test')),
                _TerminalShortcut(label: 'ls', onTap: () => _sendCommand('ls')),
                _TerminalShortcut(label: 'git log', onTap: () => _sendCommand('git log')),
                _TerminalShortcut(label: 'git branch', onTap: () => _sendCommand('git branch')),
                _TerminalShortcut(label: 'pwd', onTap: () => _sendCommand('pwd')),
                _TerminalShortcut(label: 'clear', onTap: () => _sendCommand('clear')),
                _TerminalShortcut(label: 'Ctrl+C', onTap: _sendCtrlC, isDanger: true),
              ],
            ),
          ),

          // Interactive input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.darkSurface,
              border: Border(top: BorderSide(color: AppColors.darkBorder)),
            ),
            child: Row(
              children: [
                Text('❯ ', style: AppTypography.terminal.copyWith(color: AppColors.electricCyan, fontWeight: FontWeight.bold)),
                Expanded(
                  child: TextField(
                    controller: _cmdController,
                    focusNode: _focusNode,
                    style: AppTypography.terminal,
                    cursorColor: AppColors.electricCyan,
                    decoration: const InputDecoration(
                      hintText: 'Enter command...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
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
                  onPressed: () => _sendCommand(),
                ),
              ],
            ),
          ),
        ],
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
