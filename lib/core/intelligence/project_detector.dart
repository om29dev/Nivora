import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class DetectedProjectMetadata {
  final String language;
  final String runtime;
  final String packageManager;
  final List<String> techStack;
  final Map<String, String> detectedCommands;
  final List<String> dependencies;
  final List<String> entryPoints;

  const DetectedProjectMetadata({
    required this.language,
    required this.runtime,
    required this.packageManager,
    required this.techStack,
    required this.detectedCommands,
    required this.dependencies,
    required this.entryPoints,
  });
}

class ProjectDetector {
  Future<DetectedProjectMetadata> detect(String projectRoot) async {
    final rootDir = Directory(projectRoot);
    if (!await rootDir.exists()) {
      return const DetectedProjectMetadata(
        language: 'Unknown',
        runtime: 'Unknown',
        packageManager: 'Unknown',
        techStack: [],
        detectedCommands: {},
        dependencies: [],
        entryPoints: [],
      );
    }

    // 1. Check package.json (Node.js / Web / TypeScript)
    final packageJsonFile = File(p.join(projectRoot, 'package.json'));
    if (await packageJsonFile.exists()) {
      return await _detectNodeProject(projectRoot, packageJsonFile);
    }

    // 2. Check Python manifests
    final reqFile = File(p.join(projectRoot, 'requirements.txt'));
    final pyprojectFile = File(p.join(projectRoot, 'pyproject.toml'));
    if (await reqFile.exists() || await pyprojectFile.exists()) {
      return await _detectPythonProject(projectRoot, reqFile, pyprojectFile);
    }

    // 3. Check Go (go.mod)
    final goModFile = File(p.join(projectRoot, 'go.mod'));
    if (await goModFile.exists()) {
      return const DetectedProjectMetadata(
        language: 'Go',
        runtime: 'Go',
        packageManager: 'go modules',
        techStack: ['Go'],
        detectedCommands: {
          'run': 'go run .',
          'build': 'go build .',
          'test': 'go test ./...',
        },
        dependencies: [],
        entryPoints: ['main.go'],
      );
    }

    // 4. Check Rust (Cargo.toml)
    final cargoFile = File(p.join(projectRoot, 'Cargo.toml'));
    if (await cargoFile.exists()) {
      return const DetectedProjectMetadata(
        language: 'Rust',
        runtime: 'Rust / Cargo',
        packageManager: 'cargo',
        techStack: ['Rust'],
        detectedCommands: {
          'run': 'cargo run',
          'build': 'cargo build',
          'test': 'cargo test',
        },
        dependencies: [],
        entryPoints: ['src/main.rs', 'src/lib.rs'],
      );
    }

    // 5. Check Flutter / Dart (pubspec.yaml)
    final pubspecFile = File(p.join(projectRoot, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      return const DetectedProjectMetadata(
        language: 'Dart',
        runtime: 'Flutter',
        packageManager: 'flutter pub',
        techStack: ['Flutter', 'Dart'],
        detectedCommands: {
          'run': 'flutter run',
          'build': 'flutter build apk',
          'test': 'flutter test',
        },
        dependencies: [],
        entryPoints: ['lib/main.dart'],
      );
    }

    // Default Fallback
    return const DetectedProjectMetadata(
      language: 'Shell / General',
      runtime: 'POSIX Shell',
      packageManager: 'System',
      techStack: ['General'],
      detectedCommands: {
        'run': 'sh run.sh',
        'test': 'sh test.sh',
      },
      dependencies: [],
      entryPoints: [],
    );
  }

  Future<DetectedProjectMetadata> _detectNodeProject(
      String root, File packageJson) async {
    final techStack = <String>['Node.js'];
    final commands = <String, String>{};
    final dependencies = <String>[];
    String language = 'JavaScript';
    String packageManager = 'npm';

    // Detect package manager lockfile
    if (await File(p.join(root, 'pnpm-lock.yaml')).exists()) {
      packageManager = 'pnpm';
    } else if (await File(p.join(root, 'yarn.lock')).exists()) {
      packageManager = 'yarn';
    } else if (await File(p.join(root, 'bun.lockb')).exists()) {
      packageManager = 'bun';
    }

    try {
      final content = await packageJson.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final scripts = data['scripts'] as Map<String, dynamic>? ?? {};
      if (scripts.containsKey('dev')) {
        commands['run'] = '$packageManager run dev';
      } else if (scripts.containsKey('start')) {
        commands['run'] = '$packageManager start';
      }

      if (scripts.containsKey('build')) {
        commands['build'] = '$packageManager run build';
      }
      if (scripts.containsKey('test')) {
        commands['test'] = '$packageManager test';
      }

      final deps = data['dependencies'] as Map<String, dynamic>? ?? {};
      final devDeps = data['devDependencies'] as Map<String, dynamic>? ?? {};

      dependencies.addAll(deps.keys);
      dependencies.addAll(devDeps.keys);

      if (deps.containsKey('typescript') || devDeps.containsKey('typescript') ||
          await File(p.join(root, 'tsconfig.json')).exists()) {
        language = 'TypeScript';
        techStack.add('TypeScript');
      }

      if (deps.containsKey('react') || devDeps.containsKey('react')) {
        techStack.add('React');
      }
      if (deps.containsKey('next') || devDeps.containsKey('next')) {
        techStack.add('Next.js');
      }
      if (deps.containsKey('vue') || devDeps.containsKey('vue')) {
        techStack.add('Vue');
      }
      if (deps.containsKey('vite') || devDeps.containsKey('vite')) {
        techStack.add('Vite');
      }
      if (deps.containsKey('express') || devDeps.containsKey('express')) {
        techStack.add('Express');
      }
      if (deps.containsKey('tailwindcss') || devDeps.containsKey('tailwindcss')) {
        techStack.add('Tailwind CSS');
      }
    } catch (_) {}

    // Find likely entry points
    final entryPoints = <String>[];
    for (final candidate in [
      'src/index.ts', 'src/index.js',
      'src/main.tsx', 'src/main.ts', 'src/main.jsx', 'src/main.js',
      'src/App.tsx', 'src/App.jsx', 'index.js', 'app.js'
    ]) {
      if (await File(p.join(root, candidate)).exists()) {
        entryPoints.add(candidate);
      }
    }

    return DetectedProjectMetadata(
      language: language,
      runtime: 'Node.js',
      packageManager: packageManager,
      techStack: techStack,
      detectedCommands: commands.isEmpty
          ? {'run': '$packageManager start', 'test': '$packageManager test'}
          : commands,
      dependencies: dependencies,
      entryPoints: entryPoints,
    );
  }

  Future<DetectedProjectMetadata> _detectPythonProject(
      String root, File reqFile, File pyprojectFile) async {
    final techStack = <String>['Python'];
    final commands = <String, String>{};
    final dependencies = <String>[];

    if (await reqFile.exists()) {
      try {
        final lines = await reqFile.readAsLines();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
            final depName = trimmed.split(RegExp(r'[=<>~]')).first.trim();
            if (depName.isNotEmpty) dependencies.add(depName);
          }
        }
      } catch (_) {}
    }

    if (dependencies.any((d) => d.toLowerCase().contains('fastapi'))) {
      techStack.add('FastAPI');
      commands['run'] = 'uvicorn main:app --reload';
    } else if (dependencies.any((d) => d.toLowerCase().contains('flask'))) {
      techStack.add('Flask');
      commands['run'] = 'python app.py';
    } else if (dependencies.any((d) => d.toLowerCase().contains('django'))) {
      techStack.add('Django');
      commands['run'] = 'python manage.py runserver';
    }

    if (commands.isEmpty) {
      commands['run'] = 'python main.py';
    }
    commands['test'] = 'pytest';

    final entryPoints = <String>[];
    for (final candidate in ['main.py', 'app.py', 'manage.py', 'src/main.py']) {
      if (await File(p.join(root, candidate)).exists()) {
        entryPoints.add(candidate);
      }
    }

    return DetectedProjectMetadata(
      language: 'Python',
      runtime: 'Python 3',
      packageManager: 'pip',
      techStack: techStack,
      detectedCommands: commands,
      dependencies: dependencies,
      entryPoints: entryPoints,
    );
  }
}
