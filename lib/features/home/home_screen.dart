import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/config/app_config.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/ai/ai_config.dart';
import '../../core/models/project.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_button.dart';
import '../../core/widgets/nivora_dialog.dart';
import '../../core/widgets/nivora_empty_state.dart';
import '../../core/widgets/nivora_glass_card.dart';
import '../../core/widgets/nivora_project_card.dart';
import 'widgets/dashboard_quick_chat_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _aiPromptController = TextEditingController();
  String? _errorMessage;

  // 0: AI Copilot, 1: Clone Repository
  int _activeHubTab = 0;

  @override
  void dispose() {
    _urlController.dispose();
    _aiPromptController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Working late';
  }

  void _onClonePressed([String? customUrl]) {
    final url = customUrl ?? _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Please enter a GitHub repository URL.');
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://') && !url.contains('github.com')) {
      setState(() => _errorMessage = 'Please enter a valid GitHub URL (e.g. https://github.com/user/repo).');
      return;
    }

    setState(() => _errorMessage = null);
    context.push('/clone', extra: url);
  }

  void _openProject(Project project) {
    ref.read(activeProjectProvider.notifier).state = project;
    ref.read(projectIntelligenceProvider.notifier).indexProject(project.path);
    context.push('/project/${project.id}');
  }

  void _confirmDeleteProject(Project project) async {
    final confirmed = await NivoraDialog.showConfirmation(
      context: context,
      title: 'Delete Repository',
      message: 'Are you sure you want to delete ${project.name}? This will remove local files.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      ref.read(projectsListProvider.notifier).deleteProject(project.id);
    }
  }

  void _openQuickChat([String? prompt]) {
    final text = prompt ?? _aiPromptController.text.trim();
    _aiPromptController.clear();
    DashboardQuickChatSheet.show(context, initialPrompt: text.isNotEmpty ? text : null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final recentProjects = ref.watch(projectsListProvider);
    final aiConfig = ref.watch(aiConfigProvider);
    final intel = ref.watch(projectIntelligenceProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: (isDark ? const Color(0xFF090D16) : Colors.white).withAlpha(240),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        shape: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withAlpha(18),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x6606B6D4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppConfig.appName,
              style: AppTypography.brandTitleOf(context).copyWith(
                fontSize: 22,
                letterSpacing: -0.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: AppColors.electricCyan,
              size: 20,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          // Settings
          IconButton(
            tooltip: 'Settings',
            icon: Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondaryOf(context),
              size: 20,
            ),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient Glowing Mesh Background Orbs
            Positioned(
              top: -40,
              right: -50,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.electricCyan.withAlpha(isDark ? 45 : 25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 180,
              left: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.violetAccent.withAlpha(isDark ? 40 : 20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.emeraldGreen.withAlpha(isDark ? 30 : 15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Scrollable Content
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Clean Hero Greeting
                _buildHeroHeader(context, isDark),
                const SizedBox(height: 14),

                // Slim Frosted Glass Telemetry Ribbon
                _buildTelemetryRibbon(context, isDark, recentProjects.length, aiConfig, intel.symbols.length),
                const SizedBox(height: 18),

                // Unified Glass Workstation Hub (AI Copilot / Clone Tabbed)
                _buildGlassWorkstationHub(context, isDark, aiConfig),
                const SizedBox(height: 14),

                // 4-Button Developer Workstation Action Grid
                _buildWorkstationActionGrid(context, isDark, recentProjects.isNotEmpty ? recentProjects.first : null),
                const SizedBox(height: 14),

                // Auxiliary AI Tools Carousel (Camera Debug, Voice Studio, Office Kit)
                _buildAuxiliaryToolsBanner(context, isDark),
                const SizedBox(height: 20),

                // Recent Repositories Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.source_rounded, size: 16, color: AppColors.electricCyan),
                        const SizedBox(width: 8),
                        Text(
                          'RECENT REPOSITORIES',
                          style: AppTypography.caption.copyWith(
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        backgroundColor: AppColors.electricCyan.withAlpha(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 13, color: AppColors.electricCyan),
                      label: Text(
                        'Load Demos',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.electricCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      onPressed: () async {
                        await ref.read(projectsListProvider.notifier).seedDemoProjects();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Loaded React & Python demo repositories!'),
                              backgroundColor: AppColors.emeraldGreen,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Project Cards List
                if (recentProjects.isEmpty) ...[
                  NivoraEmptyState(
                    icon: Icons.folder_open_rounded,
                    title: 'No repositories yet',
                    message: 'Clone any public GitHub repository or load sample demo projects to get started.',
                    actionText: 'Load React Demo Repo',
                    onAction: () => _onClonePressed('https://github.com/facebook/react'),
                  ),
                ] else ...[
                  ...recentProjects.map((project) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NivoraProjectCard(
                          project: project,
                          onTap: () => _openProject(project),
                          onDelete: () => _confirmDeleteProject(project),
                        ),
                      )),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_getGreeting()}, Engineer 👋',
          style: AppTypography.bodySecondaryOf(context).copyWith(fontSize: 14),
        ),
        Text(
          'Mobile Workstation',
          style: AppTypography.h1Of(context).copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryRibbon(
    BuildContext context,
    bool isDark,
    int projectCount,
    AIConfig aiConfig,
    int symbolCount,
  ) {
    return NivoraGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTelemetryItem(
            context,
            icon: Icons.source_rounded,
            label: 'SANDBOXES',
            value: '$projectCount Active',
            color: AppColors.electricCyan,
          ),
          Container(
            height: 24,
            width: 1,
            color: (isDark ? Colors.white : Colors.black).withAlpha(20),
          ),
          _buildTelemetryItem(
            context,
            icon: Icons.auto_awesome_rounded,
            label: 'AI ENGINE',
            value: aiConfig.model.split('/').last.split(':').first,
            color: AppColors.violetAccent,
            onTap: () => context.push('/ai-setup'),
          ),
          Container(
            height: 24,
            width: 1,
            color: (isDark ? Colors.white : Colors.black).withAlpha(20),
          ),
          _buildTelemetryItem(
            context,
            icon: Icons.hub_rounded,
            label: 'AST INTEL',
            value: symbolCount > 0 ? '$symbolCount Symbols' : 'Indexed',
            color: AppColors.emeraldGreen,
            onTap: () => context.push('/semantic-intel'),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withAlpha(22),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: AppColors.textMutedOf(context),
              ),
            ),
            Text(
              value,
              style: AppTypography.captionOf(context).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }
    return content;
  }

  Widget _buildGlassWorkstationHub(BuildContext context, bool isDark, AIConfig aiConfig) {
    return NivoraGlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      glowColor: _activeHubTab == 0 ? AppColors.electricCyan : AppColors.violetAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Glass Tab Switcher
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withAlpha(60),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withAlpha(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentTabButton(
                    label: '⚡ AI Copilot',
                    isSelected: _activeHubTab == 0,
                    activeColor: AppColors.electricCyan,
                    onTap: () => setState(() => _activeHubTab = 0),
                  ),
                ),
                Expanded(
                  child: _SegmentTabButton(
                    label: '🐙 Clone Repo',
                    isSelected: _activeHubTab == 1,
                    activeColor: AppColors.violetAccent,
                    onTap: () => setState(() => _activeHubTab = 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tab Content
          if (_activeHubTab == 0)
            _buildAICopilotTab(context, isDark, aiConfig)
          else
            _buildCloneRepoTab(context, isDark),
        ],
      ),
    );
  }

  Widget _buildAICopilotTab(BuildContext context, bool isDark, AIConfig aiConfig) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Glass omnibar input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withAlpha(40),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.electricCyan.withAlpha(60),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppColors.electricCyan),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _aiPromptController,
                  style: AppTypography.bodyOf(context).copyWith(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Prompt ${aiConfig.model.split('/').last}...',
                    hintStyle: AppTypography.captionOf(context).copyWith(fontSize: 12.5),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (val) => _openQuickChat(val),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.electricCyan),
                tooltip: 'Send Prompt',
                onPressed: () => _openQuickChat(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Quick Suggestion Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _GlassPromptPill(
                label: '🏛️ Architecture',
                onTap: () => _openQuickChat('Explain repository architecture & module flow'),
              ),
              const SizedBox(width: 6),
              _GlassPromptPill(
                label: '🎨 Dark Theme',
                onTap: () => _openQuickChat('Add dark mode theme support'),
              ),
              const SizedBox(width: 6),
              _GlassPromptPill(
                label: '🧪 Add Tests',
                onTap: () => _openQuickChat('Generate unit test suite for main modules'),
              ),
              const SizedBox(width: 6),
              _GlassPromptPill(
                label: '🔍 Entrypoints',
                onTap: () => _openQuickChat('Locate entrypoints and routes in codebase'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCloneRepoTab(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withAlpha(40),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.violetAccent.withAlpha(60),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, size: 18, color: AppColors.violetAccent),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _urlController,
                  style: AppTypography.bodyOf(context).copyWith(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'https://github.com/owner/repository',
                    hintStyle: AppTypography.captionOf(context).copyWith(fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _onClonePressed(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.paste_rounded, size: 16, color: AppColors.violetAccent),
                tooltip: 'Sample Repo',
                onPressed: () {
                  _urlController.text = 'https://github.com/facebook/react';
                  setState(() {});
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            _errorMessage!,
            style: AppTypography.caption.copyWith(color: AppColors.coralRed, fontSize: 11),
          ),
        ],
        const SizedBox(height: 10),

        // Quick Starters and Clone Action Button
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _StarterPill(
                      label: 'React',
                      onTap: () => _onClonePressed('https://github.com/facebook/react'),
                    ),
                    const SizedBox(width: 5),
                    _StarterPill(
                      label: 'FastAPI',
                      onTap: () => _onClonePressed('https://github.com/tiangolo/fastapi'),
                    ),
                    const SizedBox(width: 5),
                    _StarterPill(
                      label: 'Express',
                      onTap: () => _onClonePressed('https://github.com/expressjs/express'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            NivoraButton(
              text: 'Clone',
              icon: Icons.download_rounded,
              height: 36,
              onPressed: () => _onClonePressed(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkstationActionGrid(BuildContext context, bool isDark, Project? active) {
    final projId = active?.id ?? 'demo-react-vite';

    final tools = [
      _WorkstationToolItem(
        icon: Icons.play_arrow_rounded,
        iconColor: AppColors.emeraldGreen,
        title: 'Run Project',
        subtitle: 'Start dev server',
        onTap: () => active != null ? _openProject(active) : context.push('/project/$projId/run'),
      ),
      _WorkstationToolItem(
        icon: Icons.terminal_rounded,
        iconColor: AppColors.violetAccent,
        title: 'Terminal',
        subtitle: 'Open console',
        onTap: () => context.push('/terminal'),
      ),
      _WorkstationToolItem(
        icon: Icons.commit_rounded,
        iconColor: AppColors.skyBlue,
        title: 'Git Status',
        subtitle: 'Diffs & commits',
        onTap: () => context.push('/project/$projId/git'),
      ),
      _WorkstationToolItem(
        icon: Icons.language_rounded,
        iconColor: AppColors.electricCyan,
        title: 'Live Preview',
        subtitle: 'In-app browser',
        onTap: () => context.push('/project/$projId/run'),
      ),
      _WorkstationToolItem(
        icon: Icons.camera_alt_rounded,
        iconColor: AppColors.amberWarning,
        title: 'Camera Debug',
        subtitle: 'Scan error logs',
        onTap: () => context.push('/camera-debug'),
      ),
      _WorkstationToolItem(
        icon: Icons.mic_rounded,
        iconColor: AppColors.violetAccent,
        title: 'Voice Studio',
        subtitle: 'Speech-to-code',
        onTap: () => context.push('/voice-coding'),
      ),
      _WorkstationToolItem(
        icon: Icons.laptop_chromebook_rounded,
        iconColor: AppColors.electricCyan,
        title: 'Office Kit',
        subtitle: 'Screen mirror',
        onTap: () => context.push('/office-kit'),
      ),
      _WorkstationToolItem(
        icon: Icons.hub_rounded,
        iconColor: AppColors.emeraldGreen,
        title: '3D Intel',
        subtitle: 'Blast radius',
        onTap: () => context.push('/semantic-intel'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.handyman_rounded, size: 14, color: AppColors.electricCyan),
            const SizedBox(width: 6),
            Text(
              'WORKSTATION TOOLS',
              style: AppTypography.caption.copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondaryOf(context),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: tools.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final tool = tools[index];
            return _WorkstationGridCard(tool: tool, isDark: isDark);
          },
        ),
      ],
    );
  }

  Widget _buildAuxiliaryToolsBanner(BuildContext context, bool isDark) {
    return const SizedBox.shrink();
  }
}

class _WorkstationToolItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _WorkstationToolItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _WorkstationGridCard extends StatelessWidget {
  final _WorkstationToolItem tool;
  final bool isDark;

  const _WorkstationGridCard({required this.tool, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: tool.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF101726) : Colors.white).withAlpha(220),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withAlpha(16),
          ),
          boxShadow: [
            BoxShadow(
              color: tool.iconColor.withAlpha(isDark ? 20 : 10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: tool.iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tool.icon, size: 20, color: tool.iconColor),
            ),
            const SizedBox(height: 6),
            Text(
              tool.title,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              tool.subtitle,
              style: TextStyle(
                fontSize: 8,
                color: AppColors.textMutedOf(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _SegmentTabButton({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(35) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: activeColor.withAlpha(120), width: 1)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.captionOf(context).copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeColor : AppColors.textSecondaryOf(context),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPromptPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlassPromptPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withAlpha(12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withAlpha(20),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.captionOf(context).copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StarterPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StarterPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withAlpha(12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withAlpha(20),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.captionOf(context).copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
