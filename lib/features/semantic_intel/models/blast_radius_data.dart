/// Data models for the Semantic Intel blast radius visualization.

enum DependencyDegree { target, firstDegree, secondDegree }

class DependencyNode {
  final String id;
  final String label;
  final DependencyDegree degree;
  final double riskScore; // 0.0 – 1.0

  const DependencyNode({
    required this.id,
    required this.label,
    required this.degree,
    this.riskScore = 0.0,
  });
}

class DependencyEdge {
  final String fromId;
  final String toId;
  final double weight; // visual thickness

  const DependencyEdge({
    required this.fromId,
    required this.toId,
    this.weight = 1.0,
  });
}

class CouplingTrend {
  final String label;
  final double value;
  final double delta; // +/- from previous

  const CouplingTrend({
    required this.label,
    required this.value,
    this.delta = 0.0,
  });
}

class RefactoringStep {
  final int index;
  final String title;
  final String description;
  final bool isCompleted;

  const RefactoringStep({
    required this.index,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });
}

/// Complete blast radius dataset for a code change analysis.
class BlastRadiusData {
  final DependencyNode target;
  final List<DependencyNode> nodes;
  final List<DependencyEdge> edges;
  final List<CouplingTrend> couplingTrends;
  final List<RefactoringStep> refactoringPlan;
  final double overallRisk;

  const BlastRadiusData({
    required this.target,
    required this.nodes,
    required this.edges,
    this.couplingTrends = const [],
    this.refactoringPlan = const [],
    this.overallRisk = 0.0,
  });
}
