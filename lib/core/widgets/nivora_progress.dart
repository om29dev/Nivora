import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class ProgressStepItem {
  final String label;
  final bool isCompleted;
  final bool isInProgress;
  final bool isFailed;

  const ProgressStepItem({
    required this.label,
    this.isCompleted = false,
    this.isInProgress = false,
    this.isFailed = false,
  });
}

class NivoraProgress extends StatelessWidget {
  final List<ProgressStepItem> steps;

  const NivoraProgress({
    super.key,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.map((step) {
        Widget leadingWidget;
        Color textColor = AppColors.textSecondaryOf(context);

        if (step.isCompleted) {
          leadingWidget = const Icon(
            Icons.check_circle_rounded,
            color: AppColors.emeraldGreen,
            size: 18,
          );
          textColor = AppColors.text(context);
        } else if (step.isInProgress) {
          leadingWidget = const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.electricCyan,
            ),
          );
          textColor = AppColors.electricCyan;
        } else if (step.isFailed) {
          leadingWidget = const Icon(
            Icons.cancel_rounded,
            color: AppColors.coralRed,
            size: 18,
          );
          textColor = AppColors.coralRed;
        } else {
          leadingWidget = Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerTheme.color ?? AppColors.border(context),
              shape: BoxShape.circle,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Center(child: leadingWidget),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.label,
                  style: AppTypography.bodyOf(context).copyWith(
                    color: textColor,
                    fontWeight: step.isInProgress || step.isCompleted
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
