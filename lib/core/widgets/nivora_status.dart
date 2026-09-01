import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

enum NivoraStatusType {
  ready,
  running,
  warning,
  error,
  idle,
}

class NivoraStatus extends StatelessWidget {
  final NivoraStatusType type;
  final String label;

  const NivoraStatus({
    super.key,
    required this.type,
    required this.label,
  });

  Color get color {
    switch (type) {
      case NivoraStatusType.ready:
        return AppColors.emeraldGreen;
      case NivoraStatusType.running:
        return AppColors.electricCyan;
      case NivoraStatusType.warning:
        return AppColors.amberWarning;
      case NivoraStatusType.error:
        return AppColors.coralRed;
      case NivoraStatusType.idle:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(120),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
