import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/ai/tool_registry.dart';
import '../../core/models/ai_types.dart';
import '../../core/models/repository_summary.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_agent_step.dart';
import '../../core/widgets/nivora_ai_message.dart';
import '../../core/widgets/nivora_bottom_sheet.dart';
import '../../core/widgets/nivora_button.dart';
import '../../core/widgets/nivora_diff_viewer.dart';
import '../../core/widgets/nivora_input.dart';

class ChatSession {
  final String id;
  String title;
  final DateTime timestamp;
  final List<Map<String, dynamic>> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.messages,
  });
}

class AIAssistantScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String? initialPrompt;

  const AIAssistantScreen({
    super.key,
    required this.projectId,
    this.initialPrompt,
  });

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  final FocusNode _promptFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<AgentStep> _currentSteps = [];
  bool _isBusy = false;
  ProposedDiff? _pendingDiff;

  // Multi-chat sessions
  final List<ChatSession> _previousSessions = [];
  late String _currentSessionId;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _currentSessionId = 'chat-${DateTime.now().millisecondsSinceEpoch}';

    _initDefaultSession();

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitPrompt(widget.initialPrompt!);
      });
    }
  }

  void _initDefaultSession() {
    final activeProject = ref.read(activeProjectProvider);
    final intel = ref.read(projectIntelligenceProvider);

    final stackName = activeProject?.language ?? 'TypeScript / React';
    final repoName = activeProject?.name ?? 'Repository';
    final symbolCount = intel.symbols.length;
    final fileCount = intel.scannedFiles.length;

    _messages = [
      {
        'isUser': false,
        'text':
            'Hi! I am the Nivora Agent. I have scanned the repository documentation (`README.md`) and indexed **$repoName**.\n\n'
            '📋 **Detected Stack:** $stackName (${activeProject?.runtime ?? "Node.js"})\n'
            '🔍 **Repository Intelligence:** $symbolCount symbols mapped across $fileCount project files.\n\n'
            '💡 **Recommended Enhancements:**\n'
            '1. Add persistent dark/light theme state\n'
            '2. Implement offline mock sensor telemetry\n'
            '3. Optimize component state caching and build output\n\n'
            'Tap any quick suggestion below or ask me to inspect, refactor, or test!',
      }
    ];
  }

  @override
  void dispose() {
    _promptController.dispose();
    _promptFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startNewChat() {
    if (_messages.length > 1) {
      final firstUserMsg = _messages.firstWhere(
        (m) => m['isUser'] == true,
        orElse: () => {'text': 'Repository Analysis'},
      );
      String title = firstUserMsg['text'] as String;
      if (title.length > 30) title = '${title.substring(0, 30)}...';

      _previousSessions.insert(
        0,
        ChatSession(
          id: _currentSessionId,
          title: title,
          timestamp: DateTime.now(),
          messages: List.from(_messages),
        ),
      );
    }

    setState(() {
      _currentSessionId = 'chat-${DateTime.now().millisecondsSinceEpoch}';
      _pendingDiff = null;
      _currentSteps.clear();
      _initDefaultSession();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Started a fresh conversation.'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.electricCyan,
      ),
    );
  }

  void _loadSession(ChatSession session) {
    setState(() {
      _currentSessionId = session.id;
      _messages = List.from(session.messages);
      _pendingDiff = null;
      _currentSteps.clear();
    });
    Navigator.of(context).pop();
  }

  void _editPreviousMessage(String text) {
    _promptController.text = text;
    _promptFocusNode.requestFocus();
    _promptController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  Future<void> _submitPrompt([String? overrideText]) async {
    final text = overrideText ?? _promptController.text.trim();
    if (text.isEmpty || _isBusy) return;

    _promptController.clear();
    setState(() {
      _messages.add({'isUser': true, 'text': text});
      _isBusy = true;
      _currentSteps.clear();
      _pendingDiff = null;
    });
    _scrollToBottom();

    final activeProject = ref.read(activeProjectProvider);
    if (activeProject == null) {
      setState(() {
        _isBusy = false;
        _messages.add({
          'isUser': false,
          'text': 'No active project selected. Please open a repository first.',
        });
      });
      _scrollToBottom();
      return;
    }

    final intel = ref.read(projectIntelligenceProvider);
    final aiProvider = ref.read(selectedAIProvider);
    final git = ref.read(gitServiceProvider);
    final patchEngine = ref.read(patchEngineProvider);
    final tools = ToolRegistry(
      projectRoot: activeProject.path,
      gitService: git,
      patchEngine: patchEngine,
    );
    final contextRetriever = ref.read(contextRetrieverProvider);

    try {
      final summary = intel.summary ??
          RepositorySummary(
            projectName: activeProject.name,
            purpose: 'Application workspace',
            techStack: [activeProject.language, activeProject.runtime],
            runtime: activeProject.runtime,
            packageManager: activeProject.packageManager,
            entryPoints: const ['src/main.tsx', 'src/App.tsx'],
            importantDirectories: const ['src', 'public'],
            detectedCommands: {
              'run': activeProject.runCommand ?? 'npm run dev',
              'build': activeProject.buildCommand ?? 'npm run build',
              'test': activeProject.testCommand ?? 'npm test',
            },
            dependencies: const [],
          );

      final contextDocs = await contextRetriever.retrieveContext(
        projectRoot: activeProject.path,
        userPrompt: text,
        summary: summary,
        scannedFiles: intel.scannedFiles,
        symbolIndex: intel.symbols,
      );

      final result = await aiProvider.executeTask(
        prompt: text,
        context: contextDocs,
        tools: tools,
        onStep: (step) {
          setState(() {
            final idx = _currentSteps.indexWhere((s) => s.description == step.description);
            if (idx >= 0) {
              _currentSteps[idx] = step;
            } else {
              _currentSteps.add(step);
            }
          });
        },
      );

      setState(() {
        _isBusy = false;
        if (result.diffs.isNotEmpty) {
          _pendingDiff = result.diffs.first;
        }

        _messages.add({
          'isUser': false,
          'text': result.summary,
          'hasDiff': result.diffs.isNotEmpty,
        });
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isBusy = false;
        _messages.add({
          'isUser': false,
          'text': 'Error executing task: $e',
        });
      });
      _scrollToBottom();
    }
  }

  void _openDiffReview() {
    if (_pendingDiff == null) return;

    NivoraBottomSheet.show(
      context: context,
      title: 'Review Changes (${_pendingDiff!.filePath})',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: NivoraDiffViewer(diff: _pendingDiff!),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NivoraSecondaryButton(
                  text: 'Discard',
                  icon: Icons.close_rounded,
                  onPressed: () {
                    setState(() => _pendingDiff = null);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Changes discarded.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NivoraButton(
                  text: 'Keep & Apply',
                  icon: Icons.check_circle_outline_rounded,
                  backgroundColor: AppColors.emeraldGreen,
                  onPressed: () async {
                    final activeProject = ref.read(activeProjectProvider);
                    if (activeProject != null && _pendingDiff != null) {
                      final patchEngine = ref.read(patchEngineProvider);
                      await patchEngine.applyDiff(
                        projectRoot: activeProject.path,
                        diff: _pendingDiff!,
                      );
                      ref.invalidate(gitStatusProvider);

                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Applied patch to ${_pendingDiff!.filePath}'),
                            backgroundColor: AppColors.emeraldGreen,
                          ),
                        );
                        setState(() => _pendingDiff = null);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChatHistoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetBg = Theme.of(context).cardTheme.color ?? AppColors.surface(context);
        final borderColor = Theme.of(context).dividerTheme.color ?? AppColors.border(context);

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Chat History', style: AppTypography.h2Of(context)),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16, color: AppColors.electricCyan),
                    label: const Text('New Chat', style: TextStyle(color: AppColors.electricCyan, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _startNewChat();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_previousSessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No previous chat sessions yet.', style: AppTypography.bodySecondaryOf(context)),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _previousSessions.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (ctx, idx) {
                      final sess = _previousSessions[idx];
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.electricCyan),
                        title: Text(sess.title, style: AppTypography.bodyOf(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${sess.messages.length} messages',
                          style: AppTypography.captionOf(context),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _loadSession(sess),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppColors.electricCyan),
            const SizedBox(width: 8),
            Text('Nivora Agent', style: AppTypography.h3Of(context)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chat History',
            icon: const Icon(Icons.history_rounded),
            onPressed: _showChatHistoryModal,
          ),
          IconButton(
            tooltip: 'New Chat',
            icon: const Icon(Icons.add_comment_outlined, color: AppColors.electricCyan),
            onPressed: _startNewChat,
          ),
          IconButton(
            tooltip: 'Voice Coding',
            icon: const Icon(Icons.mic_none_rounded, color: AppColors.violetAccent),
            onPressed: () => context.push('/voice-coding'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Stream View
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, idx) {
                final msg = _messages[idx];
                final isUser = msg['isUser'] as bool;
                final hasDiff = msg['hasDiff'] == true;

                return NivoraAIMessage(
                  text: msg['text'] as String,
                  isUser: isUser,
                  onEdit: isUser ? () => _editPreviousMessage(msg['text'] as String) : null,
                  actionWidgets: hasDiff && _pendingDiff != null
                      ? [
                          NivoraButton(
                            text: 'Review Changes (${_pendingDiff!.filePath})',
                            icon: Icons.difference_outlined,
                            height: 38,
                            onPressed: _openDiffReview,
                          ),
                        ]
                      : null,
                );
              },
            ),
          ),

          // Real-time Agent Step progression if running
          if (_isBusy || _currentSteps.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ?? AppColors.surfaceElevated(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).dividerTheme.color ?? AppColors.border(context),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_outlined, size: 16, color: AppColors.electricCyan),
                      const SizedBox(width: 8),
                      Text(
                        'Agent Execution Pipeline',
                        style: AppTypography.captionOf(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._currentSteps.map((step) => NivoraAgentStepWidget(step: step)),
                ],
              ),
            ),
          ],

          // Quick Suggested Prompts
          Container(
            height: 36,
            margin: const EdgeInsets.only(top: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _SuggestionChip(
                  label: 'Add dark mode support',
                  onTap: () => _submitPrompt('Add dark mode support to the dashboard'),
                ),
                _SuggestionChip(
                  label: 'Add loading spinner',
                  onTap: () => _submitPrompt('Add a loading spinner state to main component'),
                ),
                _SuggestionChip(
                  label: 'Explain architecture',
                  onTap: () => _submitPrompt('Explain the project structure and architecture'),
                ),
              ],
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? AppColors.surface(context),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerTheme.color ?? AppColors.border(context),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: NivoraInput(
                    controller: _promptController,
                    focusNode: _promptFocusNode,
                    hintText: 'Ask agent to build, refactor, or test...',
                    prefixIcon: Icons.auto_awesome,
                    onSubmitted: (val) => _submitPrompt(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.electricCyan,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isBusy ? null : () => _submitPrompt(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          style: AppTypography.captionOf(context).copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.surfaceElevated(context),
        side: BorderSide(
          color: Theme.of(context).dividerTheme.color ?? AppColors.border(context),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        onPressed: onTap,
      ),
    );
  }
}
