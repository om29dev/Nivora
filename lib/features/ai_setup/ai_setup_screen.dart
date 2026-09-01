import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/ai/external_ai_provider.dart';
import '../../core/ai/local_ai_provider.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_button.dart';
import '../../core/widgets/nivora_card.dart';
import '../../core/widgets/nivora_chip.dart';

class AISetupScreen extends ConsumerStatefulWidget {
  const AISetupScreen({super.key});

  @override
  ConsumerState<AISetupScreen> createState() => _AISetupScreenState();
}

class _AISetupScreenState extends ConsumerState<AISetupScreen> {
  bool _useLocalAI = true;

  void _onConfirm() async {
    final aiProvider = _useLocalAI ? LocalAIProvider() : ExternalAIProvider();
    ref.read(selectedAIProvider.notifier).state = aiProvider;

    // Mark onboarding complete
    await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBorderColor = AppColors.electricCyan;
    final defaultBorderColor = Theme.of(context).dividerTheme.color ?? AppColors.border(context);
    final defaultCardColor = Theme.of(context).cardTheme.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Configuration'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your AI Engine',
                style: AppTypography.h1Of(context),
              ),
              const SizedBox(height: 8),
              Text(
                'Nivora is designed for private, on-device intelligence. You can change this anytime.',
                style: AppTypography.bodySecondaryOf(context),
              ),
              const SizedBox(height: 24),
              // Option 1: On-Device Local AI
              NivoraCard(
                onTap: () => setState(() => _useLocalAI = true),
                borderColor: _useLocalAI ? activeBorderColor : defaultBorderColor,
                backgroundColor: _useLocalAI
                    ? AppColors.electricCyan.withAlpha(20)
                    : defaultCardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: AppColors.electricCyan, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('On-Device Local AI', style: AppTypography.h2Of(context)),
                        ),
                        const NivoraChip(
                          label: 'RECOMMENDED',
                          color: AppColors.emeraldGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Runs locally on your phone. Completely private, offline-capable, with zero API charges or server latency.',
                      style: AppTypography.bodySecondaryOf(context),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: const [
                        NivoraChip(label: '100% Offline', icon: Icons.wifi_off_rounded),
                        NivoraChip(label: 'Zero Data Leaks', icon: Icons.lock_outline_rounded),
                        NivoraChip(label: 'Fast Retrieval', icon: Icons.speed_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Option 2: Cloud / External API
              NivoraCard(
                onTap: () => setState(() => _useLocalAI = false),
                borderColor: !_useLocalAI ? activeBorderColor : defaultBorderColor,
                backgroundColor: !_useLocalAI
                    ? AppColors.electricCyan.withAlpha(20)
                    : defaultCardColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_outlined, color: AppColors.violetAccent, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('External Cloud API', style: AppTypography.h2Of(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use OpenAI, Anthropic, or custom endpoints for complex tasks. Requires internet connection & API key.',
                      style: AppTypography.bodySecondaryOf(context),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              NivoraButton(
                text: 'Continue with ${_useLocalAI ? 'On-Device AI' : 'External API'}',
                width: double.infinity,
                onPressed: _onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
