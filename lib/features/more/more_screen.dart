import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_card.dart';
import '../../core/widgets/nivora_chip.dart';
import '../../core/widgets/nivora_status.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProject = ref.watch(activeProjectProvider);
    final termux = ref.watch(termuxEnvironmentServiceProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('More & Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // 1. Active Project Context
          if (activeProject != null) ...[
            _SectionTitle(title: 'ACTIVE REPOSITORY'),
            NivoraCard(
              onTap: () => context.push('/project/${activeProject.id}'),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.electricCyan.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.electricCyan.withAlpha(80)),
                    ),
                    child: const Icon(Icons.code_rounded, color: AppColors.electricCyan, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activeProject.name, style: AppTypography.h3Of(context)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            NivoraStatus(type: NivoraStatusType.ready, label: activeProject.currentBranch),
                            const SizedBox(width: 8),
                            NivoraChip(label: activeProject.language, color: AppColors.electricCyan),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 2. Developer Workstation Tools
          _SectionTitle(title: 'DEVELOPER WORKSTATION TOOLS'),
          NivoraCard(
            child: Column(
              children: [
                _ToolTile(
                  icon: Icons.folder_copy_rounded,
                  iconColor: AppColors.electricCyan,
                  title: 'All Repositories',
                  subtitle: 'Explore, manage, and clone local sandboxes',
                  onTap: () => context.push('/projects'),
                ),
                const Divider(height: 1),
                _ToolTile(
                  icon: Icons.play_arrow_rounded,
                  iconColor: AppColors.emeraldGreen,
                  title: 'Runner & Live Preview',
                  subtitle: 'In-app HTTP dev server on loopback :5173',
                  onTap: () {
                    final id = activeProject?.id ?? 'demo-react-vite';
                    context.push('/project/$id/run');
                  },
                ),
                const Divider(height: 1),
                _ToolTile(
                  icon: Icons.commit_rounded,
                  iconColor: AppColors.skyBlue,
                  title: 'Git Source Control',
                  subtitle: 'Inspect modified files, diffs & commits',
                  onTap: () {
                    final id = activeProject?.id ?? 'demo-react-vite';
                    context.push('/project/$id/git');
                  },
                ),
                const Divider(height: 1),
                _ToolTile(
                  icon: Icons.camera_alt_rounded,
                  iconColor: AppColors.amberWarning,
                  title: 'Camera Error Debugger',
                  subtitle: 'Scan monitor error traces to suggest fixes',
                  onTap: () => context.push('/camera-debug'),
                ),
                const Divider(height: 1),
                _ToolTile(
                  icon: Icons.mic_rounded,
                  iconColor: AppColors.violetAccent,
                  title: 'Voice Coding Studio',
                  subtitle: 'Dictate code intents with speech-to-patch',
                  onTap: () => context.push('/voice-coding'),
                ),
                const Divider(height: 1),
                _ToolTile(
                  icon: Icons.laptop_chromebook_rounded,
                  iconColor: AppColors.electricCyan,
                  title: 'Office Kit Wireless Companion',
                  subtitle: 'Desktop screen mirroring & clipboard sync',
                  onTap: () => context.push('/office-kit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. System, Termux & Preferences
          _SectionTitle(title: 'SYSTEM & ENVIRONMENT'),
          NivoraCard(
            child: Column(
              children: [
                _ToolTile(
                  icon: Icons.settings_rounded,
                  iconColor: AppColors.textSecondaryOf(context),
                  title: 'Global Settings',
                  subtitle: 'Toolchains, permissions & diagnostics',
                  onTap: () => context.push('/settings'),
                ),
                const Divider(height: 1),
                _ToolTile(
                  icon: Icons.tune_rounded,
                  iconColor: AppColors.electricCyan,
                  title: 'AI Provider Configuration',
                  subtitle: 'On-device Local vs External Cloud model',
                  onTap: () => context.push('/ai-setup'),
                ),
                const Divider(height: 1),
                _ToolTile(
                  icon: Icons.terminal_rounded,
                  iconColor: termux.isReady ? AppColors.emeraldGreen : AppColors.amberWarning,
                  title: 'Embedded Termux Runtime',
                  subtitle: termux.isReady
                      ? 'Ready (${termux.detectedArchitecture}) - pkg & apt active'
                      : 'Not installed - Tap to configure',
                  trailing: NivoraChip(
                    label: termux.isReady ? 'ACTIVE' : 'SETUP',
                    color: termux.isReady ? AppColors.emeraldGreen : AppColors.amberWarning,
                  ),
                  onTap: () => context.push('/project/demo-react-vite/terminal'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Quick Theme Switcher
          _SectionTitle(title: 'THEME MODE'),
          NivoraCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearance', style: AppTypography.h3Of(context)),
                    const SizedBox(height: 2),
                    Text(
                      themeMode == ThemeMode.dark ? 'Dark Mode (Default)' : 'Light Mode',
                      style: AppTypography.captionOf(context),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Toggle Theme',
                  icon: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: AppColors.electricCyan,
                  ),
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.captionOf(context).copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: AppColors.textMutedOf(context),
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ToolTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(22),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: AppTypography.bodyOf(context).copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: AppTypography.captionOf(context).copyWith(fontSize: 11)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
