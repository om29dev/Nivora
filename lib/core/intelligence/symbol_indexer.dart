import 'dart:io';
import '../models/symbol_definition.dart';
import 'repository_scanner.dart';

class SymbolIndexer {
  // Regex matchers for JS/TS, Python, Dart
  static final RegExp _jsFunctionRegex = RegExp(
    r'(?:function\s+([a-zA-Z0-9_$]+)|(?:const|let|var)\s+([a-zA-Z0-9_$]+)\s*=\s*(?:async\s*)?(?:\([^)]*\)|[a-zA-Z0-9_$]+)\s*=>)',
  );

  static final RegExp _jsClassRegex = RegExp(
    r'class\s+([a-zA-Z0-9_$]+)',
  );

  static final RegExp _jsExportRegex = RegExp(
    r'export\s+(?:default\s+)?(?:class|function|const|let|var|type|interface)\s+([a-zA-Z0-9_$]+)',
  );

  static final RegExp _jsRouteRegex = RegExp(
    r'(?:app|router)\.(get|post|put|delete|patch)\(\s*[\x27\x22]([^\x27\x22]+)[\x27\x22]',
  );

  static final RegExp _pyFuncRegex = RegExp(
    r'def\s+([a-zA-Z0-9_]+)\s*\(',
  );

  static final RegExp _pyClassRegex = RegExp(
    r'class\s+([a-zA-Z0-9_]+)',
  );

  static final RegExp _pyRouteRegex = RegExp(
    r'@(?:app|router)\.(get|post|put|delete|patch)\(\s*[\x27\x22]([^\x27\x22]+)[\x27\x22]',
  );

  Future<List<SymbolDefinition>> indexFiles(List<ScannedFileItem> files) async {
    final symbols = <SymbolDefinition>[];

    for (final file in files) {
      if (file.isDirectory) continue;
      final ext = file.extension;

      // Only parse code text extensions
      if (!['.js', '.jsx', '.ts', '.tsx', '.py', '.dart', '.go', '.rs'].contains(ext)) {
        continue;
      }

      try {
        final f = File(file.absolutePath);
        final lines = await f.readAsLines();

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          final lineNum = i + 1;

          // JS/TS Indexing
          if (['.js', '.jsx', '.ts', '.tsx'].contains(ext)) {
            final classMatch = _jsClassRegex.firstMatch(line);
            if (classMatch != null) {
              symbols.add(SymbolDefinition(
                name: classMatch.group(1)!,
                kind: SymbolKind.clazz,
                relativeFilePath: file.relativePath,
                lineNumber: lineNum,
                signature: line.trim(),
              ));
            }

            final funcMatch = _jsFunctionRegex.firstMatch(line);
            if (funcMatch != null) {
              final name = funcMatch.group(1) ?? funcMatch.group(2)!;
              // Detect React Component
              final isComponent = name.isNotEmpty && name[0] == name[0].toUpperCase();
              symbols.add(SymbolDefinition(
                name: name,
                kind: isComponent ? SymbolKind.component : SymbolKind.function,
                relativeFilePath: file.relativePath,
                lineNumber: lineNum,
                signature: line.trim(),
              ));
            }

            final routeMatch = _jsRouteRegex.firstMatch(line);
            if (routeMatch != null) {
              symbols.add(SymbolDefinition(
                name: '${routeMatch.group(1)!.toUpperCase()} ${routeMatch.group(2)}',
                kind: SymbolKind.route,
                relativeFilePath: file.relativePath,
                lineNumber: lineNum,
                signature: line.trim(),
              ));
            }

            final exportMatch = _jsExportRegex.firstMatch(line);
            if (exportMatch != null) {
              symbols.add(SymbolDefinition(
                name: exportMatch.group(1)!,
                kind: SymbolKind.importExport,
                relativeFilePath: file.relativePath,
                lineNumber: lineNum,
                signature: line.trim(),
              ));
            }
          }

          // Python Indexing
          if (ext == '.py') {
            final classMatch = _pyClassRegex.firstMatch(line);
            if (classMatch != null) {
              symbols.add(SymbolDefinition(
                name: classMatch.group(1)!,
                kind: SymbolKind.clazz,
                relativeFilePath: file.relativePath,
                lineNumber: lineNum,
                signature: line.trim(),
              ));
            }

            final funcMatch = _pyFuncRegex.firstMatch(line);
            if (funcMatch != null) {
              symbols.add(SymbolDefinition(
                name: funcMatch.group(1)!,
                kind: SymbolKind.function,
                relativeFilePath: file.relativePath,
                lineNumber: lineNum,
                signature: line.trim(),
              ));
            }

            final routeMatch = _pyRouteRegex.firstMatch(line);
            if (routeMatch != null) {
              symbols.add(SymbolDefinition(
                name: '${routeMatch.group(1)!.toUpperCase()} ${routeMatch.group(2)}',
                kind: SymbolKind.route,
                relativeFilePath: file.relativePath,
                lineNumber: lineNum,
                signature: line.trim(),
              ));
            }
          }
        }
      } catch (_) {
        // Ignore parsing individual unreadable files
      }
    }

    return symbols;
  }
}
