import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../ai/ai_provider.dart';
import '../ai/local_ai_provider.dart';
import '../ai/patch_engine.dart';
import '../intelligence/context_retriever.dart';
import '../intelligence/markdown_analyzer.dart';
import '../intelligence/project_detector.dart';
import '../intelligence/repository_scanner.dart';
import '../intelligence/symbol_indexer.dart';
import '../models/git_types.dart';
import '../models/project.dart';
import '../models/repository_summary.dart';
import '../models/runtime_types.dart';
import '../models/symbol_definition.dart';
import '../services/git_service.dart';
import '../services/office_kit_service.dart';
import '../services/process_manager.dart';
import 'package:flutter/material.dart';
import '../services/mock_demo_seeder.dart';
import '../services/runtime_manager.dart';
import '../services/storage_service.dart';
import '../services/termux_environment_service.dart';

// --- Theme Mode State ---
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark);

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

// --- Singleton Service Providers ---
final termuxEnvironmentServiceProvider = Provider<TermuxEnvironmentService>((ref) {
  final service = TermuxEnvironmentService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

final termuxStatusStreamProvider = StreamProvider<TermuxEnvironmentStatus>((ref) {
  final service = ref.watch(termuxEnvironmentServiceProvider);
  return service.statusStream;
});

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final mockDemoSeederProvider = Provider<MockDemoSeeder>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return MockDemoSeeder(storage);
});
final gitServiceProvider = Provider<GitService>((ref) => GitService());
final runtimeManagerProvider = Provider<RuntimeManager>((ref) {
  final termux = ref.watch(termuxEnvironmentServiceProvider);
  return RuntimeManager(termuxService: termux);
});
final processManagerProvider = ChangeNotifierProvider<ProcessManager>((ref) {
  final termux = ref.watch(termuxEnvironmentServiceProvider);
  return ProcessManager(termuxService: termux);
});
final officeKitServiceProvider = Provider<OfficeKitService>((ref) => OfficeKitService());

final repositoryScannerProvider = Provider<RepositoryScanner>((ref) => RepositoryScanner());
final projectDetectorProvider = Provider<ProjectDetector>((ref) => ProjectDetector());
final markdownAnalyzerProvider = Provider<MarkdownAnalyzer>((ref) => MarkdownAnalyzer());
final symbolIndexerProvider = Provider<SymbolIndexer>((ref) => SymbolIndexer());
final contextRetrieverProvider = Provider<ContextRetriever>((ref) => ContextRetriever());
final patchEngineProvider = Provider<PatchEngine>((ref) => PatchEngine());

// --- Active AI Provider ---
final selectedAIProvider = StateProvider<AIProvider>((ref) => LocalAIProvider());

// --- Onboarding State ---
final onboardingCompletedProvider = StateNotifierProvider<OnboardingNotifier, AsyncValue<bool>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return OnboardingNotifier(storage);
});

class OnboardingNotifier extends StateNotifier<AsyncValue<bool>> {
  final StorageService _storage;
  OnboardingNotifier(this._storage) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final val = await _storage.isOnboardingCompleted();
      state = AsyncValue.data(val);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeOnboarding() async {
    await _storage.setOnboardingCompleted(true);
    state = const AsyncValue.data(true);
  }
}

// --- Recent Projects State ---
final projectsListProvider = StateNotifierProvider<ProjectsNotifier, List<Project>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ProjectsNotifier(storage);
});

class ProjectsNotifier extends StateNotifier<List<Project>> {
  final StorageService _storage;
  ProjectsNotifier(this._storage) : super([]) {
    loadProjects();
  }

  Future<void> loadProjects({bool seedIfEmpty = true}) async {
    var list = await _storage.getRecentProjects();
    if (list.isEmpty && seedIfEmpty) {
      final seeder = MockDemoSeeder(_storage);
      list = await seeder.seedDemoProjects();
    }
    state = list;
  }

  Future<void> seedDemoProjects() async {
    final seeder = MockDemoSeeder(_storage);
    final list = await seeder.seedDemoProjects();
    state = list;
  }

  Future<void> addOrUpdateProject(Project project) async {
    await _storage.saveProject(project);
    await loadProjects(seedIfEmpty: false);
  }

  Future<void> deleteProject(String id) async {
    await _storage.deleteProject(id);
    await loadProjects(seedIfEmpty: false);
  }
}

// --- Active Project State ---
final activeProjectProvider = StateProvider<Project?>((ref) => null);

// --- Active Project Intelligence State ---
class ProjectIntelligenceState {
  final RepositorySummary? summary;
  final List<ScannedFileItem> scannedFiles;
  final List<SymbolDefinition> symbols;
  final bool isIndexing;

  const ProjectIntelligenceState({
    this.summary,
    this.scannedFiles = const [],
    this.symbols = const [],
    this.isIndexing = false,
  });
}

final projectIntelligenceProvider = StateNotifierProvider<ProjectIntelligenceNotifier, ProjectIntelligenceState>((ref) {
  final scanner = ref.watch(repositoryScannerProvider);
  final detector = ref.watch(projectDetectorProvider);
  final mdAnalyzer = ref.watch(markdownAnalyzerProvider);
  final symbolIndexer = ref.watch(symbolIndexerProvider);

  return ProjectIntelligenceNotifier(
    scanner: scanner,
    detector: detector,
    mdAnalyzer: mdAnalyzer,
    symbolIndexer: symbolIndexer,
  );
});

class ProjectIntelligenceNotifier extends StateNotifier<ProjectIntelligenceState> {
  final RepositoryScanner scanner;
  final ProjectDetector detector;
  final MarkdownAnalyzer mdAnalyzer;
  final SymbolIndexer symbolIndexer;

  ProjectIntelligenceNotifier({
    required this.scanner,
    required this.detector,
    required this.mdAnalyzer,
    required this.symbolIndexer,
  }) : super(const ProjectIntelligenceState());

  Future<void> indexProject(String projectRoot) async {
    state = const ProjectIntelligenceState(isIndexing: true);

    try {
      final projectName = p.basename(projectRoot);
      final files = await scanner.scanRepository(projectRoot);
      final meta = await detector.detect(projectRoot);
      final mdResult = await mdAnalyzer.analyze(projectRoot);
      final symbols = await symbolIndexer.indexFiles(files);

      final summary = RepositorySummary(
        projectName: projectName,
        purpose: mdResult.purpose,
        techStack: meta.techStack,
        runtime: meta.runtime,
        packageManager: meta.packageManager,
        entryPoints: meta.entryPoints,
        importantDirectories: files
            .where((f) => f.isDirectory)
            .map((f) => f.relativePath)
            .take(6)
            .toList(),
        detectedCommands: meta.detectedCommands,
        dependencies: meta.dependencies.take(15).toList(),
        hasReadme: mdResult.foundReadme,
        hasTests: meta.detectedCommands.containsKey('test'),
        hasGit: await Directory(p.join(projectRoot, '.git')).exists(),
        totalFilesIndexed: files.length,
        totalSymbolsIndexed: symbols.length,
      );

      state = ProjectIntelligenceState(
        summary: summary,
        scannedFiles: files,
        symbols: symbols,
        isIndexing: false,
      );
    } catch (_) {
      state = const ProjectIntelligenceState(isIndexing: false);
    }
  }
}

// --- Active File & Editor State ---
class EditorState {
  final String? filePath;
  final String content;
  final bool isModified;

  const EditorState({
    this.filePath,
    this.content = '',
    this.isModified = false,
  });

  EditorState copyWith({String? filePath, String? content, bool? isModified}) {
    return EditorState(
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      isModified: isModified ?? this.isModified,
    );
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(const EditorState());

  Future<void> openFile(String root, String relativePath) async {
    try {
      final file = File(p.join(root, relativePath));
      if (await file.exists()) {
        final content = await file.readAsString();
        state = EditorState(filePath: relativePath, content: content, isModified: false);
      }
    } catch (_) {}
  }

  void updateContent(String newContent) {
    state = state.copyWith(content: newContent, isModified: true);
  }

  Future<void> saveFile(String root) async {
    if (state.filePath == null) return;
    try {
      final file = File(p.join(root, state.filePath!));
      await file.writeAsString(state.content);
      state = state.copyWith(isModified: false);
    } catch (_) {}
  }
}

// --- Git State Provider ---
final gitStatusProvider = FutureProvider.autoDispose<GitRepoStatus>((ref) async {
  final project = ref.watch(activeProjectProvider);
  if (project == null) return GitRepoStatus.clean('main');
  final git = ref.watch(gitServiceProvider);
  return await git.getStatus(project.path);
});

// --- Runtime Health Provider ---
final runtimeHealthProvider = FutureProvider<EnvironmentHealth>((ref) async {
  final mgr = ref.watch(runtimeManagerProvider);
  return await mgr.inspectEnvironment();
});
