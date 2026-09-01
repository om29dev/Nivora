import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'nivora_button.dart';

class NivoraDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const NivoraDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => NivoraDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialogBg = Theme.of(context).cardTheme.color ?? AppColors.surface(context);
    final borderColor = Theme.of(context).dividerTheme.color ?? AppColors.border(context);

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isDestructive)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.warning_amber_rounded, color: AppColors.coralRed, size: 22),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.h2Of(context).copyWith(
                      color: isDestructive ? AppColors.coralRed : AppColors.text(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTypography.bodySecondaryOf(context),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel ?? () => Navigator.of(context).pop(),
                  child: Text(
                    cancelText,
                    style: AppTypography.button.copyWith(color: AppColors.textSecondaryOf(context)),
                  ),
                ),
                const SizedBox(width: 8),
                NivoraButton(
                  text: confirmText,
                  height: 40,
                  backgroundColor: isDestructive ? AppColors.coralRed : AppColors.electricCyan,
                  onPressed: onConfirm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
