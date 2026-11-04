import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/shared_controllers/app_controller.dart';
import 'package:lifepilot/features/profile/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores and persists theme and notification preferences', () async {
    SharedPreferences.setMockInitialValues({
      'onboardingCompleted': true,
      'theme': 'dark',
      'notificationsEnabled': false,
      'reminderEnabled': false,
    });
    final controller = AppController();

    await controller.load();
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.notificationsEnabled, isFalse);
    expect(controller.remindersEnabled, isFalse);

    await controller.setThemeMode(ThemeMode.light);
    await controller.setNotificationsEnabled(true);
    await controller.setRemindersEnabled(true);

    final restored = await UserService().loadPreferences();
    expect(restored.theme, 'light');
    expect(restored.notificationsEnabled, isTrue);
    expect(restored.reminderEnabled, isTrue);
    controller.dispose();
  });
}
