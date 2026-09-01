import '../intelligence/context_retriever.dart';
import '../models/ai_types.dart';
import 'tool_registry.dart';

abstract class AIProvider {
  String get name;
  String get description;
  bool get isLocal;

  Future<AgentTaskResult> executeTask({
    required String prompt,
    required ProjectContext context,
    required ToolRegistry tools,
    required void Function(AgentStep step) onStep,
  });
}
