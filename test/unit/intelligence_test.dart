import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivora/core/intelligence/context_retriever.dart';
import 'package:nivora/core/intelligence/markdown_analyzer.dart';
import 'package:nivora/core/intelligence/project_detector.dart';
import 'package:nivora/core/intelligence/repository_scanner.dart';
import 'package:nivora/core/intelligence/symbol_indexer.dart';
import 'package:nivora/core/models/repository_summary.dart';

void main() {
  group('Repository Intelligence Engine Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nivora_test_');
      // Create sample Node.js project files
      final pkgJson = File('${tempDir.path}/package.json');
      await pkgJson.writeAsString('''{
        "name": "weather-app",
        "scripts": {
          "dev": "vite",
          "build": "vite build",
          "test": "vitest"
        },
        "dependencies": {
          "react": "^18.2.0"
        }
      }''');

      final readme = File('${tempDir.path}/README.md');
      await readme.writeAsString('''# Weather App
A lightweight real-time weather dashboard.

## Development
Run `npm run dev` to start.
''');

      final srcDir = Directory('${tempDir.path}/src');
      await srcDir.create(recursive: true);

      final componentFile = File('${srcDir.path}/Dashboard.tsx');
      await componentFile.writeAsString('''import React from 'react';

export function Dashboard() {
  return <div>Weather</div>;
}

export const fetchWeather = async () => {
  return {};
};
''');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('ProjectDetector identifies Node.js and vite commands', () async {
      final detector = ProjectDetector();
      final meta = await detector.detect(tempDir.path);

      expect(meta.language, equals('JavaScript'));
      expect(meta.runtime, equals('Node.js'));
      expect(meta.packageManager, equals('npm'));
      expect(meta.detectedCommands['run'], equals('npm run dev'));
    });

    test('MarkdownAnalyzer extracts purpose and commands', () async {
      final analyzer = MarkdownAnalyzer();
      final result = await analyzer.analyze(tempDir.path);

      expect(result.foundReadme, isTrue);
      expect(result.purpose, contains('real-time weather dashboard'));
      expect(result.extractedCommands, contains('npm run dev'));
    });

    test('RepositoryScanner and SymbolIndexer discover components and functions', () async {
      final scanner = RepositoryScanner();
      final files = await scanner.scanRepository(tempDir.path);

      expect(files.any((f) => f.relativePath.contains('Dashboard.tsx')), isTrue);

      final indexer = SymbolIndexer();
      final symbols = await indexer.indexFiles(files);

      expect(symbols.any((s) => s.name == 'Dashboard'), isTrue);
      expect(symbols.any((s) => s.name == 'fetchWeather'), isTrue);
    });

    test('ContextRetriever stays strictly within token budget', () async {
      final scanner = RepositoryScanner();
      final files = await scanner.scanRepository(tempDir.path);

      final indexer = SymbolIndexer();
      final symbols = await indexer.indexFiles(files);

      const summary = RepositorySummary(
        projectName: 'weather-app',
        purpose: 'Weather dashboard',
        techStack: ['React', 'Node.js'],
        runtime: 'Node.js',
        packageManager: 'npm',
        entryPoints: ['src/Dashboard.tsx'],
        importantDirectories: ['src'],
        detectedCommands: {'run': 'npm run dev'},
        dependencies: ['react'],
      );

      final retriever = ContextRetriever();
      final context = await retriever.retrieveContext(
        projectRoot: tempDir.path,
        userPrompt: 'Add dark mode to the Dashboard',
        summary: summary,
        scannedFiles: files,
        symbolIndex: symbols,
      );

      expect(context.files.any((f) => f.relativePath.contains('Dashboard.tsx')), isTrue);
      expect(context.totalEstimatedTokens, lessThanOrEqualTo(ContextRetriever.maxBudgetTokens));
    });
  });
}
