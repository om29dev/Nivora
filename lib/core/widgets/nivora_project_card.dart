import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../models/project.dart';
import 'nivora_glass_card.dart';
import 'nivora_status.dart';

class NivoraProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const NivoraProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onDelete,
  });

  Color _getLanguageColor(String lang) {
    final l = lang.toLowerCase();
    if (l.contains('dart') || l.contains('flutter')) return const Color(0xFF00D2B8);
    if (l.contains('type') || l.contains('ts')) return AppColors.electricCyan;
    if (l.contains('java') || l.contains('js')) return const Color(0xFFFBBF24);
    if (l.contains('python')) return AppColors.emeraldGreen;
    if (l.contains('rust')) return const Color(0xFFF97316);
    if (l.contains('go')) return const Color(0xFF00ADD8);
    return AppColors.violetAccent;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final dateFormat = DateFormat('MMM d, h:mm a');
    final langColor = _getLanguageColor(project.language);

    return NivoraGlassCard(
      onTap: onTap,
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      borderColor: isDark
          ? Colors.white.withAlpha(22)
          : Colors.black.withAlpha(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Glowing language dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: langColor,
                  boxShadow: [
                    BoxShadow(
                      color: langColor.withAlpha(160),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  project.name,
                  style: AppTypography.h3Of(context).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              NivoraStatus(
                type: project.isClean ? NivoraStatusType.ready : NivoraStatusType.warning,
                label: project.isClean ? 'Clean' : 'Modified',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(
              project.remoteUrl,
              style: AppTypography.captionOf(context).copyWith(
                color: AppColors.textMutedOf(context),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Language pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: langColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: langColor.withAlpha(60), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code_rounded, size: 12, color: langColor),
                    const SizedBox(width: 4),
                    Text(
                      project.language,
                      style: AppTypography.caption.copyWith(
                        color: langColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Branch pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withAlpha(14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withAlpha(20),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fork_right_rounded,
                      size: 12,
                      color: AppColors.textSecondaryOf(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      project.currentBranch,
                      style: AppTypography.captionOf(context).copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                dateFormat.format(project.lastOpened),
                style: AppTypography.captionOf(context).copyWith(
                  fontSize: 10,
                  color: AppColors.textMutedOf(context),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppColors.textMutedOf(context),
                  ),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
