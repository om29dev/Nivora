import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'nivora_floating_ai_button.dart';

/// Sticked edge-to-edge developer workstation bottom navigation bar for Nivora.
/// Renders 5 items: Dashboard, Terminal, AI (center), Intel, and More.
class NivoraBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onAITapped;

  const NivoraBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.onAITapped,
  });

  static const double barContentHeight = 62.0;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0C1220) : Colors.white).withAlpha(210),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withAlpha(16),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: SizedBox(
              height: barContentHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Tab 0: Dashboard
                  _NavItem(
                    label: 'Dashboard',
                    icon: Icons.dashboard_rounded,
                    isSelected: currentIndex == 0,
                    onTap: () => onItemSelected(0),
                  ),

                  // Tab 1: Terminal
                  _NavItem(
                    label: 'Terminal',
                    icon: Icons.terminal_rounded,
                    isSelected: currentIndex == 1,
                    onTap: () => onItemSelected(1),
                  ),

                  // Center Tab: AI Agent
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: NivoraFloatingAIButton(
                      size: 42.0,
                      onTap: onAITapped,
                    ),
                  ),

                  // Tab 2: Semantic Intel
                  _NavItem(
                    label: 'Intel',
                    icon: Icons.hub_rounded,
                    isSelected: currentIndex == 2,
                    onTap: () => onItemSelected(2),
                  ),

                  // Tab 3: More
                  _NavItem(
                    label: 'More',
                    icon: Icons.more_horiz_rounded,
                    isSelected: currentIndex == 3,
                    onTap: () => onItemSelected(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.electricCyan;
    final inactiveColor = AppColors.textSecondaryOf(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.electricCyan.withAlpha(25),
          highlightColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(minWidth: 54, minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withAlpha(28)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.captionOf(context).copyWith(
                    color: isSelected ? activeColor : inactiveColor,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
