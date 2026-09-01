import 'package:flutter_test/flutter_test.dart';
import 'package:nivora/core/ai/local_nano_llm.dart';
import 'package:nivora/core/ai/patch_engine.dart';
import 'package:nivora/core/ai/tool_registry.dart';
import 'package:nivora/core/intelligence/context_retriever.dart';
import 'package:nivora/core/models/ai_types.dart';
import 'package:nivora/core/models/repository_summary.dart';
import 'package:nivora/core/services/git_service.dart';

void main() {
  group('Local Nano-LLM Engine Tests (Extreme Low-Parameter On-Device)', () {
    test('Default model profile is SmolLM2 135M with ultra-low memory footprint', () {
      final provider = LocalNanoLLMProvider();

      expect(provider.isLocal, isTrue);
      expect(provider.activeProfile.id, equals('smollm2-135m'));
      expect(provider.activeProfile.parameterCount, contains('135'));
      expect(provider.activeProfile.memoryFootprintMb, lessThan(150));
      expect(provider.activeProfile.typicalSpeedTokSec, greaterThan(40.0));
      expect(provider.name, contains('SmolLM2 135M'));
    });

    test('Can switch profiles to Qwen2.5 0.5B and TinyLlama 1.1B', () {
      final provider = LocalNanoLLMProvider();

      final qwenProfile = NanoModelProfile.availableProfiles.firstWhere((p) => p.id == 'qwen2.5-0.5b');
      provider.switchProfile(qwenProfile);
      expect(provider.activeProfile.id, equals('qwen2.5-0.5b'));
      expect(provider.activeProfile.memoryFootprintMb, equals(340));
      expect(provider.name, contains('Qwen2.5 0.5B'));

      final tinyProfile = NanoModelProfile.availableProfiles.firstWhere((p) => p.id == 'tinyllama-1.1b');
      provider.switchProfile(tinyProfile);
      expect(provider.activeProfile.id, equals('tinyllama-1.1b'));
      expect(provider.name, contains('TinyLlama 1.1B'));
    });

    test('Generates conversational dialogue without generating code diffs for questions', () async {
      final provider = LocalNanoLLMProvider();
      final summary = const RepositorySummary(
        projectName: 'TestApp',
        purpose: 'E-commerce mobile client',
        techStack: ['TypeScript', 'React'],
        runtime: 'Node.js',
        packageManager: 'npm',
        entryPoints: ['src/main.tsx'],
        importantDirectories: ['src'],
        detectedCommands: {'run': 'npm run dev', 'test': 'npm test'},
        dependencies: ['react', 'vite'],
      );

      final context = ProjectContext(
        summary: summary,
        files: [],
        matchedSymbols: [],
        totalEstimatedTokens: 450,
      );

      final response = await provider.generateConversationalResponse(
        prompt: 'Explain repository architecture and how it works',
        context: context,
      );

      expect(response, contains('TestApp Architecture Overview'));
      expect(response, contains('TypeScript / React'));
      expect(response, contains('npm run dev'));
    });

    test('Synthesizes code diff for transformation prompts', () async {
      final provider = LocalNanoLLMProvider();
      final summary = const RepositorySummary(
        projectName: 'ThemeDemo',
        purpose: 'Dark theme application',
        techStack: ['TypeScript'],
        runtime: 'Node.js',
        packageManager: 'npm',
        entryPoints: ['src/index.ts'],
        importantDirectories: ['src'],
        detectedCommands: {'run': 'npm run dev'},
        dependencies: [],
      );

      const targetFile = RetrievedContextItem(
        relativePath: 'src/index.ts',
        content: 'export const app = "demo";\n',
        tokenEstimate: 10,
        relevanceReason: 'Entrypoint',
      );

      final context = ProjectContext(
        summary: summary,
        files: [targetFile],
        matchedSymbols: [],
        totalEstimatedTokens: 100,
      );

      final tools = ToolRegistry(
        projectRoot: '.',
        gitService: GitService(),
        patchEngine: PatchEngine(),
      );

      final steps = <AgentStep>[];
      final result = await provider.executeTask(
        prompt: 'Add dark mode theme config',
        context: context,
        tools: tools,
        onStep: (step) => steps.add(step),
      );

      expect(result.success, isTrue);
      expect(result.diffs, isNotEmpty);
      expect(result.modifiedFiles, contains('src/index.ts'));
      expect(result.diffs.first.proposedContent, contains('themeConfig'));
      expect(steps.any((s) => s.status == AgentStepStatus.completed), isTrue);
    });
  });
}
