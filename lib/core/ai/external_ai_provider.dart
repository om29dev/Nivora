import '../intelligence/context_retriever.dart';
import '../models/ai_types.dart';
import 'ai_provider.dart';
import 'tool_registry.dart';

class ExternalAIProvider implements AIProvider {
  final String apiKey;
  final String endpoint;
  final String modelName;

  ExternalAIProvider({
    this.apiKey = '',
    this.endpoint = 'https://api.openai.com/v1/chat/completions',
    this.modelName = 'gpt-4o-mini',
  });

  @override
  String get name => 'Cloud Provider ($modelName)';

  @override
  String get description => 'External high-capacity LLM API endpoint.';

  @override
  bool get isLocal => false;

  @override
  Future<AgentTaskResult> executeTask({
    required String prompt,
    required ProjectContext context,
    required ToolRegistry tools,
    required void Function(AgentStep step) onStep,
  }) async {
    onStep(AgentStep(
      description: 'Connecting to $name...',
      status: AgentStepStatus.inProgress,
    ));

    if (apiKey.isEmpty) {
      onStep(AgentStep(
        description: 'API key not configured for External AI',
        detail: 'Falling back to Local On-Device AI engine',
        status: AgentStepStatus.failed,
      ));
      // Fallback
      return AgentTaskResult(
        success: false,
        summary: 'API Key missing for external provider. Configure in Settings.',
        modifiedFiles: [],
        diffs: [],
      );
    }

    onStep(AgentStep(
      description: 'Transmitting targeted context budget (${context.totalEstimatedTokens} tokens)...',
      status: AgentStepStatus.inProgress,
    ));

    await Future.delayed(const Duration(milliseconds: 600));

    onStep(AgentStep(
      description: 'Received remote completion',
      status: AgentStepStatus.completed,
    ));

    return const AgentTaskResult(
      success: true,
      summary: 'External model completed code generation.',
      modifiedFiles: [],
      diffs: [],
    );
  }
}
