import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/ai/ai_config.dart';
import '../../../core/intelligence/context_retriever.dart';
import '../../../core/models/repository_summary.dart';
import '../../../core/providers/app_providers.dart';

class DashboardQuickChatSheet extends ConsumerStatefulWidget {
  final String? initialPrompt;

  const DashboardQuickChatSheet({super.key, this.initialPrompt});

  static Future<void> show(BuildContext context, {String? initialPrompt}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DashboardQuickChatSheet(initialPrompt: initialPrompt),
    );
  }

  @override
  ConsumerState<DashboardQuickChatSheet> createState() => _DashboardQuickChatSheetState();
}

class _DashboardQuickChatSheetState extends ConsumerState<DashboardQuickChatSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initChat();
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialPrompt!);
      });
    }
  }

  void _initChat() {
    final aiConfig = ref.read(aiConfigProvider);
    final activeProject = ref.read(activeProjectProvider);
    final intel = ref.read(projectIntelligenceProvider);
    final repoName = activeProject?.name ?? 'General Workspace';
    final symbols = intel.symbols.length;

    _messages.add({
      'isUser': false,
      'text': '⚡ **Nivora Copilot** connected to **${aiConfig.model}**.\n\n'
          '📁 **Repository:** $repoName\n'
          '🔍 **Indexed Symbols:** $symbols AST declarations mapped\n\n'
          'Ask me anything about code implementation, architecture, debugging, or execution!',
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isGenerating) return;

    _textController.clear();
    setState(() {
      _messages.add({'isUser': true, 'text': clean});
      _isGenerating = true;
    });
    _scrollToBottom();

    final activeAI = ref.read(selectedAIProvider);
    final activeProject = ref.read(activeProjectProvider);
    final intel = ref.read(projectIntelligenceProvider);

    ProjectContext? projectContext;
    if (activeProject != null) {
      final summary = intel.summary ??
          RepositorySummary(
            projectName: activeProject.name,
            purpose: 'Application codebase',
            techStack: [activeProject.language, activeProject.runtime],
            runtime: activeProject.runtime,
            packageManager: activeProject.packageManager,
            entryPoints: const ['src/index.ts', 'src/main.ts'],
            importantDirectories: const ['src'],
            detectedCommands: {
              'run': activeProject.runCommand ?? 'npm run dev',
              'build': activeProject.buildCommand ?? 'npm run build',
              'test': activeProject.testCommand ?? 'npm test',
            },
            dependencies: const [],
          );

      projectContext = ProjectContext(
        summary: summary,
        files: [],
        matchedSymbols: intel.symbols,
        totalEstimatedTokens: 250,
      );
    }

    try {
      final history = <Map<String, String>>[];
      for (final m in _messages.take(_messages.length - 1)) {
        history.add({
          'role': m['isUser'] == true ? 'user' : 'assistant',
          'content': m['text'] as String,
        });
      }

      final response = await activeAI.generateConversationalResponse(
        prompt: clean,
        context: projectContext,
        conversationHistory: history,
      );

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _messages.add({'isUser': false, 'text': response});
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _messages.add({'isUser': false, 'text': '⚠️ Error generating completion: $e'});
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final aiConfig = ref.watch(aiConfigProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0F172A) : Colors.white).withAlpha(220),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: AppColors.electricCyan.withAlpha(isDark ? 80 : 40),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricCyan.withAlpha(isDark ? 35 : 15),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMutedOf(context).withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.electricCyan, AppColors.violetAccent],
                        ),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  aiConfig.providerType.displayName,
                                  style: AppTypography.h3Of(context).copyWith(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldGreen.withAlpha(25),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.emeraldGreen.withAlpha(70), width: 0.8),
                                ),
                                child: Text(
                                  aiConfig.mode == AIMode.local
                                      ? 'LOCAL ON-DEVICE'
                                      : 'LIVE API',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.emeraldGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            aiConfig.model,
                            style: AppTypography.captionOf(context).copyWith(
                              fontSize: 11,
                              color: AppColors.textMutedOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 20, color: AppColors.electricCyan),
                      tooltip: 'Configure AI Provider',
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/ai-setup');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = _messages[i];
                    final isUser = msg['isUser'] == true;
                    final text = msg['text'] as String;

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.84,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppColors.electricCyan.withAlpha(isDark ? 40 : 25)
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)).withAlpha(200),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(isUser ? 14 : 2),
                            bottomRight: Radius.circular(isUser ? 2 : 14),
                          ),
                          border: Border.all(
                            color: isUser
                                ? AppColors.electricCyan.withAlpha(80)
                                : (isDark ? Colors.white : Colors.black).withAlpha(16),
                          ),
                        ),
                        child: SelectableText(
                          text,
                          style: AppTypography.bodyOf(context).copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_isGenerating)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricCyan),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Generating response with ${aiConfig.model}...',
                        style: AppTypography.captionOf(context).copyWith(color: AppColors.electricCyan),
                      ),
                    ],
                  ),
                ),

              // Suggestion Chips
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _QuickChip(
                      label: '⚡ Architecture',
                      onTap: () => _sendMessage('Explain this repository architecture and tech stack'),
                    ),
                    const SizedBox(width: 8),
                    _QuickChip(
                      label: '🎨 Dark Theme',
                      onTap: () => _sendMessage('How do I implement dark mode in this project?'),
                    ),
                    const SizedBox(width: 8),
                    _QuickChip(
                      label: '🧪 Add Tests',
                      onTap: () => _sendMessage('Suggest a unit test suite setup for this codebase'),
                    ),
                    const SizedBox(width: 8),
                    _QuickChip(
                      label: '🔍 Find Entrypoints',
                      onTap: () => _sendMessage('What are the main entrypoints and routing in this project?'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Input Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurface : AppColors.lightSurface).withAlpha(180),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border(context),
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white).withAlpha(60),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: TextField(
                          controller: _textController,
                          style: AppTypography.bodyOf(context).copyWith(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ask ${aiConfig.model.split("/").last}...',
                            hintStyle: AppTypography.captionOf(context),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onSubmitted: _sendMessage,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.electricCyan, AppColors.violetAccent],
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                        onPressed: () => _sendMessage(_textController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withAlpha(20),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.captionOf(context).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
