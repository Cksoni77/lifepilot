import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class AuthService {
  static const _usersKey = 'local_users';
  static const _legacyUserKey = 'local_user';
  static const _legacyPasswordKey = 'local_user_password';
  static const _tokenKey = 'local_auth_token';

  Future<User?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_tokenKey);
    if (userId == null) return null;
    final accounts = await _loadAccounts(prefs);
    final account = accounts[userId];
    return account == null
        ? null
        : User.fromJson(account['user'] as Map<String, dynamic>);
  }

  Future<User?> registeredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    if (accounts.isEmpty) return null;
    return User.fromJson(accounts.values.first['user'] as Map<String, dynamic>);
  }

  Future<bool> isLoggedIn() async => (await currentUser()) != null;

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    final normalizedEmail = email.trim().toLowerCase();
    if (accounts.values.any(
      (account) =>
          (account['user'] as Map<String, dynamic>)['email'] == normalizedEmail,
    )) {
      throw StateError('An account with this email already exists.');
    }
    final user = User(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      email: normalizedEmail,
    );
    accounts[user.id] = {'user': user.toJson(), 'password': password};
    await _saveAccounts(prefs, accounts);
    await prefs.setString(_tokenKey, user.id);
    return user;
  }

  Future<User?> login({required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    final accountEntry = accounts.values
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (account) =>
              (account?['user'] as Map<String, dynamic>?)?['email'] ==
              email.trim().toLowerCase(),
          orElse: () => null,
        );
    if (accountEntry == null || accountEntry['password'] != password) {
      return null;
    }
    final user = User.fromJson(accountEntry['user'] as Map<String, dynamic>);
    await prefs.setString(_tokenKey, user.id);
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> updateUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    final account = accounts[user.id];
    if (account == null) return;
    account['user'] = user.toJson();
    await _saveAccounts(prefs, accounts);
  }

  Future<Map<String, Map<String, dynamic>>> _loadAccounts(
    SharedPreferences prefs,
  ) async {
    final encodedAccounts = prefs.getString(_usersKey);
    if (encodedAccounts != null) {
      final decoded = jsonDecode(encodedAccounts) as Map<String, dynamic>;
      return decoded.map(
        (id, value) => MapEntry(id, Map<String, dynamic>.from(value as Map)),
      );
    }
    final legacyUser = prefs.getString(_legacyUserKey);
    if (legacyUser == null) return <String, Map<String, dynamic>>{};
    final user = jsonDecode(legacyUser) as Map<String, dynamic>;
    final id = user['id'] as String;
    return {
      id: {'user': user, 'password': prefs.getString(_legacyPasswordKey) ?? ''},
    };
  }

  Future<void> _saveAccounts(
    SharedPreferences prefs,
    Map<String, Map<String, dynamic>> accounts,
  ) async {
    await prefs.setString(_usersKey, jsonEncode(accounts));
  }
}
