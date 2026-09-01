import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class NivoraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? glowColor;
  final double borderRadius;

  const NivoraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.glowColor,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final defaultBg = backgroundColor ??
        (isDark ? const Color(0xFF101726) : Colors.white);

    final defaultBorder = borderColor ??
        (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));

    final effectiveGlow = glowColor ?? (isDark ? const Color(0xFF06B6D4) : null);

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: defaultBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: defaultBorder,
          width: 1.0,
        ),
        boxShadow: [
          if (effectiveGlow != null && isDark)
            BoxShadow(
              color: effectiveGlow.withAlpha(12),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.electricCyan.withAlpha(25),
          highlightColor: Colors.transparent,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
