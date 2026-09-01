import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/config/app_config.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/runtime_types.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_card.dart';
import '../../core/widgets/nivora_chip.dart';
import '../../core/widgets/nivora_status.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAI = ref.watch(selectedAIProvider);
    final healthAsync = ref.watch(runtimeHealthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Global Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // AI Engine Section
          _SectionHeader(title: 'AI ENGINE & MODELS'),
          NivoraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Provider', style: AppTypography.h3),
                    NivoraChip(
                      label: activeAI.isLocal ? 'ON-DEVICE' : 'EXTERNAL',
                      color: activeAI.isLocal
                          ? AppColors.emeraldGreen
                          : AppColors.violetAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(activeAI.name, style: AppTypography.bodySecondary),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.push('/ai-setup'),
                  child: const Text('Switch or Configure AI Provider'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Embedded Termux Section
          _SectionHeader(title: 'EMBEDDED TERMUX RUNTIME'),
          NivoraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Termux Package Environment',
                        style: AppTypography.h3Of(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    NivoraChip(
                      label: ref.watch(termuxEnvironmentServiceProvider).isReady
                          ? 'READY (${ref.watch(termuxEnvironmentServiceProvider).detectedArchitecture})'
                          : 'NOT INSTALLED',
                      color: ref.watch(termuxEnvironmentServiceProvider).isReady
                          ? AppColors.emeraldGreen
                          : AppColors.amberWarning,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Self-contained Linux runtime running inside Nivora without requiring the Termux app.',
                  style: AppTypography.captionOf(context),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Prefix: ${ref.watch(termuxEnvironmentServiceProvider).prefixPath}',
                        style: AppTypography.terminal.copyWith(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricCyan,
                        foregroundColor: AppColors.darkBackground,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        context.push('/project/demo-react-vite/terminal');
                      },
                      child: Text(
                        ref.watch(termuxEnvironmentServiceProvider).isReady
                            ? 'Open in Terminal'
                            : 'Install Runtime',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Toolchain Diagnostics Section
          _SectionHeader(title: 'RUNTIME TOOLCHAINS & ENVIRONMENT'),
          NivoraCard(
            child: healthAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.electricCyan),
              ),
              error: (err, _) => Text('Error probing toolchains: $err'),
              data: (health) {
                return Column(
                  children: [
                    _ToolchainRow(info: health.node),
                    const Divider(),
                    _ToolchainRow(info: health.npm),
                    const Divider(),
                    _ToolchainRow(info: health.python),
                    const Divider(),
                    _ToolchainRow(info: health.pip),
                    const Divider(),
                    _ToolchainRow(info: health.git),
                    const Divider(),
                    _ToolchainRow(info: health.shell),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Security & Agent Permissions Section
          _SectionHeader(title: 'AI AGENT PERMISSIONS & SAFETY'),
          NivoraCard(
            child: Column(
              children: const [
                _PermissionToggle(
                  title: 'Read project files & documentation',
                  initialValue: true,
                ),
                Divider(),
                _PermissionToggle(
                  title: 'Targeted symbol indexing',
                  initialValue: true,
                ),
                Divider(),
                _PermissionToggle(
                  title: 'Synthesize code modifications',
                  initialValue: true,
                ),
                Divider(),
                _PermissionToggle(
                  title: 'Require confirmation for destructive commands',
                  initialValue: true,
                ),
                Divider(),
                _PermissionToggle(
                  title: 'Automatic Git Push',
                  initialValue: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Appearance & Theme Mode Section
          _SectionHeader(title: 'APPEARANCE & THEME'),
          NivoraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Application Theme', style: AppTypography.h3Of(context)),
                const SizedBox(height: 2),
                Text(switch (ref.watch(themeModeProvider)) {
                  ThemeMode.dark => 'Dark Mode (Default)',
                  ThemeMode.light => 'Light Mode',
                  ThemeMode.system => 'Following System',
                }, style: AppTypography.captionOf(context)),
                const SizedBox(height: 14),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.auto_mode, size: 16),
                      label: Text('Auto'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode, size: 16),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode, size: 16),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {ref.watch(themeModeProvider)},
                  onSelectionChanged: (val) {
                    ref.read(themeModeProvider.notifier).setTheme(val.first);
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Demo Data & Hackathon Sandbox Section
          _SectionHeader(title: 'HACKATHON DEMO SANDBOX'),
          NivoraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pre-seeded Repositories',
                  style: AppTypography.h3Of(context),
                ),
                const SizedBox(height: 4),
                Text(
                  'Instantly generate realistic React & Python projects for offline evaluation.',
                  style: AppTypography.bodySecondaryOf(context),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Re-seed Demo Repositories'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricCyan,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await ref
                        .read(projectsListProvider.notifier)
                        .seedDemoProjects();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Demo repositories re-seeded successfully!',
                          ),
                          backgroundColor: AppColors.emeraldGreen,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Nivora Section
          _SectionHeader(title: 'ABOUT'),
          NivoraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConfig.appName, style: AppTypography.h2),
                const SizedBox(height: 2),
                Text(AppConfig.appTagline, style: AppTypography.bodySecondary),
                const SizedBox(height: 8),
                Text(
                  'Version ${AppConfig.appVersion} • Built for iQOO Hackathon 2026',
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTypography.captionOf(context).copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondaryOf(context),
        ),
      ),
    );
  }
}

class _ToolchainRow extends StatelessWidget {
  final ToolchainInfo info;

  const _ToolchainRow({required this.info});

  @override
  Widget build(BuildContext context) {
    final isReady = info.status == ToolchainStatus.ready;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.name,
                style: AppTypography.bodyOf(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                info.version ?? 'Not found',
                style: AppTypography.captionOf(
                  context,
                ).copyWith(fontFamily: 'JetBrainsMono', fontSize: 11),
              ),
            ],
          ),
          NivoraStatus(
            type: isReady ? NivoraStatusType.ready : NivoraStatusType.warning,
            label: isReady ? 'Ready' : 'Not installed',
          ),
        ],
      ),
    );
  }
}

class _PermissionToggle extends StatefulWidget {
  final String title;
  final bool initialValue;

  const _PermissionToggle({required this.title, required this.initialValue});

  @override
  State<_PermissionToggle> createState() => _PermissionToggleState();
}

class _PermissionToggleState extends State<_PermissionToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: AppTypography.bodyOf(context).copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.text(context),
              ),
            ),
          ),
          Switch(
            value: _value,
            activeTrackColor: AppColors.electricCyan,
            activeThumbColor: Colors.white,
            onChanged: (val) {
              setState(() => _value = val);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${widget.title}: ${val ? "Enabled" : "Disabled"}',
                  ),
                  duration: const Duration(seconds: 1),
                  backgroundColor: val
                      ? AppColors.emeraldGreen
                      : AppColors.amberWarning,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
