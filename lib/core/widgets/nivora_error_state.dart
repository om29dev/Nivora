import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'nivora_button.dart';
import 'nivora_card.dart';

class NivoraErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String? cause;
  final String? suggestedAction;
  final VoidCallback? onFixWithAI;
  final VoidCallback? onRetry;

  const NivoraErrorState({
    super.key,
    required this.title,
    required this.message,
    this.cause,
    this.suggestedAction,
    this.onFixWithAI,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: NivoraCard(
        borderColor: AppColors.coralRed.withAlpha(120),
        backgroundColor: AppColors.coralRed.withAlpha(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.coralRed, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.h3.copyWith(color: AppColors.coralRed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: AppTypography.body),
            if (cause != null) ...[
              const SizedBox(height: 8),
              Text(
                'Likely cause: $cause',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (onFixWithAI != null)
                  NivoraButton(
                    text: 'Fix with AI',
                    icon: Icons.auto_awesome,
                    height: 38,
                    onPressed: onFixWithAI,
                  ),
                if (onRetry != null) ...[
                  const SizedBox(width: 12),
                  NivoraSecondaryButton(
                    text: 'Retry',
                    height: 38,
                    onPressed: onRetry,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
