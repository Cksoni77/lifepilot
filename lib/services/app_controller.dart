import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/user_preferences.dart';
import 'auth_service.dart';
import 'user_service.dart';

class AppController extends ChangeNotifier {
  AppController({AuthService? authService, UserService? userService})
      : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService();

  final AuthService _authService;
  final UserService _userService;
  User? user;
  UserPreferences preferences = const UserPreferences();
  bool isLoading = true;

  ThemeMode get themeMode => preferences.themeMode;

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppControllerScope>();
    assert(scope != null, 'AppControllerScope is missing above this context.');
    return scope!.notifier!;
  }

  Future<void> load() async {
    user = await _authService.currentUser();
    preferences = await _userService.loadPreferences(userId: user?.id);
    isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(User updatedUser, UserPreferences updatedPreferences) async {
    user = updatedUser;
    preferences = updatedPreferences;
    await _userService.saveUser(updatedUser);
    await _userService.savePreferences(updatedPreferences, userId: updatedUser.id);
    notifyListeners();
  }

  void refreshUser(User updatedUser) {
    user = updatedUser;
    notifyListeners();
  }
}

class AppControllerScope extends InheritedNotifier<AppController> {
  const AppControllerScope({required super.notifier, required super.child, super.key});
}
