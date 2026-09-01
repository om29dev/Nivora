import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../models/git_types.dart';

class NivoraFileRow extends StatelessWidget {
  final String fileName;
  final bool isDirectory;
  final bool isExpanded;
  final int depth;
  final GitFileStatusType gitStatus;
  final VoidCallback onTap;

  const NivoraFileRow({
    super.key,
    required this.fileName,
    required this.isDirectory,
    this.isExpanded = false,
    this.depth = 0,
    this.gitStatus = GitFileStatusType.clean,
    required this.onTap,
  });

  IconData get icon {
    if (isDirectory) {
      return isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded;
    }
    if (fileName.endsWith('.js') || fileName.endsWith('.ts') || fileName.endsWith('.tsx') || fileName.endsWith('.jsx')) {
      return Icons.javascript_rounded;
    }
    if (fileName.endsWith('.py')) {
      return Icons.terminal_rounded;
    }
    if (fileName.endsWith('.json')) {
      return Icons.data_object_rounded;
    }
    if (fileName.endsWith('.md')) {
      return Icons.description_rounded;
    }
    if (fileName.endsWith('.html') || fileName.endsWith('.css')) {
      return Icons.web_rounded;
    }
    return Icons.insert_drive_file_outlined;
  }

  Color get iconColor {
    if (isDirectory) return AppColors.amberWarning;
    if (fileName.endsWith('.ts') || fileName.endsWith('.tsx')) return AppColors.skyBlue;
    if (fileName.endsWith('.js')) return AppColors.amberWarning;
    if (fileName.endsWith('.py')) return AppColors.electricCyan;
    if (fileName.endsWith('.json')) return AppColors.emeraldGreen;
    if (fileName.endsWith('.md')) return AppColors.violetAccent;
    return AppColors.textSecondary;
  }

  Widget? get gitBadge {
    switch (gitStatus) {
      case GitFileStatusType.modified:
        return const Text('M', style: TextStyle(color: AppColors.amberWarning, fontWeight: FontWeight.bold, fontSize: 12));
      case GitFileStatusType.added:
        return const Text('A', style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 12));
      case GitFileStatusType.deleted:
        return const Text('D', style: TextStyle(color: AppColors.coralRed, fontWeight: FontWeight.bold, fontSize: 12));
      case GitFileStatusType.untracked:
        return const Text('U', style: TextStyle(color: AppColors.infoBlue, fontWeight: FontWeight.bold, fontSize: 12));
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: EdgeInsets.only(
          left: (depth * 16.0) + 8,
          right: 12,
          top: 8,
          bottom: 8,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileName,
                style: AppTypography.bodyOf(context).copyWith(
                  fontWeight: isDirectory ? FontWeight.w500 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (gitBadge != null) ...[
              const SizedBox(width: 8),
              gitBadge!,
            ],
          ],
        ),
      ),
    );
  }
}
