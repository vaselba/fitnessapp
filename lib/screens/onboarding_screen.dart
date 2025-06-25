import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Color> get _tipColors => [
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.secondary,
        Theme.of(context).colorScheme.tertiary,
        Theme.of(context).colorScheme.surfaceTint,
        Theme.of(context).colorScheme.error,
        Theme.of(context).colorScheme.primaryContainer,
      ];

  List<_OnboardingTip> get _tips => [
        _OnboardingTip(
          icon: Icons.smart_toy,
          color: _tipColors[0],
          title: 'AI-powered Fitness Chat',
          description:
              'Get instant answers, personalized advice, and workout plans from your AI assistant.',
        ),
        _OnboardingTip(
          icon: Icons.show_chart,
          color: _tipColors[1],
          title: 'Track Your Progress',
          description:
              'Monitor your workouts, goals, and achievements over time.',
        ),
        _OnboardingTip(
          icon: Icons.palette,
          color: _tipColors[2],
          title: 'Customizable Themes',
          description:
              'Switch between light and dark mode to match your style.',
        ),
        _OnboardingTip(
          icon: Icons.language,
          color: _tipColors[3],
          title: 'Multi-language Support',
          description:
              'Use the app in your preferred language for a better experience.',
        ),
        _OnboardingTip(
          icon: Icons.lock_reset,
          color: _tipColors[4],
          title: 'Easy Password Reset',
          description:
              'Forgot your password? Reset it quickly and securely from the login screen.',
        ),
        _OnboardingTip(
          icon: Icons.settings,
          color: _tipColors[5],
          title: 'Settings & Privacy',
          description:
              'Manage your profile, privacy, and app preferences anytime from the settings menu.',
        ),
      ];

  void _nextPage() {
    if (_currentPage < _tips.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      widget.onFinish();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _skip() {
    widget.onFinish();
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _tips.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final tip = _tips[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tip.icon, color: tip.color, size: 64),
                        const SizedBox(height: 24),
                        Text(tip.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(tip.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _tips.length,
                  (index) => Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[400],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(onPressed: _prevPage, child: const Text('Back'))
                  else
                    const SizedBox(width: 64),
                  TextButton(onPressed: _skip, child: const Text('Skip')),
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage == _tips.length - 1
                        ? 'Get Started'
                        : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingTip {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _OnboardingTip(
      {required this.icon,
      required this.color,
      required this.title,
      required this.description});
}

Future<bool> shouldShowOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') != true;
}

Future<void> setOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_complete', true);
}
