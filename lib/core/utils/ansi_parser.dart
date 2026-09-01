import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AnsiParser {
  AnsiParser._();

  static final RegExp _ansiRegex = RegExp(r'\x1B\[([0-9;]*)m');

  static String stripAnsi(String text) {
    return text.replaceAll(_ansiRegex, '');
  }

  static List<TextSpan> parseToSpans(String text, {Color? defaultColor}) {
    final baseColor = defaultColor ?? AppColors.textCode;

    if (!text.contains('\x1B[')) {
      return [
        TextSpan(
          text: text,
          style: TextStyle(color: baseColor),
        )
      ];
    }

    final spans = <TextSpan>[];
    int lastMatchEnd = 0;
    Color currentColor = baseColor;
    FontWeight currentWeight = FontWeight.normal;

    for (final match in _ansiRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(color: currentColor, fontWeight: currentWeight),
        ));
      }

      final code = match.group(1) ?? '';
      final codes = code.split(';').map((s) => int.tryParse(s) ?? 0).toList();

      for (final c in codes) {
        switch (c) {
          case 0:
            currentColor = baseColor;
            currentWeight = FontWeight.normal;
            break;
          case 1:
            currentWeight = FontWeight.bold;
            break;
          case 31: // Red
            currentColor = AppColors.coralRed;
            break;
          case 32: // Green
            currentColor = AppColors.emeraldGreen;
            break;
          case 33: // Yellow
            currentColor = AppColors.amberWarning;
            break;
          case 34: // Blue
            currentColor = AppColors.skyBlue;
            break;
          case 35: // Magenta
            currentColor = AppColors.violetAccent;
            break;
          case 36: // Cyan
            currentColor = AppColors.electricCyan;
            break;
          case 37: // White
            currentColor = Colors.white;
            break;
          case 90: // Bright black (gray)
            currentColor = AppColors.textMuted;
            break;
        }
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(color: currentColor, fontWeight: currentWeight),
      ));
    }

    return spans;
  }
}
