import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/git_types.dart';
import '../services/git_service.dart';
import 'patch_engine.dart';

class ToolRegistry {
  final String projectRoot;
  final GitService gitService;
  final PatchEngine patchEngine;

  ToolRegistry({
    required this.projectRoot,
    required this.gitService,
    required this.patchEngine,
  });

  bool isDestructive(String toolName, Map<String, dynamic> args) {
    if (toolName == 'apply_patch') return true;
    if (toolName == 'run_command') {
      final cmd = (args['command'] as String? ?? '').toLowerCase();
      if (cmd.contains('rm ') || cmd.contains('git reset') || cmd.contains('git checkout --')) {
        return true;
      }
    }
    return false;
  }

  Future<String> searchCode(String query) async {
    final results = <String>[];
    try {
      final dir = Directory(projectRoot);
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && !entity.path.contains('.git') && !entity.path.contains('node_modules')) {
          try {
            final content = await entity.readAsString();
            if (content.toLowerCase().contains(query.toLowerCase())) {
              results.add(p.relative(entity.path, from: projectRoot));
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return results.isEmpty ? 'No matching files found.' : results.take(10).join('\n');
  }

  Future<String> readFile(String relativePath, {int? startLine, int? endLine}) async {
    try {
      final file = File(p.join(projectRoot, relativePath));
      if (!await file.exists()) return 'File not found: $relativePath';
      final lines = await file.readAsLines();

      final s = (startLine != null && startLine > 0) ? startLine - 1 : 0;
      final e = (endLine != null && endLine <= lines.length) ? endLine : lines.length;

      return lines.sublist(s, e).join('\n');
    } catch (e) {
      return 'Error reading file: $e';
    }
  }

  Future<GitRepoStatus> getGitStatus() async {
    return await gitService.getStatus(projectRoot);
  }

  Future<String> getGitDiff({String? filePath}) async {
    return await gitService.getDiff(projectRoot, filePath: filePath);
  }
}
