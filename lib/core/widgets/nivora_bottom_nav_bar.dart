import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'nivora_floating_ai_button.dart';

/// Sticked edge-to-edge developer workstation bottom navigation bar for Nivora.
/// Renders a docked bar with 4 destinations and the center AI Agent action button
/// fitted completely inside, fully respecting Android system navigation insets.
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

  static const double barContentHeight = 60.0;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: AppColors.border(context),
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Tab 0: Dashboard
              _NavItem(
                label: 'Dashboard',
                icon: Icons.dashboard_rounded,
                isSelected: currentIndex == 0,
                onTap: () => onItemSelected(0),
              ),

              // Left Tab 1: Projects
              _NavItem(
                label: 'Projects',
                icon: Icons.folder_copy_rounded,
                isSelected: currentIndex == 1,
                onTap: () => onItemSelected(1),
              ),

              // Center AI Button - completely fitted inside the bottom nav bar
              NivoraFloatingAIButton(
                size: 42.0,
                onTap: onAITapped,
              ),

              // Right Tab 2: Terminal
              _NavItem(
                label: 'Terminal',
                icon: Icons.terminal_rounded,
                isSelected: currentIndex == 2,
                onTap: () => onItemSelected(2),
              ),

              // Right Tab 3: More
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
            constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
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
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.captionOf(context).copyWith(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeColor : inactiveColor,
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
