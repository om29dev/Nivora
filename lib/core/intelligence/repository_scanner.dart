import 'dart:io';
import 'package:path/path.dart' as p;

class ScannedFileItem {
  final String relativePath;
  final String absolutePath;
  final int sizeInBytes;
  final String extension;
  final bool isDirectory;

  const ScannedFileItem({
    required this.relativePath,
    required this.absolutePath,
    required this.sizeInBytes,
    required this.extension,
    required this.isDirectory,
  });
}

class RepositoryScanner {
  static const Set<String> ignoredDirectories = {
    'node_modules',
    '.git',
    'dist',
    'build',
    '.next',
    '.nuxt',
    '__pycache__',
    '.pytest_cache',
    'venv',
    '.venv',
    'env',
    'target',
    'bin',
    'obj',
    '.idea',
    '.vscode',
    '.dart_tool',
  };

  static const Set<String> binaryExtensions = {
    '.png', '.jpg', '.jpeg', '.gif', '.svg', '.ico', '.webp',
    '.mp4', '.mov', '.avi', '.mp3', '.wav',
    '.zip', '.tar', '.gz', '.7z', '.rar',
    '.pdf', '.exe', '.dll', '.so', '.dylib',
    '.apk', '.aab', '.ipa',
    '.class', '.pyc', '.o',
  };

  Future<List<ScannedFileItem>> scanRepository(String rootPath) async {
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) return [];

    final results = <ScannedFileItem>[];

    await for (final entity in rootDir.list(recursive: true, followLinks: false)) {
      final relative = p.relative(entity.path, from: rootPath);
      final parts = p.split(relative);

      // Check if any ancestor folder is in ignoredDirectories
      if (parts.any((part) => ignoredDirectories.contains(part))) {
        continue;
      }

      final isDir = entity is Directory;
      final ext = p.extension(entity.path).toLowerCase();

      // Skip heavy binaries from indexing
      if (!isDir && binaryExtensions.contains(ext)) {
        continue;
      }

      int size = 0;
      if (!isDir) {
        try {
          final stat = await entity.stat();
          size = stat.size;
        } catch (_) {}
      }

      results.add(ScannedFileItem(
        relativePath: relative.replaceAll('\\', '/'),
        absolutePath: entity.path,
        sizeInBytes: size,
        extension: ext,
        isDirectory: isDir,
      ));
    }

    return results;
  }
}
