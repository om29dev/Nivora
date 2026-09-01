import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blast_radius_data.dart';

// --- NPU Inference State ---
enum NpuInferenceStatus { idle, running, completed, failed }

class NpuInferenceState {
  final NpuInferenceStatus status;
  final String? statusMessage;
  final double progress; // 0.0 – 1.0
  final BlastRadiusData? result;

  const NpuInferenceState({
    this.status = NpuInferenceStatus.idle,
    this.statusMessage,
    this.progress = 0.0,
    this.result,
  });

  NpuInferenceState copyWith({
    NpuInferenceStatus? status,
    String? statusMessage,
    double? progress,
    BlastRadiusData? result,
  }) {
    return NpuInferenceState(
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      progress: progress ?? this.progress,
      result: result ?? this.result,
    );
  }
}

final npuInferenceProvider =
    StateNotifierProvider<NpuInferenceNotifier, NpuInferenceState>(
  (ref) => NpuInferenceNotifier(),
);

class NpuInferenceNotifier extends StateNotifier<NpuInferenceState> {
  NpuInferenceNotifier() : super(const NpuInferenceState());

  Future<void> runAnalysis() async {
    state = state.copyWith(
      status: NpuInferenceStatus.running,
      statusMessage: 'Initializing NPU graph compiler…',
      progress: 0.0,
    );

    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(
      statusMessage: 'Scanning dependency tree…',
      progress: 0.15,
    );

    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      statusMessage: 'Building adjacency matrix…',
      progress: 0.35,
    );

    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(
      statusMessage: 'Running on-device NPU inference…',
      progress: 0.55,
    );

    await Future.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(
      statusMessage: 'Computing blast radius…',
      progress: 0.78,
    );

    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(
      statusMessage: 'Generating refactoring plan…',
      progress: 0.92,
    );

    await Future.delayed(const Duration(milliseconds: 300));

    final data = _generateMockBlastRadius();
    state = state.copyWith(
      status: NpuInferenceStatus.completed,
      statusMessage: 'Analysis complete',
      progress: 1.0,
      result: data,
    );
  }

  void reset() {
    state = const NpuInferenceState();
  }

  BlastRadiusData _generateMockBlastRadius() {
    final rng = Random(42);

    const target = DependencyNode(
      id: 'target',
      label: 'editor_screen.dart',
      degree: DependencyDegree.target,
      riskScore: 0.85,
    );

    final firstDegreeLabels = [
      'syntax_highlighter.dart',
      'file_explorer.dart',
      'ai_assistant.dart',
      'terminal_bridge.dart',
      'git_service.dart',
    ];

    final secondDegreeLabels = [
      'theme_provider.dart',
      'process_manager.dart',
      'patch_engine.dart',
      'context_retriever.dart',
      'symbol_indexer.dart',
      'storage_service.dart',
      'runtime_manager.dart',
      'office_kit.dart',
    ];

    final nodes = <DependencyNode>[target];
    final edges = <DependencyEdge>[];

    for (final label in firstDegreeLabels) {
      final node = DependencyNode(
        id: 'f_$label',
        label: label,
        degree: DependencyDegree.firstDegree,
        riskScore: 0.3 + rng.nextDouble() * 0.5,
      );
      nodes.add(node);
      edges.add(DependencyEdge(
        fromId: 'target',
        toId: node.id,
        weight: 1.0 + rng.nextDouble(),
      ));
    }

    for (final label in secondDegreeLabels) {
      final node = DependencyNode(
        id: 's_$label',
        label: label,
        degree: DependencyDegree.secondDegree,
        riskScore: 0.1 + rng.nextDouble() * 0.3,
      );
      nodes.add(node);

      // Connect to a random first-degree node
      final parentIdx = 1 + rng.nextInt(firstDegreeLabels.length);
      edges.add(DependencyEdge(
        fromId: nodes[parentIdx].id,
        toId: node.id,
        weight: 0.6 + rng.nextDouble() * 0.8,
      ));
    }

    const couplingTrends = [
      CouplingTrend(label: 'Afferent', value: 7, delta: 2),
      CouplingTrend(label: 'Efferent', value: 12, delta: -1),
      CouplingTrend(label: 'Instability', value: 0.63, delta: 0.05),
      CouplingTrend(label: 'Abstractness', value: 0.28, delta: -0.03),
    ];

    const refactoringPlan = [
      RefactoringStep(
        index: 1,
        title: 'Extract SyntaxHighlighter Interface',
        description:
            'Decouple highlighting logic from EditorScreen via an abstract contract.',
      ),
      RefactoringStep(
        index: 2,
        title: 'Inject FileExplorer via Provider',
        description:
            'Replace direct instantiation with Riverpod provider for testability.',
      ),
      RefactoringStep(
        index: 3,
        title: 'Isolate Terminal Bridge',
        description:
            'Move terminal IPC to a dedicated service layer with message queue.',
        isCompleted: true,
      ),
      RefactoringStep(
        index: 4,
        title: 'Add Integration Tests',
        description:
            'Cover the 3 highest-risk coupling points with golden tests.',
      ),
    ];

    return BlastRadiusData(
      target: target,
      nodes: nodes,
      edges: edges,
      couplingTrends: couplingTrends,
      refactoringPlan: refactoringPlan,
      overallRisk: 0.72,
    );
  }
}
