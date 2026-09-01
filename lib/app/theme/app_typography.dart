import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get brandTitle => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get bodySecondary => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.2,
      );

  static TextStyle get code => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get terminal => GoogleFonts.jetBrainsMono(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textCode,
        height: 1.35,
      );

  // Context-aware explicit text styles
  static TextStyle brandTitleOf(BuildContext context) => brandTitle.copyWith(color: AppColors.text(context));
  static TextStyle h1Of(BuildContext context) => h1.copyWith(color: AppColors.text(context));
  static TextStyle h2Of(BuildContext context) => h2.copyWith(color: AppColors.text(context));
  static TextStyle h3Of(BuildContext context) => h3.copyWith(color: AppColors.text(context));
  static TextStyle bodyOf(BuildContext context) => body.copyWith(color: AppColors.text(context));
  static TextStyle bodySecondaryOf(BuildContext context) => bodySecondary.copyWith(color: AppColors.textSecondaryOf(context));
  static TextStyle captionOf(BuildContext context) => caption.copyWith(color: AppColors.textMutedOf(context));
}
