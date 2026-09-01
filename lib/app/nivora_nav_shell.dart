import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_typography.dart';
import '../core/providers/app_providers.dart';
import '../core/widgets/nivora_bottom_nav_bar.dart';
import '../core/widgets/nivora_bottom_sheet.dart';
import '../core/widgets/nivora_button.dart';

/// Application navigation shell hosting the active navigation branch and the floating bottom bar.
class NivoraNavShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const NivoraNavShell({
    super.key,
    required this.navigationShell,
  });

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _onAITapped(BuildContext context, WidgetRef ref) {
    final activeProject = ref.read(activeProjectProvider);
    final projects = ref.read(projectsListProvider);

    if (activeProject != null) {
      context.push('/project/${activeProject.id}/ai');
      return;
    }

    if (projects.isNotEmpty) {
      // Automatically activate the most recent project
      final targetProject = projects.first;
      ref.read(activeProjectProvider.notifier).state = targetProject;
      ref.read(projectIntelligenceProvider.notifier).indexProject(targetProject.path);
      context.push('/project/${targetProject.id}/ai');
      return;
    }

    // No projects available yet -> Show quick setup sheet
    NivoraBottomSheet.show(
      context: context,
      title: 'AI Agent Assistant',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.electricCyan, AppColors.violetAccent],
                  ),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Repository-Aware AI', style: AppTypography.h3Of(context)),
                    const SizedBox(height: 2),
                    Text(
                      'Surgical context retrieval on your code',
                      style: AppTypography.captionOf(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'The AI Agent operates directly on cloned repositories, indexing symbols, reading documentation, and proposing unified diffs. Clone a repository to begin.',
            style: AppTypography.bodySecondaryOf(context),
          ),
          const SizedBox(height: 24),
          NivoraButton(
            text: 'Clone a Repository',
            icon: Icons.download_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/clone');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      extendBody: false,
      body: navigationShell,
      bottomNavigationBar: isKeyboardOpen
          ? null
          : NivoraBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onItemSelected: _onTabSelected,
              onAITapped: () => _onAITapped(context, ref),
            ),
    );
  }
}
