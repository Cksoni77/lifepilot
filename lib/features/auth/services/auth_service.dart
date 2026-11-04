import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../models/user.dart';

class AuthService {
  AuthService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<User?> currentUser() async {
    await _sanitizeLegacyCredentials();
    if (await _apiClient.tokenStore.readAccessToken() == null) return null;
    final response = await _apiClient.get('/api/users/me');
    return User.fromJson(response as Map<String, dynamic>);
  }

  Future<bool> isLoggedIn() async => await currentUser() != null;

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _sanitizeLegacyCredentials();
    try {
      return await _authenticate('/api/auth/register', {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      });
    } on ApiException catch (error) {
      if (error.statusCode == 409) throw StateError(error.message);
      rethrow;
    }
  }

  Future<User?> login({required String email, required String password}) async {
    try {
      return await _authenticate('/api/auth/login', {
        'email': email.trim().toLowerCase(),
        'password': password,
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _apiClient.tokenStore.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _apiClient.post(
          '/api/auth/logout',
          body: {'refreshToken': refreshToken},
        );
      }
    } finally {
      await _apiClient.tokenStore.clear();
    }
  }

  Future<void> updateUser(User user) async {
    final response = await _apiClient.put(
      '/api/users/me',
      body: {'name': user.name},
    );
    final updated = User.fromJson(response as Map<String, dynamic>);
    user
      ..name = updated.name
      ..email = updated.email;
  }

  Future<User> _authenticate(String path, Map<String, dynamic> body) async {
    final response =
        await _apiClient.post(path, body: body) as Map<String, dynamic>;
    await _apiClient.tokenStore.saveTokens(
      response['accessToken'] as String,
      response['refreshToken'] as String,
    );
    return User.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<void> _sanitizeLegacyCredentials() async {
    final preferences = await SharedPreferences.getInstance();
    final storedAccounts = preferences.getString('local_users');
    if (storedAccounts != null) {
      try {
        final accounts = jsonDecode(storedAccounts) as Map<String, dynamic>;
        for (final value in accounts.values) {
          if (value is Map<String, dynamic>) {
            value
              ..remove('password')
              ..remove('passwordHash')
              ..remove('passwordSalt');
          }
        }
        await preferences.setString('local_users', jsonEncode(accounts));
      } on FormatException {
        await preferences.remove('local_users');
      }
    }
    await preferences.remove('local_user_password');
    await preferences.remove('local_auth_token');
  }
}
