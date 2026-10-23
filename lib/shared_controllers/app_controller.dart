import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/models/user.dart';
import '../features/auth/services/auth_service.dart';

class AppController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? user;

  ThemeMode themeMode = ThemeMode.system;

  bool isLoading = true;

  // Onboarding state
  bool _onboardingCompleted = false;

  bool get onboardingCompleted => _onboardingCompleted;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    // Check whether onboarding has been completed.
    _onboardingCompleted =
        prefs.getBool('onboardingCompleted') ?? false;

    // Load existing user.
    user = await _authService.currentUser();

    isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('onboardingCompleted', true);

    _onboardingCompleted = true;

    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('onboardingCompleted');

    _onboardingCompleted = false;

    notifyListeners();
  }

  void refreshUser(User? value) {
    user = value;
    notifyListeners();
  }

  void setThemeMode(ThemeMode value) {
    themeMode = value;
    notifyListeners();
  }

  static AppController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppControllerScope>();

    assert(
      scope != null,
      'AppControllerScope is missing above this context.',
    );

    return scope!.notifier!;
  }
}

class AppControllerScope extends InheritedNotifier<AppController> {
  const AppControllerScope({
    required AppController notifier,
    required super.child,
    super.key,
  }) : super(notifier: notifier);
}