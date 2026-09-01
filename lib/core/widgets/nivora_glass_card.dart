import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Luxury Frosted Glass Card for Nivora.
///
/// Features:
/// - Native `BackdropFilter` blur (16px) with translucent glass gradient.
/// - Luminescent hairline border with subtle accent glow highlights.
/// - Touch feedback ripple with rounded corners.
class NivoraGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? glowColor;
  final Color? borderColor;
  final Color? backgroundColor;
  final double blur;
  final double borderWidth;

  const NivoraGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.borderRadius = 18,
    this.glowColor,
    this.borderColor,
    this.backgroundColor,
    this.blur = 16.0,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final defaultBg = backgroundColor ??
        (isDark
            ? const Color(0xFF131B2E).withAlpha(140)
            : Colors.white.withAlpha(190));

    final effectiveBorderColor = borderColor ??
        (isDark
            ? Colors.white.withAlpha(28)
            : Colors.black.withAlpha(18));

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withAlpha(isDark ? 30 : 18),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: defaultBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: effectiveBorderColor,
                width: borderWidth,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withAlpha(20),
                        Colors.white.withAlpha(4),
                      ]
                    : [
                        Colors.white.withAlpha(220),
                        Colors.white.withAlpha(140),
                      ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.electricCyan.withAlpha(30),
          highlightColor: Colors.transparent,
          child: content,
        ),
      );
    }

    return content;
  }
}
