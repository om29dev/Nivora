import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../models/ai_types.dart';

class NivoraDiffViewer extends StatelessWidget {
  final ProposedDiff diff;
  final VoidCallback? onApply;
  final VoidCallback? onReject;

  const NivoraDiffViewer({
    super.key,
    required this.diff,
    this.onApply,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.darkSurfaceHighlight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              const Icon(Icons.difference_outlined, size: 16, color: AppColors.electricCyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  diff.filePath,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceElevated,
            border: Border.all(color: AppColors.darkBorder),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          child: Column(
            children: diff.hunks.map((hunk) {
              return Column(
                children: hunk.lines.map((line) {
                  Color bg = Colors.transparent;
                  Color textCol = AppColors.textCode;
                  String prefix = ' ';

                  if (line.type == DiffLineType.addition) {
                    bg = AppColors.syntaxDiffAdd.withAlpha(80);
                    textCol = AppColors.syntaxDiffAddText;
                    prefix = '+';
                  } else if (line.type == DiffLineType.deletion) {
                    bg = AppColors.syntaxDiffRemove.withAlpha(80);
                    textCol = AppColors.syntaxDiffRemoveText;
                    prefix = '-';
                  }

                  return Container(
                    color: bg,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            line.oldLineNumber?.toString() ?? '',
                            style: AppTypography.terminal.copyWith(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            line.newLineNumber?.toString() ?? '',
                            style: AppTypography.terminal.copyWith(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 14,
                          child: Text(
                            prefix,
                            style: AppTypography.terminal.copyWith(
                              color: textCol,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line.content,
                            style: AppTypography.terminal.copyWith(color: textCol),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
