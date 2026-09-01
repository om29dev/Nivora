import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../models/terminal_types.dart';
import '../utils/ansi_parser.dart';

class NivoraTerminalLineWidget extends StatelessWidget {
  final TerminalLine line;

  const NivoraTerminalLineWidget({
    super.key,
    required this.line,
  });

  @override
  Widget build(BuildContext context) {
    if (line.isInput) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '> ',
              style: AppTypography.terminal.copyWith(
                color: AppColors.electricCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                line.text,
                style: AppTypography.terminal.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (line.isError) {
      final errorSpans = AnsiParser.parseToSpans(line.text, defaultColor: AppColors.coralRed);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.5),
        child: RichText(
          text: TextSpan(
            style: AppTypography.terminal.copyWith(color: AppColors.coralRed),
            children: errorSpans,
          ),
        ),
      );
    }

    final spans = AnsiParser.parseToSpans(line.text);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: RichText(
        text: TextSpan(
          style: AppTypography.terminal,
          children: spans,
        ),
      ),
    );
  }
}
