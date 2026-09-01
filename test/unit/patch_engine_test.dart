import 'package:flutter_test/flutter_test.dart';
import 'package:nivora/core/ai/patch_engine.dart';
import 'package:nivora/core/models/ai_types.dart';

void main() {
  group('PatchEngine Diff Tests', () {
    test('Generates additions and deletions correctly', () {
      final engine = PatchEngine();
      const orig = 'function hello() {\n  return "world";\n}';
      const modified = 'function hello() {\n  return "nivora";\n}';

      final diff = engine.generateDiff(
        filePath: 'src/hello.ts',
        originalContent: orig,
        newContent: modified,
      );

      expect(diff.filePath, equals('src/hello.ts'));
      expect(diff.hunks.isNotEmpty, isTrue);

      final lines = diff.hunks.first.lines;
      expect(lines.any((l) => l.type == DiffLineType.deletion && l.content.contains('world')), isTrue);
      expect(lines.any((l) => l.type == DiffLineType.addition && l.content.contains('nivora')), isTrue);
    });
  });
}
