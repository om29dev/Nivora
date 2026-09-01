enum AgentStepStatus {
  inProgress,
  completed,
  failed,
  waitingConfirmation,
}

class AgentStep {
  final String description;
  final AgentStepStatus status;
  final String? detail;
  final DateTime timestamp;

  AgentStep({
    required this.description,
    this.status = AgentStepStatus.inProgress,
    this.detail,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  AgentStep copyWith({
    String? description,
    AgentStepStatus? status,
    String? detail,
  }) {
    return AgentStep(
      description: description ?? this.description,
      status: status ?? this.status,
      detail: detail ?? this.detail,
      timestamp: timestamp,
    );
  }
}

class ProposedDiff {
  final String filePath;
  final String originalContent;
  final String proposedContent;
  final List<DiffHunk> hunks;

  const ProposedDiff({
    required this.filePath,
    required this.originalContent,
    required this.proposedContent,
    required this.hunks,
  });
}

class DiffHunk {
  final int oldStart;
  final int oldLines;
  final int newStart;
  final int newLines;
  final List<DiffLine> lines;

  const DiffHunk({
    required this.oldStart,
    required this.oldLines,
    required this.newStart,
    required this.newLines,
    required this.lines,
  });
}

enum DiffLineType { context, addition, deletion }

class DiffLine {
  final DiffLineType type;
  final String content;
  final int? oldLineNumber;
  final int? newLineNumber;

  const DiffLine({
    required this.type,
    required this.content,
    this.oldLineNumber,
    this.newLineNumber,
  });
}

class AgentTaskResult {
  final bool success;
  final String summary;
  final List<String> modifiedFiles;
  final List<ProposedDiff> diffs;
  final String? testSummary;

  const AgentTaskResult({
    required this.success,
    required this.summary,
    required this.modifiedFiles,
    required this.diffs,
    this.testSummary,
  });
}
