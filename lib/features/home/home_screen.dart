import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/config/app_config.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/project.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_button.dart';
import '../../core/widgets/nivora_card.dart';
import '../../core/widgets/nivora_dialog.dart';
import '../../core/widgets/nivora_empty_state.dart';
import '../../core/widgets/nivora_input.dart';
import '../../core/widgets/nivora_project_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _onClonePressed() {
    final url = _urlController.text.trim();
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
    // Trigger indexing in background
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

  @override
  Widget build(BuildContext context) {
    final recentProjects = ref.watch(projectsListProvider);
    final activeAI = ref.watch(selectedAIProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.electricCyan, AppColors.violetAccent],
                ),
              ),
              child: const Center(
                child: Icon(Icons.terminal_rounded, size: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppConfig.appName,
              style: AppTypography.brandTitleOf(context).copyWith(fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: AppColors.electricCyan,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          IconButton(
            tooltip: 'Office Kit',
            icon: const Icon(Icons.devices_rounded, color: AppColors.electricCyan),
            onPressed: () => context.push('/office-kit'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondaryOf(context),
            ),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Greeting & Callout
            Text('Good afternoon 👋', style: AppTypography.bodySecondaryOf(context)),
            const SizedBox(height: 4),
            Text('What are you working on?', style: AppTypography.h1Of(context)),
            const SizedBox(height: 20),

            // GitHub Clone Input Card
            NivoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link_rounded, color: AppColors.electricCyan, size: 20),
                      const SizedBox(width: 8),
                      Text('Clone GitHub Repository', style: AppTypography.h3Of(context)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  NivoraInput(
                    controller: _urlController,
                    hintText: 'https://github.com/username/repository',
                    prefixIcon: Icons.search_rounded,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste_rounded, size: 18, color: AppColors.electricCyan),
                      onPressed: () async {
                        // Quick demo shortcut
                        _urlController.text = 'https://github.com/facebook/react';
                        setState(() {});
                      },
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: AppTypography.caption.copyWith(color: AppColors.coralRed),
                    ),
                  ],
                  const SizedBox(height: 16),
                  NivoraButton(
                    text: 'Clone Repository',
                    icon: Icons.download_rounded,
                    width: double.infinity,
                    onPressed: _onClonePressed,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Active AI Provider Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).dividerTheme.color ?? AppColors.border(context),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: AppColors.electricCyan),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI: ${activeAI.name}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/ai-setup'),
                    child: Text(
                      'Change',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.electricCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Recent Projects Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT PROJECTS',
                  style: AppTypography.caption.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 14, color: AppColors.electricCyan),
                  label: Text(
                    'Load Demos',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.electricCyan,
                      fontWeight: FontWeight.bold,
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

            // Projects List or Empty State
            if (recentProjects.isEmpty) ...[
              NivoraEmptyState(
                icon: Icons.folder_open_rounded,
                title: 'No repositories yet',
                message: 'Paste a GitHub URL above to clone and start developing directly on your phone.',
                actionText: 'Clone React Demo',
                onAction: () {
                  _urlController.text = 'https://github.com/facebook/react';
                  _onClonePressed();
                },
              ),
            ] else ...[
              ...recentProjects.map((project) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NivoraProjectCard(
                      project: project,
                      onTap: () => _openProject(project),
                      onDelete: () => _confirmDeleteProject(project),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
