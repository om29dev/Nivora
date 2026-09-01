enum ToolchainStatus {
  ready,
  checking,
  notInstalled,
  error,
}

class ToolchainInfo {
  final String name;
  final String command;
  final String? version;
  final ToolchainStatus status;
  final String? path;
  final String? error;

  const ToolchainInfo({
    required this.name,
    required this.command,
    this.version,
    this.status = ToolchainStatus.checking,
    this.path,
    this.error,
  });

  ToolchainInfo copyWith({
    String? version,
    ToolchainStatus? status,
    String? path,
    String? error,
  }) {
    return ToolchainInfo(
      name: name,
      command: command,
      version: version ?? this.version,
      status: status ?? this.status,
      path: path ?? this.path,
      error: error ?? this.error,
    );
  }
}

class EnvironmentHealth {
  final ToolchainInfo node;
  final ToolchainInfo npm;
  final ToolchainInfo python;
  final ToolchainInfo pip;
  final ToolchainInfo git;
  final ToolchainInfo shell;

  const EnvironmentHealth({
    required this.node,
    required this.npm,
    required this.python,
    required this.pip,
    required this.git,
    required this.shell,
  });
}
