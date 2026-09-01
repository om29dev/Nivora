import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/ai_types.dart';

class PatchEngine {
  ProposedDiff generateDiff({
    required String filePath,
    required String originalContent,
    required String newContent,
  }) {
    final origLines = originalContent.split('\n');
    final newLines = newContent.split('\n');

    final diffLines = <DiffLine>[];

    // Simple line-based unified diff builder
    int i = 0;
    int j = 0;

    while (i < origLines.length || j < newLines.length) {
      if (i < origLines.length && j < newLines.length && origLines[i] == newLines[j]) {
        diffLines.add(DiffLine(
          type: DiffLineType.context,
          content: origLines[i],
          oldLineNumber: i + 1,
          newLineNumber: j + 1,
        ));
        i++;
        j++;
      } else {
        // Collect deletions
        if (i < origLines.length) {
          diffLines.add(DiffLine(
            type: DiffLineType.deletion,
            content: origLines[i],
            oldLineNumber: i + 1,
          ));
          i++;
        }
        // Collect additions
        if (j < newLines.length) {
          diffLines.add(DiffLine(
            type: DiffLineType.addition,
            content: newLines[j],
            newLineNumber: j + 1,
          ));
          j++;
        }
      }
    }

    final hunk = DiffHunk(
      oldStart: 1,
      oldLines: origLines.length,
      newStart: 1,
      newLines: newLines.length,
      lines: diffLines,
    );

    return ProposedDiff(
      filePath: filePath,
      originalContent: originalContent,
      proposedContent: newContent,
      hunks: [hunk],
    );
  }

  Future<bool> applyDiff({
    required String projectRoot,
    required ProposedDiff diff,
  }) async {
    try {
      final file = File(p.join(projectRoot, diff.filePath));
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsString(diff.proposedContent);
      return true;
    } catch (_) {
      return false;
    }
  }
}
