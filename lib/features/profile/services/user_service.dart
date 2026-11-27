import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_preferences.dart';

class UserService {
  Future<UserPreferences> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return UserPreferences(
      theme: prefs.getString('theme') ?? 'system',
      notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
      reminderEnabled: prefs.getBool('reminderEnabled') ?? true,
    );
  }

  Future<void> savePreferences(UserPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', preferences.theme);
    await prefs.setBool(
      'notificationsEnabled',
      preferences.notificationsEnabled,
    );
    await prefs.setBool('reminderEnabled', preferences.reminderEnabled);
  }
}
