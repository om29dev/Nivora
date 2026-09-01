import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/nivora_card.dart';
import '../../../core/widgets/nivora_chip.dart';
import '../models/blast_radius_data.dart';
import '../providers/semantic_intel_providers.dart';

/// AI-powered insight panel displayed in the bottom sheet.
/// Shows refactoring plans, coupling trends, and NPU status
/// while connecting to LocalAIProvider for on-device emphasis.
class InsightPanel extends ConsumerWidget {
  const InsightPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inferenceState = ref.watch(npuInferenceProvider);
    final result = inferenceState.result;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NPU Status Badge
          _NpuStatusBadge(state: inferenceState),
          const SizedBox(height: 20),

          if (result != null) ...[
            // Overall Risk Gauge
            _RiskGauge(risk: result.overallRisk),
            const SizedBox(height: 24),

            // Coupling Trends Section
            Text('Coupling Trends', style: AppTypography.h3Of(context)),
            const SizedBox(height: 10),
            _CouplingTrendsGrid(trends: result.couplingTrends),
            const SizedBox(height: 24),

            // Refactoring Plan Section
            Text('Refactoring Plan', style: AppTypography.h3Of(context)),
            const SizedBox(height: 10),
            ...result.refactoringPlan.map(
              (step) => _RefactoringStepTile(step: step),
            ),
          ] else ...[
            _EmptyInsightState(isRunning: inferenceState.status == NpuInferenceStatus.running),
          ],
        ],
      ),
    );
  }
}

// ==========================================
//  NPU STATUS BADGE — pulsing when active
// ==========================================
class _NpuStatusBadge extends StatefulWidget {
  final NpuInferenceState state;
  const _NpuStatusBadge({required this.state});

  @override
  State<_NpuStatusBadge> createState() => _NpuStatusBadgeState();
}

class _NpuStatusBadgeState extends State<_NpuStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.state.status == NpuInferenceStatus.running) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _NpuStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.status == NpuInferenceStatus.running) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = widget.state.status == NpuInferenceStatus.running;
    final isCompleted = widget.state.status == NpuInferenceStatus.completed;

    final Color dotColor;
    final String statusText;
    final Color badgeBorderColor;

    if (isRunning) {
      dotColor = AppColors.electricCyan;
      statusText = 'NPU Inference Active';
      badgeBorderColor = AppColors.electricCyan.withAlpha(60);
    } else if (isCompleted) {
      dotColor = AppColors.emeraldGreen;
      statusText = 'NPU Analysis Complete';
      badgeBorderColor = AppColors.emeraldGreen.withAlpha(60);
    } else {
      dotColor = AppColors.textMuted;
      statusText = 'NPU Standby';
      badgeBorderColor = AppColors.darkBorder;
    }

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: dotColor.withAlpha(isRunning ? 12 : 8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: badgeBorderColor, width: 1),
          ),
          child: Row(
            children: [
              // Pulsing dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor.withAlpha(
                    isRunning ? (255 * _pulseAnim.value).toInt() : 255,
                  ),
                  boxShadow: isRunning
                      ? [
                          BoxShadow(
                            color: dotColor.withAlpha(
                              (100 * _pulseAnim.value).toInt(),
                            ),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: AppTypography.caption.copyWith(
                        color: dotColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (widget.state.statusMessage != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.state.statusMessage!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isRunning) ...[
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(widget.state.progress * 100).toInt()}%',
                    textAlign: TextAlign.right,
                    style: AppTypography.code.copyWith(
                      color: AppColors.electricCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (isCompleted) ...[
                Icon(Icons.check_circle_rounded,
                    color: AppColors.emeraldGreen, size: 18),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
//  RISK GAUGE — visual meter bar
// ==========================================
class _RiskGauge extends StatelessWidget {
  final double risk;
  const _RiskGauge({required this.risk});

  @override
  Widget build(BuildContext context) {
    final Color riskColor;
    final String riskLabel;
    if (risk > 0.7) {
      riskColor = AppColors.coralRed;
      riskLabel = 'High Risk';
    } else if (risk > 0.4) {
      riskColor = AppColors.amberWarning;
      riskLabel = 'Medium Risk';
    } else {
      riskColor = AppColors.emeraldGreen;
      riskLabel = 'Low Risk';
    }

    return NivoraCard(
      borderColor: riskColor.withAlpha(50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overall Blast Radius Risk',
                  style: AppTypography.captionOf(context)),
              NivoraChip(
                label: riskLabel,
                color: riskColor,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: risk,
              minHeight: 6,
              backgroundColor: AppColors.darkBorder,
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(risk * 100).toInt()}% of dependency graph affected',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
//  COUPLING TRENDS GRID
// ==========================================
class _CouplingTrendsGrid extends StatelessWidget {
  final List<CouplingTrend> trends;
  const _CouplingTrendsGrid({required this.trends});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: trends.map((trend) => _CouplingTrendTile(trend: trend)).toList(),
    );
  }
}

class _CouplingTrendTile extends StatelessWidget {
  final CouplingTrend trend;
  const _CouplingTrendTile({required this.trend});

  @override
  Widget build(BuildContext context) {
    final isPositiveDelta = trend.delta > 0;
    final deltaColor =
        isPositiveDelta ? AppColors.coralRed : AppColors.emeraldGreen;
    final deltaIcon =
        isPositiveDelta ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final deltaSign = isPositiveDelta ? '+' : '';

    return NivoraCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            trend.label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                trend.value % 1 == 0
                    ? trend.value.toInt().toString()
                    : trend.value.toStringAsFixed(2),
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(deltaIcon, color: deltaColor, size: 14),
              Text(
                '$deltaSign${trend.delta % 1 == 0 ? trend.delta.toInt() : trend.delta.toStringAsFixed(2)}',
                style: AppTypography.caption.copyWith(
                  color: deltaColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
//  REFACTORING STEP TILE
// ==========================================
class _RefactoringStepTile extends StatelessWidget {
  final RefactoringStep step;
  const _RefactoringStepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NivoraCard(
        borderColor: step.isCompleted
            ? AppColors.emeraldGreen.withAlpha(50)
            : AppColors.darkBorder,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step number / checkmark
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.isCompleted
                    ? AppColors.emeraldGreen.withAlpha(25)
                    : AppColors.violetAccent.withAlpha(20),
                border: Border.all(
                  color: step.isCompleted
                      ? AppColors.emeraldGreen.withAlpha(100)
                      : AppColors.violetAccent.withAlpha(60),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: step.isCompleted
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: AppColors.emeraldGreen)
                    : Text(
                        '${step.index}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.violetAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppTypography.body.copyWith(
                      color: step.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      decoration: step.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
//  EMPTY STATE
// ==========================================
class _EmptyInsightState extends StatelessWidget {
  final bool isRunning;
  const _EmptyInsightState({required this.isRunning});

  @override
  Widget build(BuildContext context) {
    if (isRunning) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.electricCyan),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Running on-device analysis…',
                style: AppTypography.bodySecondaryOf(context),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.hub_rounded,
              size: 48,
              color: AppColors.textMuted.withAlpha(60),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the NPU Analysis button to begin',
              style: AppTypography.bodySecondaryOf(context),
            ),
            const SizedBox(height: 4),
            Text(
              'Powered by Nivora Local Engine (On-Device)',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
