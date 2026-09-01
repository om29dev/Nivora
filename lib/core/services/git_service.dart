import 'dart:io';
import '../models/git_types.dart';

class GitService {
  Future<bool> cloneRepository({
    required String remoteUrl,
    required String targetDirectory,
    String branch = 'main',
    void Function(String progressStage)? onProgress,
  }) async {
    try {
      onProgress?.call('Connecting to GitHub...');
      await Future.delayed(const Duration(milliseconds: 300));

      onProgress?.call('Downloading repository...');
      final result = await Process.run(
        'git',
        ['clone', '--branch', branch, '--depth', '1', remoteUrl, targetDirectory],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        // Fallback clone without branch specification if default branch differs
        final fallbackResult = await Process.run(
          'git',
          ['clone', '--depth', '1', remoteUrl, targetDirectory],
          runInShell: true,
        );
        if (fallbackResult.exitCode != 0) {
          throw Exception(fallbackResult.stderr.toString());
        }
      }

      onProgress?.call('Preparing environment...');
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<GitRepoStatus> getStatus(String repoPath) async {
    try {
      // 1. Get branch
      final branchResult = await Process.run(
        'git',
        ['rev-parse', '--abbrev-ref', 'HEAD'],
        workingDirectory: repoPath,
        runInShell: true,
      );
      final currentBranch = branchResult.exitCode == 0
          ? branchResult.stdout.toString().trim()
          : 'main';

      // 2. Get status porcelain
      final statusResult = await Process.run(
        'git',
        ['status', '--porcelain'],
        workingDirectory: repoPath,
        runInShell: true,
      );

      final files = <GitFileStatus>[];
      if (statusResult.exitCode == 0) {
        final lines = statusResult.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.length < 3) continue;
          final x = line[0];
          final y = line[1];
          final filePath = line.substring(3).trim();

          GitFileStatusType statusType = GitFileStatusType.modified;
          bool isStaged = false;

          if (x == '?' && y == '?') {
            statusType = GitFileStatusType.untracked;
          } else if (x == 'A' || y == 'A') {
            statusType = GitFileStatusType.added;
            isStaged = (x == 'A');
          } else if (x == 'D' || y == 'D') {
            statusType = GitFileStatusType.deleted;
            isStaged = (x == 'D');
          } else if (x == 'M' || y == 'M') {
            statusType = GitFileStatusType.modified;
            isStaged = (x == 'M');
          }

          files.add(GitFileStatus(
            path: filePath,
            status: statusType,
            isStaged: isStaged,
          ));
        }
      }

      // 3. Get branches
      final branchListResult = await Process.run(
        'git',
        ['branch'],
        workingDirectory: repoPath,
        runInShell: true,
      );
      final branches = <String>[];
      if (branchListResult.exitCode == 0) {
        for (final b in branchListResult.stdout.toString().split('\n')) {
          final cleanB = b.replaceAll('*', '').trim();
          if (cleanB.isNotEmpty) branches.add(cleanB);
        }
      }
      if (branches.isEmpty) branches.add(currentBranch);

      return GitRepoStatus(
        currentBranch: currentBranch,
        branches: branches,
        files: files,
        isClean: files.isEmpty,
      );
    } catch (_) {
      return GitRepoStatus.clean('main');
    }
  }

  Future<String> getDiff(String repoPath, {String? filePath}) async {
    try {
      final args = ['diff'];
      if (filePath != null) args.add(filePath);

      final result = await Process.run(
        'git',
        args,
        workingDirectory: repoPath,
        runInShell: true,
      );
      return result.exitCode == 0 ? result.stdout.toString() : '';
    } catch (_) {
      return '';
    }
  }

  Future<bool> stageFile(String repoPath, String filePath) async {
    try {
      final result = await Process.run(
        'git',
        ['add', filePath],
        workingDirectory: repoPath,
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stageAll(String repoPath) async {
    try {
      final result = await Process.run(
        'git',
        ['add', '-A'],
        workingDirectory: repoPath,
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> commit(String repoPath, String message) async {
    try {
      final result = await Process.run(
        'git',
        ['commit', '-m', message],
        workingDirectory: repoPath,
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<List<GitCommit>> getCommitHistory(String repoPath, {int limit = 10}) async {
    try {
      final result = await Process.run(
        'git',
        ['log', '-n', '$limit', '--pretty=format:%H|%h|%s|%an|%ad', '--date=iso'],
        workingDirectory: repoPath,
        runInShell: true,
      );

      if (result.exitCode != 0) return [];

      final commits = <GitCommit>[];
      for (final line in result.stdout.toString().split('\n')) {
        final parts = line.split('|');
        if (parts.length >= 5) {
          commits.add(GitCommit(
            hash: parts[0],
            shortHash: parts[1],
            message: parts[2],
            author: parts[3],
            timestamp: DateTime.tryParse(parts[4]) ?? DateTime.now(),
          ));
        }
      }
      return commits;
    } catch (_) {
      return [];
    }
  }

  Future<bool> checkoutBranch(String repoPath, String branch) async {
    try {
      final result = await Process.run(
        'git',
        ['checkout', branch],
        workingDirectory: repoPath,
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
