import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../models/ai_types.dart';

class NivoraAgentStepWidget extends StatelessWidget {
  final AgentStep step;

  const NivoraAgentStepWidget({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    Widget statusIcon;
    Color textColor = AppColors.textSecondary;

    switch (step.status) {
      case AgentStepStatus.completed:
        statusIcon = const Icon(Icons.check_circle_rounded, color: AppColors.emeraldGreen, size: 16);
        textColor = AppColors.textPrimary;
        break;
      case AgentStepStatus.inProgress:
        statusIcon = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.electricCyan),
        );
        textColor = AppColors.electricCyan;
        break;
      case AgentStepStatus.failed:
        statusIcon = const Icon(Icons.error_outline_rounded, color: AppColors.coralRed, size: 16);
        textColor = AppColors.coralRed;
        break;
      case AgentStepStatus.waitingConfirmation:
        statusIcon = const Icon(Icons.pan_tool_rounded, color: AppColors.amberWarning, size: 16);
        textColor = AppColors.amberWarning;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: statusIcon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: AppTypography.caption.copyWith(
                    color: textColor,
                    fontWeight: step.status == AgentStepStatus.inProgress ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (step.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.detail!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
