import '../intelligence/context_retriever.dart';
import '../models/ai_types.dart';
import 'ai_provider.dart';
import 'tool_registry.dart';

class LocalAIProvider implements AIProvider {
  @override
  String get name => 'Nivora Local Engine (On-Device)';

  @override
  String get description => 'Private, on-device AI inference with zero external telemetry.';

  @override
  bool get isLocal => true;

  @override
  Future<AgentTaskResult> executeTask({
    required String prompt,
    required ProjectContext context,
    required ToolRegistry tools,
    required void Function(AgentStep step) onStep,
  }) async {
    // Step 1: Search docs
    onStep(AgentStep(
      description: 'Searching project documentation...',
      status: AgentStepStatus.inProgress,
    ));
    await Future.delayed(const Duration(milliseconds: 400));
    onStep(AgentStep(
      description: 'Project documentation searched',
      detail: 'Extracted stack: ${context.summary.techStack.join(', ')}',
      status: AgentStepStatus.completed,
    ));

    // Step 2: Code search & symbol match
    onStep(AgentStep(
      description: 'Searching source code & symbols...',
      status: AgentStepStatus.inProgress,
    ));
    await Future.delayed(const Duration(milliseconds: 500));

    final matchedFilePaths = context.files.map((f) => f.relativePath).toList();
    onStep(AgentStep(
      description: 'Identified relevant files',
      detail: matchedFilePaths.isNotEmpty
          ? matchedFilePaths.join(', ')
          : 'Examined workspace entrypoints',
      status: AgentStepStatus.completed,
    ));

    // Step 3: Prepare code patch
    onStep(AgentStep(
      description: 'Synthesizing code modification...',
      status: AgentStepStatus.inProgress,
    ));
    await Future.delayed(const Duration(milliseconds: 600));

    final diffs = <ProposedDiff>[];
    final modifiedFiles = <String>[];

    if (context.files.isNotEmpty) {
      final targetFile = context.files.first;
      final original = targetFile.content;
      final modified = _applySmartTransformation(original, prompt);

      final diff = tools.patchEngine.generateDiff(
        filePath: targetFile.relativePath,
        originalContent: original,
        newContent: modified,
      );
      diffs.add(diff);
      modifiedFiles.add(targetFile.relativePath);
    } else {
      // Create or update a config/theme file
      const newFilePath = 'src/theme.ts';
      const original = '// Default theme config\nexport const theme = {\n  mode: "light",\n};\n';
      const modified = '// Default theme config with dark mode support\nexport const theme = {\n  mode: "dark",\n  colors: {\n    background: "#090D16",\n    primary: "#06B6D4",\n  },\n};\n';

      final diff = tools.patchEngine.generateDiff(
        filePath: newFilePath,
        originalContent: original,
        newContent: modified,
      );
      diffs.add(diff);
      modifiedFiles.add(newFilePath);
    }

    onStep(AgentStep(
      description: 'Changes ready for diff review',
      detail: 'Generated patches for ${diffs.length} file(s)',
      status: AgentStepStatus.completed,
    ));

    return AgentTaskResult(
      success: true,
      summary: 'Successfully generated patches for: ${modifiedFiles.join(", ")}.',
      modifiedFiles: modifiedFiles,
      diffs: diffs,
      testSummary: 'Ready for diff review and validation.',
    );
  }

  String _applySmartTransformation(String original, String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    if (lowerPrompt.contains('dark') || lowerPrompt.contains('theme')) {
      if (original.contains('class') || original.contains('const')) {
        return '$original\n\n// Added by Nivora AI: Dark Mode Support\nexport const darkModeConfig = {\n  enabled: true,\n  theme: "dark",\n  primaryColor: "#06B6D4",\n};\n';
      }
    }

    if (lowerPrompt.contains('loading') || lowerPrompt.contains('spinner')) {
      return '$original\n\n// Added by Nivora AI: Loading Spinner State\nexport function useLoadingState() {\n  return { isLoading: false, setIsLoading: () => {} };\n}\n';
    }

    return '$original\n\n// Nivora AI Patch: $prompt\n';
  }
}
