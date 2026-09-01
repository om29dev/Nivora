enum GitFileStatusType {
  modified,
  added,
  deleted,
  renamed,
  untracked,
  ignored,
  clean,
}

class GitFileStatus {
  final String path;
  final GitFileStatusType status;
  final bool isStaged;

  const GitFileStatus({
    required this.path,
    required this.status,
    this.isStaged = false,
  });
}

class GitCommit {
  final String hash;
  final String shortHash;
  final String message;
  final String author;
  final DateTime timestamp;

  const GitCommit({
    required this.hash,
    required this.shortHash,
    required this.message,
    required this.author,
    required this.timestamp,
  });
}

class GitRepoStatus {
  final String currentBranch;
  final List<String> branches;
  final List<GitFileStatus> files;
  final int aheadCount;
  final int behindCount;
  final bool isClean;

  const GitRepoStatus({
    required this.currentBranch,
    required this.branches,
    required this.files,
    this.aheadCount = 0,
    this.behindCount = 0,
    required this.isClean,
  });

  factory GitRepoStatus.clean(String branch) => GitRepoStatus(
        currentBranch: branch,
        branches: [branch],
        files: [],
        aheadCount: 0,
        behindCount: 0,
        isClean: true,
      );
}
