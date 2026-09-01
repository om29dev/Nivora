import 'package:flutter/material.dart';

/// Semantic design tokens for Nivora luxury developer dark/light themes.
class AppColors {
  AppColors._();

  // Dark Palette (Default)
  static const Color darkBackground = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceElevated = Color(0xFF1A2234);
  static const Color darkSurfaceHighlight = Color(0xFF263348);
  static const Color darkBorder = Color(0xFF1F2A3C);
  static const Color darkBorderHover = Color(0xFF334155);

  // Light Palette
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightSurfaceHighlight = Color(0xFFE2E8F0);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderHover = Color(0xFFCBD5E1);

  // Brand & Accent Colors
  static const Color electricCyan = Color(0xFF06B6D4);
  static const Color skyBlue = Color(0xFF0EA5E9);
  static const Color deepTeal = Color(0xFF0D9488);
  static const Color violetAccent = Color(0xFF8B5CF6);

  // Status & Feedback Colors
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color coralRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF38BDF8);

  // Text Colors (Dark Mode)
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textCode = Color(0xFFE2E8F0);

  // Text Colors (Light Mode)
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightTextCode = Color(0xFF1E293B);

  // Dynamic Theme Helpers
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color background(BuildContext context) => isDark(context) ? darkBackground : lightBackground;
  static Color surface(BuildContext context) => isDark(context) ? darkSurface : lightSurface;
  static Color surfaceElevated(BuildContext context) => isDark(context) ? darkSurfaceElevated : lightSurfaceElevated;
  static Color surfaceHighlight(BuildContext context) => isDark(context) ? darkSurfaceHighlight : lightSurfaceHighlight;
  static Color border(BuildContext context) => isDark(context) ? darkBorder : lightBorder;
  static Color text(BuildContext context) => isDark(context) ? textPrimary : lightTextPrimary;
  static Color textSecondaryOf(BuildContext context) => isDark(context) ? textSecondary : lightTextSecondary;
  static Color textMutedOf(BuildContext context) => isDark(context) ? textMuted : lightTextMuted;

  // Code Syntax Colors
  static const Color syntaxKeyword = Color(0xFFF472B6);
  static const Color syntaxString = Color(0xFF34D399);
  static const Color syntaxNumber = Color(0xFFFBBF24);
  static const Color syntaxComment = Color(0xFF64748B);
  static const Color syntaxFunction = Color(0xFF60A5FA);
  static const Color syntaxVariable = Color(0xFFA78BFA);
  static const Color syntaxDiffAdd = Color(0xFF065F46);
  static const Color syntaxDiffAddText = Color(0xFF34D399);
  static const Color syntaxDiffRemove = Color(0xFF7F1D1D);
  static const Color syntaxDiffRemoveText = Color(0xFFF87171);

  // Terminal Colors
  static const Color terminalBackground = Color(0xFF070B12);
  static const Color terminalCursor = Color(0xFF06B6D4);
  static const Color terminalSelection = Color(0x3306B6D4);
}
