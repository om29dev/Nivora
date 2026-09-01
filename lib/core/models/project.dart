class Project {
  final String id;
  final String name;
  final String path;
  final String remoteUrl;
  final String currentBranch;
  final String language;
  final String runtime;
  final String packageManager;
  final DateTime lastOpened;
  final bool isClean;
  final String? runCommand;
  final String? buildCommand;
  final String? testCommand;

  const Project({
    required this.id,
    required this.name,
    required this.path,
    required this.remoteUrl,
    this.currentBranch = 'main',
    this.language = 'Unknown',
    this.runtime = 'Unknown',
    this.packageManager = 'Unknown',
    required this.lastOpened,
    this.isClean = true,
    this.runCommand,
    this.buildCommand,
    this.testCommand,
  });

  Project copyWith({
    String? id,
    String? name,
    String? path,
    String? remoteUrl,
    String? currentBranch,
    String? language,
    String? runtime,
    String? packageManager,
    DateTime? lastOpened,
    bool? isClean,
    String? runCommand,
    String? buildCommand,
    String? testCommand,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      currentBranch: currentBranch ?? this.currentBranch,
      language: language ?? this.language,
      runtime: runtime ?? this.runtime,
      packageManager: packageManager ?? this.packageManager,
      lastOpened: lastOpened ?? this.lastOpened,
      isClean: isClean ?? this.isClean,
      runCommand: runCommand ?? this.runCommand,
      buildCommand: buildCommand ?? this.buildCommand,
      testCommand: testCommand ?? this.testCommand,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'remoteUrl': remoteUrl,
        'currentBranch': currentBranch,
        'language': language,
        'runtime': runtime,
        'packageManager': packageManager,
        'lastOpened': lastOpened.toIso8601String(),
        'isClean': isClean,
        'runCommand': runCommand,
        'buildCommand': buildCommand,
        'testCommand': testCommand,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        path: json['path'] as String,
        remoteUrl: json['remoteUrl'] as String,
        currentBranch: (json['currentBranch'] as String?) ?? 'main',
        language: (json['language'] as String?) ?? 'Unknown',
        runtime: (json['runtime'] as String?) ?? 'Unknown',
        packageManager: (json['packageManager'] as String?) ?? 'Unknown',
        lastOpened: DateTime.parse(json['lastOpened'] as String),
        isClean: (json['isClean'] as bool?) ?? true,
        runCommand: json['runCommand'] as String?,
        buildCommand: json['buildCommand'] as String?,
        testCommand: json['testCommand'] as String?,
      );
}
