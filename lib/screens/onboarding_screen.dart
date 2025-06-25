import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

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
              Text('Welcome to Fitnessa!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              const Text('• AI-powered fitness chat',
                  textAlign: TextAlign.center),
              const Text('• Track your progress', textAlign: TextAlign.center),
              const Text('• Multi-platform & secure',
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onFinish,
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> shouldShowOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') != true;
}

Future<void> setOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_complete', true);
}
