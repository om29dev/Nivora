import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../models/project.dart';
import 'nivora_card.dart';
import 'nivora_chip.dart';
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return NivoraCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: AppTypography.h2Of(context),
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
          Text(
            project.remoteUrl,
            style: AppTypography.captionOf(context),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              NivoraChip(
                label: project.language,
                color: AppColors.electricCyan,
                icon: Icons.code,
              ),
              NivoraChip(
                label: project.runtime,
                color: AppColors.violetAccent,
                icon: Icons.memory,
              ),
              NivoraChip(
                label: project.currentBranch,
                color: AppColors.emeraldGreen,
                icon: Icons.fork_right,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active: ${dateFormat.format(project.lastOpened)}',
                style: AppTypography.captionOf(context),
              ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: AppColors.textMutedOf(context)),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
