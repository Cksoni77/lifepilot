import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../shared_controllers/app_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({this.onCompleted, super.key});

  final VoidCallback? onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      title: 'Plan your whole life in one place',
      description:
          'Tasks, calendar, habits and goals - unified in a single, calm view.',
      icon: Icons.track_changes,
      accent: AppColors.primaryTint,
    ),
    _OnboardingPage(
      title: 'Build habits that actually stick',
      description:
          'Track streaks, get gentle nudges, and see your consistency grow.',
      icon: Icons.local_fire_department_outlined,
      accent: AppColors.accentOrangeTint,
    ),
    _OnboardingPage(
      title: 'Meet your AI co-pilot',
      description:
          'Ask it to plan your day, reshuffle tasks, or turn a thought into a habit.',
      icon: Icons.auto_awesome,
      accent: AppColors.accentPurpleTint,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Called when the user finishes or skips onboarding.
  Future<void> _complete() async {
    final controller = AppController.of(context);

    // Save onboardingCompleted = true
    await controller.completeOnboarding();

    if (!mounted) return;

    // Keep compatibility with the existing callback.
    widget.onCompleted?.call();
  }

  /// Handles Continue / Get started button.
  Future<void> _continue() async {
    // If this is the last page, complete onboarding.
    if (_currentPage == _pages.length - 1) {
      await _complete();
      return;
    }

    // Otherwise move to the next page.
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'LifePilot  /  ${_currentPage + 1} of ${_pages.length}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _OnboardingContent(
                      page: _pages[index],
                    );
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: index == _currentPage ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              PrimaryButton(
                label: _currentPage == _pages.length - 1
                    ? 'Get started'
                    : 'Continue',
                onPressed: _continue,
              ),

              if (_currentPage < _pages.length - 1)
                TextButton(
                  onPressed: _complete,
                  child: const Text('Skip'),
                )
              else
                const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({
    required this.page,
  });

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: page.accent,
            borderRadius: BorderRadius.circular(38),
          ),
          child: SizedBox(
            width: 150,
            height: 150,
            child: Icon(
              page.icon,
              size: 64,
              color: AppColors.primaryDark,
            ),
          ),
        ),

        const SizedBox(height: 28),

        Text(
          page.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        const SizedBox(height: 10),

        Text(
          page.description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
        ),
      ],
    );
  }
}