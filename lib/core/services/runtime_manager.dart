import 'dart:io';
import '../models/runtime_types.dart';

class RuntimeManager {
  Future<EnvironmentHealth> inspectEnvironment() async {
    final node = await _probeTool('Node.js', 'node', ['--version']);
    final npm = await _probeTool('npm', 'npm', ['--version']);
    final python = await _probeTool('Python', 'python', ['--version']);
    final pip = await _probeTool('pip', 'pip', ['--version']);
    final git = await _probeTool('Git', 'git', ['--version']);
    final shell = await _probeShell();

    return EnvironmentHealth(
      node: node,
      npm: npm,
      python: python,
      pip: pip,
      git: git,
      shell: shell,
    );
  }

  Future<ToolchainInfo> _probeTool(
      String name, String command, List<String> args) async {
    try {
      final result = await Process.run(command, args, runInShell: true);
      if (result.exitCode == 0) {
        final version = result.stdout.toString().trim();
        return ToolchainInfo(
          name: name,
          command: command,
          version: version.isNotEmpty ? version : 'Installed',
          status: ToolchainStatus.ready,
        );
      } else {
        return ToolchainInfo(
          name: name,
          command: command,
          status: ToolchainStatus.notInstalled,
          error: result.stderr.toString().trim(),
        );
      }
    } catch (e) {
      return ToolchainInfo(
        name: name,
        command: command,
        status: ToolchainStatus.notInstalled,
        error: e.toString(),
      );
    }
  }

  Future<ToolchainInfo> _probeShell() async {
    final shellCmd = Platform.isWindows ? 'powershell' : 'sh';
    try {
      final result = await Process.run(
        shellCmd,
        Platform.isWindows ? ['-Command', 'echo Ready'] : ['-c', 'echo Ready'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        return ToolchainInfo(
          name: 'Shell',
          command: shellCmd,
          version: Platform.isWindows ? 'PowerShell / CMD' : 'POSIX Shell',
          status: ToolchainStatus.ready,
        );
      }
    } catch (_) {}

    return const ToolchainInfo(
      name: 'Shell',
      command: 'sh',
      status: ToolchainStatus.ready,
      version: 'Integrated Terminal',
    );
  }
}
