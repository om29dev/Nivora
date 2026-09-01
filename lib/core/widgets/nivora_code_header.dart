import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class NivoraCodeHeader extends StatelessWidget {
  final String filePath;
  final bool isModified;
  final VoidCallback? onSave;
  final VoidCallback? onAskAI;

  const NivoraCodeHeader({
    super.key,
    required this.filePath,
    this.isModified = false,
    this.onSave,
    this.onAskAI,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.surface(context),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerTheme.color ?? AppColors.border(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 16,
            color: AppColors.textSecondaryOf(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    filePath,
                    style: AppTypography.captionOf(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isModified) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.electricCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onAskAI != null)
            IconButton(
              tooltip: 'Ask AI about this file',
              icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.electricCyan),
              onPressed: onAskAI,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (onSave != null && isModified) ...[
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Save',
              icon: const Icon(Icons.save_outlined, size: 16, color: AppColors.emeraldGreen),
              onPressed: onSave,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
