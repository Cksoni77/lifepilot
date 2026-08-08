import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/user_preferences.dart';

class UserService {
  static const _userKey = 'local_user';
  static const _preferencesKey = 'user_preferences';

  Future<User?> loadUser({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedUser = prefs.getString(_userKeyFor(userId));
    if (encodedUser == null) return null;
    return User.fromJson(jsonDecode(encodedUser) as Map<String, dynamic>);
  }

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKeyFor(user.id), jsonEncode(user.toJson()));
  }

  Future<UserPreferences> loadPreferences({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedPreferences = prefs.getString(_preferencesKeyFor(userId));
    if (encodedPreferences == null) return const UserPreferences();
    return UserPreferences.fromJson(
      jsonDecode(encodedPreferences) as Map<String, dynamic>,
    );
  }

  Future<void> savePreferences(UserPreferences preferences, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferencesKeyFor(userId), jsonEncode(preferences.toJson()));
  }

  String _userKeyFor(String? userId) => userId == null ? _userKey : '${_userKey}_$userId';

  String _preferencesKeyFor(String? userId) =>
      userId == null ? _preferencesKey : '${_preferencesKey}_$userId';
}
