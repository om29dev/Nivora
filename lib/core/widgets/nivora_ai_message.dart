import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'nivora_card.dart';

class NivoraAIMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final List<Widget>? actionWidgets;
  final DateTime? timestamp;
  final VoidCallback? onEdit;

  const NivoraAIMessage({
    super.key,
    required this.text,
    this.isUser = false,
    this.actionWidgets,
    this.timestamp,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onEdit != null)
              IconButton(
                tooltip: 'Edit message',
                icon: Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondaryOf(context)),
                onPressed: onEdit,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.electricCyan.withAlpha(Theme.of(context).brightness == Brightness.dark ? 40 : 25),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                  border: Border.all(color: AppColors.electricCyan.withAlpha(70)),
                ),
                child: Text(
                  text,
                  style: AppTypography.bodyOf(context),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.electricCyan, AppColors.violetAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: NivoraCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppTypography.bodyOf(context),
                  ),
                  if (actionWidgets != null && actionWidgets!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...actionWidgets!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
