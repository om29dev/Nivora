import 'dart:io';
import 'package:path/path.dart' as p;

class MarkdownAnalysisResult {
  final String purpose;
  final List<String> features;
  final List<String> extractedCommands;
  final List<String> architectureNotes;
  final List<String> environmentVariables;
  final bool foundReadme;

  const MarkdownAnalysisResult({
    required this.purpose,
    required this.features,
    required this.extractedCommands,
    required this.architectureNotes,
    required this.environmentVariables,
    required this.foundReadme,
  });
}

class MarkdownAnalyzer {
  Future<MarkdownAnalysisResult> analyze(String projectRoot) async {
    final readmeCandidates = [
      'README.md',
      'readme.md',
      'Readme.md',
      'README.markdown',
      'README',
    ];

    File? readmeFile;
    for (final name in readmeCandidates) {
      final file = File(p.join(projectRoot, name));
      if (await file.exists()) {
        readmeFile = file;
        break;
      }
    }

    if (readmeFile == null) {
      return const MarkdownAnalysisResult(
        purpose: 'No README documentation found in repository.',
        features: [],
        extractedCommands: [],
        architectureNotes: [],
        environmentVariables: [],
        foundReadme: false,
      );
    }

    try {
      final content = await readmeFile.readAsString();
      return _parseMarkdown(content);
    } catch (_) {
      return const MarkdownAnalysisResult(
        purpose: 'Failed to read README documentation.',
        features: [],
        extractedCommands: [],
        architectureNotes: [],
        environmentVariables: [],
        foundReadme: true,
      );
    }
  }

  MarkdownAnalysisResult _parseMarkdown(String content) {
    final lines = content.split('\n');
    String purpose = '';
    final features = <String>[];
    final commands = <String>[];
    final architecture = <String>[];
    final envVars = <String>[];

    bool inCodeBlock = false;
    String currentSection = '';

    // First non-heading, non-badge paragraph is usually the purpose
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        continue;
      }

      if (inCodeBlock) {
        // Collect code block commands
        if (trimmed.startsWith('npm ') ||
            trimmed.startsWith('pnpm ') ||
            trimmed.startsWith('yarn ') ||
            trimmed.startsWith('pip ') ||
            trimmed.startsWith('python ') ||
            trimmed.startsWith('cargo ') ||
            trimmed.startsWith('git ')) {
          commands.add(trimmed);
        }
        continue;
      }

      // Check for inline backtick commands (e.g. `npm run dev`)
      final inlineMatch = RegExp(r'`(npm|pnpm|yarn|pip|python|cargo|git)\s+[^`]+`').firstMatch(line);
      if (inlineMatch != null) {
        commands.add(inlineMatch.group(0)!.replaceAll('`', ''));
      }

      if (trimmed.startsWith('#')) {
        currentSection = trimmed.replaceAll(RegExp(r'^#+\s*'), '').toLowerCase();
        continue;
      }

      // Purpose extraction
      if (purpose.isEmpty &&
          trimmed.isNotEmpty &&
          !trimmed.startsWith('[!') &&
          !trimmed.startsWith('<') &&
          !trimmed.startsWith('![')) {
        purpose = trimmed;
      }

      // Feature extraction
      if ((currentSection.contains('feature') || currentSection.contains('what')) &&
          (trimmed.startsWith('- ') || trimmed.startsWith('* '))) {
        features.add(trimmed.substring(2).trim());
      }

      // Architecture extraction
      if (currentSection.contains('architecture') || currentSection.contains('structure')) {
        if (trimmed.isNotEmpty) architecture.add(trimmed);
      }

      // Env vars extraction
      if (trimmed.contains('=') &&
          (currentSection.contains('env') || currentSection.contains('config'))) {
        final match = RegExp(r'^[A-Z0-9_]+').firstMatch(trimmed);
        if (match != null) {
          envVars.add(match.group(0)!);
        }
      }
    }

    return MarkdownAnalysisResult(
      purpose: purpose.isNotEmpty ? purpose : 'Repository codebase',
      features: features.take(8).toList(),
      extractedCommands: commands.toSet().toList(),
      architectureNotes: architecture.take(5).toList(),
      environmentVariables: envVars.toSet().toList(),
      foundReadme: true,
    );
  }
}
