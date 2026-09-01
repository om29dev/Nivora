import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/nivora_app_bar.dart';
import '../../core/widgets/nivora_bottom_sheet.dart';
import '../../core/widgets/nivora_chip.dart';
import 'providers/semantic_intel_providers.dart';
import 'widgets/blast_radius_canvas.dart';
import 'widgets/insight_panel.dart';

/// The main Semantic Intel dashboard screen.
///
/// Features:
///   • Full-screen blast radius visualization with interactive pan/zoom
///   • Floating "Local NPU Analysis" action button
///   • Sliding bottom panel for AI insights (via NivoraBottomSheet)
///   • Deep space dark aesthetic (#0A0A0F) with neon blue / electric purple accents
class SemanticDashboardScreen extends ConsumerStatefulWidget {
  const SemanticDashboardScreen({super.key});

  @override
  ConsumerState<SemanticDashboardScreen> createState() =>
      _SemanticDashboardScreenState();
}

class _SemanticDashboardScreenState
    extends ConsumerState<SemanticDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabGlowController;
  late Animation<double> _fabGlowAnim;

  @override
  void initState() {
    super.initState();
    _fabGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _fabGlowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _fabGlowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabGlowController.dispose();
    super.dispose();
  }

  void _runNpuAnalysis() {
    ref.read(npuInferenceProvider.notifier).runAnalysis();
  }

  void _showInsightsPanel() {
    NivoraBottomSheet.show(
      context: context,
      title: 'AI Insights',
      child: const InsightPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inferenceState = ref.watch(npuInferenceProvider);
    final hasResult = inferenceState.result != null;
    final isRunning = inferenceState.status == NpuInferenceStatus.running;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: NivoraAppBar(
        title: 'Semantic Intel',
        subtitle: 'Blast Radius Analyzer',
        actions: [
          if (hasResult)
            IconButton(
              icon: const Icon(Icons.insights_rounded),
              color: AppColors.electricCyan,
              tooltip: 'View AI Insights',
              onPressed: _showInsightsPanel,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF0E0E1A),
                    Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),
          ),

          // Main content with padding for bottom status bar
          if (hasResult)
            Positioned.fill(
              bottom: 60,
              child: BlastRadiusCanvas(data: inferenceState.result!),
            )
          else
            _WelcomeState(
              isRunning: isRunning,
              progress: inferenceState.progress,
              statusMessage: inferenceState.statusMessage,
            ),

          // Floating Action Button in top-right or overlay
          Positioned(
            top: 16,
            right: 16,
            child: _NpuAnalysisFab(
              glowAnim: _fabGlowAnim,
              isRunning: isRunning,
              onPressed: _runNpuAnalysis,
            ),
          ),

          // Bottom info bar with status chips
          if (hasResult)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomStatusBar(
                data: inferenceState.result!,
                onTapInsights: _showInsightsPanel,
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
//  WELCOME / EMPTY STATE
// ==========================================
class _WelcomeState extends StatelessWidget {
  final bool isRunning;
  final double progress;
  final String? statusMessage;

  const _WelcomeState({
    required this.isRunning,
    required this.progress,
    this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRunning) ...[
              // Animated progress ring
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        backgroundColor: AppColors.darkBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.electricCyan,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: AppTypography.h2.copyWith(
                        color: AppColors.electricCyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                statusMessage ?? 'Analyzing…',
                style: AppTypography.bodyOf(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'On-device NPU inference',
                style: AppTypography.caption.copyWith(
                  color: AppColors.violetAccent,
                  letterSpacing: 0.5,
                ),
              ),
            ] else ...[
              // Idle state with glow icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.violetAccent.withAlpha(30),
                      AppColors.violetAccent.withAlpha(0),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.hub_rounded,
                  size: 40,
                  color: AppColors.violetAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Blast Radius Analyzer',
                style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Visualize the impact of code changes across your dependency graph using on-device NPU inference.',
                style: AppTypography.bodySecondaryOf(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NivoraChip(
                    label: 'On-Device',
                    icon: Icons.phone_android_rounded,
                    color: AppColors.electricCyan,
                  ),
                  const SizedBox(width: 8),
                  NivoraChip(
                    label: 'Zero Latency',
                    icon: Icons.bolt_rounded,
                    color: AppColors.violetAccent,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
//  BOTTOM STATUS BAR
// ==========================================
class _BottomStatusBar extends StatelessWidget {
  final dynamic data; // BlastRadiusData
  final VoidCallback onTapInsights;

  const _BottomStatusBar({
    required this.data,
    required this.onTapInsights,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapInsights,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0A0F).withAlpha(0),
              const Color(0xFF0A0A0F).withAlpha(220),
              const Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              const NivoraChip(
                label: 'NPU Complete',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.emeraldGreen,
              ),
              const SizedBox(width: 8),
              NivoraChip(
                label: '${data.nodes.length} nodes',
                icon: Icons.scatter_plot_rounded,
                color: AppColors.electricCyan,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.electricCyan, AppColors.violetAccent],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insights_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'View Insights',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

// ==========================================
//  FLOATING ACTION BUTTON — NPU TRIGGER
// ==========================================
class _NpuAnalysisFab extends StatelessWidget {
  final Animation<double> glowAnim;
  final bool isRunning;
  final VoidCallback onPressed;

  const _NpuAnalysisFab({
    required this.glowAnim,
    required this.isRunning,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.violetAccent
                    .withAlpha((glowAnim.value * 80).toInt()),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.electricCyan
                    .withAlpha((glowAnim.value * 40).toInt()),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: isRunning ? null : onPressed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.electricCyan,
                    Color(0xFF00B4D8),
                    AppColors.violetAccent,
                  ],
                ),
              ),
              child: Center(
                child: isRunning
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.memory_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
