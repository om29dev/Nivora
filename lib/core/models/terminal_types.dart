enum ProcessState {
  idle,
  starting,
  running,
  stopping,
  stopped,
  failed,
}

class TerminalLine {
  final String text;
  final bool isError;
  final bool isInput;
  final DateTime timestamp;

  TerminalLine({
    required this.text,
    this.isError = false,
    this.isInput = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class RunningProcessInfo {
  final int pid;
  final String command;
  final ProcessState state;
  final DateTime startedAt;
  final int? localPort;

  const RunningProcessInfo({
    required this.pid,
    required this.command,
    required this.state,
    required this.startedAt,
    this.localPort,
  });
}
