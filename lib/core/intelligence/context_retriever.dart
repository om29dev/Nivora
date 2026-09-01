import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/repository_summary.dart';
import '../models/symbol_definition.dart';
import 'repository_scanner.dart';

class RetrievedContextItem {
  final String relativePath;
  final String content;
  final int tokenEstimate;
  final String relevanceReason;

  const RetrievedContextItem({
    required this.relativePath,
    required this.content,
    required this.tokenEstimate,
    required this.relevanceReason,
  });
}

class ProjectContext {
  final RepositorySummary summary;
  final List<RetrievedContextItem> files;
  final List<SymbolDefinition> matchedSymbols;
  final int totalEstimatedTokens;

  const ProjectContext({
    required this.summary,
    required this.files,
    required this.matchedSymbols,
    required this.totalEstimatedTokens,
  });
}

class ContextRetriever {
  static const int maxBudgetTokens = 3800;

  Future<ProjectContext> retrieveContext({
    required String projectRoot,
    required String userPrompt,
    required RepositorySummary summary,
    required List<ScannedFileItem> scannedFiles,
    required List<SymbolDefinition> symbolIndex,
  }) async {
    final promptWords = userPrompt
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toSet();

    // 1. Symbol matching
    final matchedSymbols = <SymbolDefinition>[];
    for (final sym in symbolIndex) {
      final nameLower = sym.name.toLowerCase();
      if (promptWords.any((w) => nameLower.contains(w) || w.contains(nameLower))) {
        matchedSymbols.add(sym);
      }
    }

    // 2. File matching & scoring
    final fileScores = <ScannedFileItem, int>{};
    for (final file in scannedFiles) {
      if (file.isDirectory) continue;
      int score = 0;
      final pathLower = file.relativePath.toLowerCase();

      // Keyword match in filename or path
      for (final word in promptWords) {
        if (pathLower.contains(word)) score += 10;
      }

      // Bonus if any matched symbol lives in this file
      for (final sym in matchedSymbols) {
        if (sym.relativeFilePath == file.relativePath) score += 15;
      }

      // Bonus for entry points or config
      if (summary.entryPoints.contains(file.relativePath)) score += 5;

      if (score > 0) {
        fileScores[file] = score;
      }
    }

    // Sort files by relevance
    final sortedFiles = fileScores.keys.toList()
      ..sort((a, b) => fileScores[b]!.compareTo(fileScores[a]!));

    final retrievedItems = <RetrievedContextItem>[];
    int currentTokenTotal = _estimateTokens(summary.purpose) + 150; // summary baseline

    for (final file in sortedFiles) {
      if (retrievedItems.length >= 4) break; // Max 4 top files

      try {
        final f = File(p.join(projectRoot, file.relativePath));
        final content = await f.readAsString();
        final tokens = _estimateTokens(content);

        if (currentTokenTotal + tokens > maxBudgetTokens) {
          // If file is too large, take first 100 lines
          final truncatedLines = content.split('\n').take(100).join('\n');
          final truncTokens = _estimateTokens(truncatedLines);
          if (currentTokenTotal + truncTokens <= maxBudgetTokens) {
            retrievedItems.add(RetrievedContextItem(
              relativePath: file.relativePath,
              content: '$truncatedLines\n... [remaining lines omitted for context budget]',
              tokenEstimate: truncTokens,
              relevanceReason: 'Matched prompt keywords / symbols (truncated)',
            ));
            currentTokenTotal += truncTokens;
          }
          break;
        } else {
          retrievedItems.add(RetrievedContextItem(
            relativePath: file.relativePath,
            content: content,
            tokenEstimate: tokens,
            relevanceReason: 'Matched prompt keywords & symbols',
          ));
          currentTokenTotal += tokens;
        }
      } catch (_) {}
    }

    return ProjectContext(
      summary: summary,
      files: retrievedItems,
      matchedSymbols: matchedSymbols.take(10).toList(),
      totalEstimatedTokens: currentTokenTotal,
    );
  }

  static int _estimateTokens(String text) {
    // Standard heuristic: ~4 characters per token
    return (text.length / 4).ceil();
  }
}
