import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/user_preferences.dart';

class UserService {
  static const _userKey = 'local_user';
  static const _preferencesKey = 'user_preferences';

  Future<User?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedUser = prefs.getString(_userKey);
    if (encodedUser == null) return null;
    return User.fromJson(jsonDecode(encodedUser) as Map<String, dynamic>);
  }

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserPreferences> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedPreferences = prefs.getString(_preferencesKey);
    if (encodedPreferences == null) return const UserPreferences();
    return UserPreferences.fromJson(
      jsonDecode(encodedPreferences) as Map<String, dynamic>,
    );
  }

  Future<void> savePreferences(UserPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferencesKey, jsonEncode(preferences.toJson()));
  }
}
