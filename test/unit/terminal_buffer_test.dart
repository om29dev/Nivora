import 'package:flutter_test/flutter_test.dart';
import 'package:nivora/core/models/terminal_types.dart';
import 'package:nivora/core/services/process_manager.dart';
import 'package:nivora/core/utils/ansi_parser.dart';

void main() {
  group('Terminal & ANSI Parser Tests', () {
    test('AnsiParser parses colored text into styled TextSpans', () {
      const ansiText = '\x1B[32mSuccess\x1B[0m: Done';
      final spans = AnsiParser.parseToSpans(ansiText);

      expect(spans.isNotEmpty, isTrue);
      expect(spans.any((s) => s.text == 'Success'), isTrue);
    });

    test('ProcessManager bounds buffer size', () {
      final manager = ProcessManager();

      for (int i = 0; i < 2100; i++) {
        manager.appendLine(TerminalLine(text: 'Line $i'));
      }

      expect(manager.currentBuffer.length, equals(ProcessManager.maxBufferLines));
      expect(manager.currentBuffer.first.text, equals('Line 100'));
      expect(manager.currentBuffer.last.text, equals('Line 2099'));
    });
  });
}
