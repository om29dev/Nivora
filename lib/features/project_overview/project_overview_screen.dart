import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_button.dart';
import '../../core/widgets/nivora_card.dart';
import '../../core/widgets/nivora_chip.dart';
import '../../core/widgets/nivora_status.dart';

class ProjectOverviewScreen extends ConsumerWidget {
  final String projectId;

  const ProjectOverviewScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProject = ref.watch(activeProjectProvider);
    final intelState = ref.watch(projectIntelligenceProvider);
    final summary = intelState.summary;

    if (activeProject == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Overview')),
        body: const Center(child: Text('No active project found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Repositories',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(activeProject.name),
        actions: [
          IconButton(
            tooltip: 'Voice Coding',
            icon: const Icon(Icons.mic_none_rounded, color: AppColors.violetAccent),
            onPressed: () => context.push('/voice-coding'),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerTheme.color ?? AppColors.border(context),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: NivoraButton(
                text: 'Ask AI',
                icon: Icons.auto_awesome,
                onPressed: () => context.push('/project/$projectId/ai'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NivoraSecondaryButton(
                text: 'Run Project',
                icon: Icons.play_arrow_rounded,
                onPressed: () => context.push('/project/$projectId/run'),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Project Meta Card
          NivoraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(activeProject.name, style: AppTypography.h1Of(context)),
                    ),
                    NivoraStatus(
                      type: NivoraStatusType.ready,
                      label: activeProject.currentBranch,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  activeProject.remoteUrl,
                  style: AppTypography.captionOf(context),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    NivoraChip(
                      label: activeProject.language,
                      color: AppColors.electricCyan,
                      icon: Icons.code,
                    ),
                    NivoraChip(
                      label: activeProject.runtime,
                      color: AppColors.violetAccent,
                      icon: Icons.memory,
                    ),
                    NivoraChip(
                      label: activeProject.packageManager,
                      color: AppColors.skyBlue,
                      icon: Icons.inventory_2_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Navigation Tabs
          Row(
            children: [
              Expanded(
                child: _QuickNavCard(
                  title: 'Files',
                  subtitle: '${intelState.scannedFiles.length} files',
                  icon: Icons.folder_open_rounded,
                  color: AppColors.amberWarning,
                  onTap: () => context.push('/project/$projectId/files'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickNavCard(
                  title: 'Terminal',
                  subtitle: 'Interactive shell',
                  icon: Icons.terminal_rounded,
                  color: AppColors.electricCyan,
                  onTap: () => context.push('/project/$projectId/terminal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickNavCard(
                  title: 'Git',
                  subtitle: 'Source Control',
                  icon: Icons.fork_right_rounded,
                  color: AppColors.emeraldGreen,
                  onTap: () => context.push('/project/$projectId/git'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Repository Intelligence Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROJECT INTELLIGENCE',
                style: AppTypography.caption.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: const [
                  NivoraStatus(type: NivoraStatusType.ready, label: 'AI Context Ready'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          NivoraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary != null && summary.purpose.isNotEmpty) ...[
                  Text('Purpose', style: AppTypography.h3),
                  const SizedBox(height: 4),
                  Text(summary.purpose, style: AppTypography.bodySecondary),
                  const Divider(height: 24),
                ],
                Text('Detected Commands', style: AppTypography.h3),
                const SizedBox(height: 8),
                if (summary != null && summary.detectedCommands.isNotEmpty) ...[
                  ...summary.detectedCommands.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                e.key.toUpperCase(),
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.electricCyan,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.value,
                                style: AppTypography.code.copyWith(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )),
                ] else ...[
                  Text('npm run dev', style: AppTypography.code),
                ],
                const Divider(height: 24),
                Text('Architecture & Symbols', style: AppTypography.h3),
                const SizedBox(height: 6),
                Text(
                  '${intelState.symbols.length} symbols extracted (functions, classes, routes) across ${intelState.scannedFiles.length} files. Targeted retrieval budget capped at 4,000 tokens.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickNavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NivoraCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(title, style: AppTypography.h3),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
