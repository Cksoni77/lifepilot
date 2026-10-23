import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../shared_controllers/app_controller.dart';
import '../features/auth/screens/onboarding_screen.dart';

class LifePilotApp extends StatefulWidget {
  const LifePilotApp({super.key});

  @override
  State<LifePilotApp> createState() => _LifePilotAppState();
}

class _LifePilotAppState extends State<LifePilotApp> {
  late final AppController _controller;
  bool _showSplash = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    _initialize();
  }

  Future<void> _initialize() async {
    await _controller.load();

    if (!mounted) return;

    _splashTimer?.cancel();
    _splashTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => AppControllerScope(
        notifier: _controller,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _controller.themeMode,
          home: _showSplash || _controller.isLoading
    ? const SplashScreen()
    : !_controller.onboardingCompleted
        ? const OnboardingScreen()
        : _controller.user == null
            ? const LoginScreen()
            : HomeScreen(userId: _controller.user!.id),
        ),
      ),
    );
  }
}
