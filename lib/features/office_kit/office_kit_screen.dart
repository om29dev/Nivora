import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/office_kit_service.dart';
import '../../core/widgets/nivora_button.dart';
import '../../core/widgets/nivora_card.dart';
import '../../core/widgets/nivora_status.dart';

class OfficeKitScreen extends ConsumerStatefulWidget {
  const OfficeKitScreen({super.key});

  @override
  ConsumerState<OfficeKitScreen> createState() => _OfficeKitScreenState();
}

class _OfficeKitScreenState extends ConsumerState<OfficeKitScreen> {
  void _triggerDiscovery() {
    final officeKit = ref.read(officeKitServiceProvider);
    officeKit.startDiscovery();
    setState(() {});
  }

  void _syncClipboard() async {
    final officeKit = ref.read(officeKitServiceProvider);
    final success = await officeKit.syncClipboard('https://github.com/facebook/react');
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synced phone clipboard with laptop.'),
            backgroundColor: AppColors.emeraldGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final officeKit = ref.watch(officeKitServiceProvider);
    final status = officeKit.status;
    final device = officeKit.connectedDevice;
    final isConnected = status == OfficeKitStatus.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Kit Companion'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Architecture Diagram Card
            NivoraCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.electricCyan.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.phone_android_rounded, color: AppColors.electricCyan, size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text('PHONE', style: AppTypography.h3),
                          Text('Primary Workstation', style: AppTypography.caption),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(
                            isConnected ? Icons.sync_alt_rounded : Icons.sync_disabled_rounded,
                            color: isConnected ? AppColors.emeraldGreen : AppColors.textMuted,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isConnected ? 'Office Kit Link' : 'Searching LAN',
                            style: AppTypography.caption.copyWith(
                              color: isConnected ? AppColors.emeraldGreen : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.violetAccent.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.laptop_chromebook_rounded, color: AppColors.violetAccent, size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text('LAPTOP', style: AppTypography.h3),
                          Text('Accelerator', style: AppTypography.caption),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NivoraStatus(
                        type: isConnected ? NivoraStatusType.ready : NivoraStatusType.idle,
                        label: isConnected ? 'Connected to ${device?.name}' : 'Disconnected',
                      ),
                      TextButton(
                        onPressed: _triggerDiscovery,
                        child: Text(isConnected ? 'Reconnect' : 'Scan Network'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Compute Mode Split Breakdown
            Text(
              'COMPUTE SPLIT ARCHITECTURE',
              style: AppTypography.caption.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: NivoraCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phone Tasks', style: AppTypography.h3.copyWith(color: AppColors.electricCyan)),
                        const SizedBox(height: 8),
                        Text('• Local AI Agent\n• Git operations\n• Mobile code editor\n• Touch debugging\n• Voice & camera input', style: AppTypography.caption.copyWith(height: 1.6)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NivoraCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Laptop Tasks', style: AppTypography.h3.copyWith(color: AppColors.violetAccent)),
                        const SizedBox(height: 8),
                        Text('• Heavy builds\n• Headless tests\n• Secondary display\n• Shared clipboard\n• File transfer link', style: AppTypography.caption.copyWith(height: 1.6)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Office Kit Features
            Text(
              'INTERACTION MODES',
              style: AppTypography.caption.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            _FeatureTile(
              title: 'Cross-Device Shared Clipboard',
              subtitle: 'Instantly paste URLs and code snippets between phone and laptop.',
              icon: Icons.assignment_outlined,
              actionLabel: 'Sync Now',
              isEnabled: isConnected,
              onAction: _syncClipboard,
            ),
            const SizedBox(height: 10),

            _FeatureTile(
              title: 'Screen Mirroring & External Display',
              subtitle: 'Cast Nivora workspace to laptop monitor with full touch feedback.',
              icon: Icons.cast_connected_rounded,
              actionLabel: 'Mirror Screen',
              isEnabled: isConnected,
              onAction: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Screen mirroring stream started on 192.168.1.145:8090')),
                );
              },
            ),
            const SizedBox(height: 10),

            _FeatureTile(
              title: 'P2P File Transfer & Patch Sync',
              subtitle: 'Direct local Wi-Fi transfer of diffs without cloud intermediaries.',
              icon: Icons.swap_horiz_rounded,
              actionLabel: 'Send Patch',
              isEnabled: isConnected,
              onAction: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Patch sent to laptop companion.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final bool isEnabled;
  final VoidCallback onAction;

  const _FeatureTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.isEnabled,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return NivoraCard(
      child: Row(
        children: [
          Icon(icon, size: 24, color: isEnabled ? AppColors.electricCyan : AppColors.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.h3),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          NivoraButton(
            text: actionLabel,
            height: 34,
            onPressed: isEnabled ? onAction : null,
          ),
        ],
      ),
    );
  }
}
