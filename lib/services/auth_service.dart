import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class AuthService {
  static const _userKey = 'local_user';
  static const _passwordKey = 'local_user_password';
  static const _tokenKey = 'local_auth_token';

  Future<User?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedUser = prefs.getString(_userKey);
    if (encodedUser == null || prefs.getString(_tokenKey) == null) return null;
    return User.fromJson(jsonDecode(encodedUser) as Map<String, dynamic>);
  }

  Future<User?> registeredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedUser = prefs.getString(_userKey);
    if (encodedUser == null) return null;
    return User.fromJson(jsonDecode(encodedUser) as Map<String, dynamic>);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
    );
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_passwordKey, password);
    await prefs.setString(_tokenKey, _createToken(user));
    return user;
  }

  Future<User?> login({required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedUser = prefs.getString(_userKey);
    if (encodedUser == null || prefs.getString(_passwordKey) != password) return null;
    final user = User.fromJson(jsonDecode(encodedUser) as Map<String, dynamic>);
    if (user.email != email.trim().toLowerCase()) return null;
    await prefs.setString(_tokenKey, _createToken(user));
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  String _createToken(User user) {
    final payload = '${user.id}:${DateTime.now().millisecondsSinceEpoch}';
    return base64Url.encode(utf8.encode(payload));
  }
}
