class RepositorySummary {
  final String projectName;
  final String purpose;
  final List<String> techStack;
  final String runtime;
  final String packageManager;
  final List<String> entryPoints;
  final List<String> importantDirectories;
  final Map<String, String> detectedCommands;
  final List<String> dependencies;
  final bool hasReadme;
  final bool hasTests;
  final bool hasGit;
  final int totalFilesIndexed;
  final int totalSymbolsIndexed;

  const RepositorySummary({
    required this.projectName,
    required this.purpose,
    required this.techStack,
    required this.runtime,
    required this.packageManager,
    required this.entryPoints,
    required this.importantDirectories,
    required this.detectedCommands,
    required this.dependencies,
    this.hasReadme = false,
    this.hasTests = false,
    this.hasGit = true,
    this.totalFilesIndexed = 0,
    this.totalSymbolsIndexed = 0,
  });

  Map<String, dynamic> toJson() => {
        'projectName': projectName,
        'purpose': purpose,
        'techStack': techStack,
        'runtime': runtime,
        'packageManager': packageManager,
        'entryPoints': entryPoints,
        'importantDirectories': importantDirectories,
        'detectedCommands': detectedCommands,
        'dependencies': dependencies,
        'hasReadme': hasReadme,
        'hasTests': hasTests,
        'hasGit': hasGit,
        'totalFilesIndexed': totalFilesIndexed,
        'totalSymbolsIndexed': totalSymbolsIndexed,
      };

  factory RepositorySummary.fromJson(Map<String, dynamic> json) =>
      RepositorySummary(
        projectName: json['projectName'] as String? ?? 'Untitled Project',
        purpose: json['purpose'] as String? ?? '',
        techStack: List<String>.from(json['techStack'] as List? ?? []),
        runtime: json['runtime'] as String? ?? 'Unknown',
        packageManager: json['packageManager'] as String? ?? 'Unknown',
        entryPoints: List<String>.from(json['entryPoints'] as List? ?? []),
        importantDirectories:
            List<String>.from(json['importantDirectories'] as List? ?? []),
        detectedCommands:
            Map<String, String>.from(json['detectedCommands'] as Map? ?? {}),
        dependencies: List<String>.from(json['dependencies'] as List? ?? []),
        hasReadme: json['hasReadme'] as bool? ?? false,
        hasTests: json['hasTests'] as bool? ?? false,
        hasGit: json['hasGit'] as bool? ?? true,
        totalFilesIndexed: json['totalFilesIndexed'] as int? ?? 0,
        totalSymbolsIndexed: json['totalSymbolsIndexed'] as int? ?? 0,
      );
}
