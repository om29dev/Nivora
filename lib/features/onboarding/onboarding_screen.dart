import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/nivora_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.terminal_rounded,
      'title': 'Your development environment.',
      'subtitle':
          'Git, Python, Node.js, an interactive shell, and professional developer tools right on your Android phone.',
      'tag': 'LOCAL RUNTIME',
    },
    {
      'icon': Icons.psychology_rounded,
      'title': 'AI that understands your repository.',
      'subtitle':
          'Nivora indexes symbols and docs to retrieve surgical context—never blindly sending entire codebases to AI.',
      'tag': 'SURGICAL CONTEXT',
    },
    {
      'icon': Icons.security_rounded,
      'title': 'Your code stays local.',
      'subtitle':
          'Offline-first and on-device AI ensure your private code, secrets, and repository history never leave your device.',
      'tag': 'PRIVATE & SECURE',
    },
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/ai-setup');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Toggle Theme',
                    icon: Icon(
                      ref.watch(themeModeProvider) == ThemeMode.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: AppColors.electricCyan,
                    ),
                    onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                  ),
                  TextButton(
                    onPressed: () => context.go('/ai-setup'),
                    child: Text(
                      'Skip',
                      style: AppTypography.button.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: _pages.length,
                  itemBuilder: (ctx, idx) {
                    final item = _pages[idx];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color ?? AppColors.surfaceElevated(context),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Theme.of(context).dividerTheme.color ?? AppColors.border(context),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.electricCyan.withAlpha(20),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 42,
                            color: AppColors.electricCyan,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.electricCyan.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['tag'] as String,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.electricCyan,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          item['title'] as String,
                          style: AppTypography.brandTitleOf(context).copyWith(fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item['subtitle'] as String,
                          style: AppTypography.bodySecondaryOf(context).copyWith(fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (idx) {
                  final isSelected = idx == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.electricCyan
                          : (Theme.of(context).dividerTheme.color ?? AppColors.border(context)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              NivoraButton(
                text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                width: double.infinity,
                onPressed: _onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
