import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Circular action button for the Nivora AI Agent.
/// Perfectly proportioned to fit completely inside the bottom navigation bar.
class NivoraFloatingAIButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const NivoraFloatingAIButton({
    super.key,
    required this.onTap,
    this.size = 42.0,
  });

  @override
  State<NivoraFloatingAIButton> createState() => _NivoraFloatingAIButtonState();
}

class _NivoraFloatingAIButtonState extends State<NivoraFloatingAIButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Semantics(
      button: true,
      label: 'Open AI Agent',
      hint: 'Activates repository-aware AI development assistant',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.electricCyan,
                  Color(0xFF00B4D8),
                  AppColors.violetAccent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricCyan.withAlpha(isDark ? 80 : 50),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
