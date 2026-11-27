import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

abstract interface class TokenStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'lifepilot_access_token';
  static const _refreshTokenKey = 'lifepilot_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, TokenStore? tokenStore, Uri? baseUri})
    : _client = client ?? http.Client(),
      tokenStore = tokenStore ?? SecureTokenStore(),
      _baseUri =
          baseUri ??
          Uri.parse(
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8080',
            ),
          );

  static ApiClient instance = ApiClient();

  final http.Client _client;
  final Uri _baseUri;
  final TokenStore tokenStore;
  Future<bool>? _refreshInProgress;

  Future<dynamic> get(String path) => request('GET', path);

  Future<dynamic> post(String path, {Object? body}) =>
      request('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      request('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      request('PATCH', path, body: body);

  Future<dynamic> delete(String path) => request('DELETE', path);

  Future<dynamic> request(String method, String path, {Object? body}) async {
    final response = await _send(method, path, body: body);
    if (response.statusCode == 401 && _canRefresh(path)) {
      final refreshed = await _refreshSession();
      if (refreshed) {
        final retry = await _send(method, path, body: body);
        return _decodeResponse(retry);
      }
    }
    return _decodeResponse(response);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Object? body,
  }) async {
    final request = http.Request(method, _baseUri.resolve(path));
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final accessToken = await tokenStore.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      return await http.Response.fromStream(
        streamed,
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } on http.ClientException {
      throw const ApiException(
        'Could not reach the LifePilot server. Check your connection and server address.',
      );
    }
  }

  bool _canRefresh(String path) =>
      !path.endsWith('/auth/login') &&
      !path.endsWith('/auth/register') &&
      !path.endsWith('/auth/refresh') &&
      !path.endsWith('/auth/logout');

  Future<bool> _refreshSession() async {
    final pendingRefresh = _refreshInProgress;
    if (pendingRefresh != null) return pendingRefresh;
    final refresh = _performRefresh();
    _refreshInProgress = refresh;
    try {
      return await refresh;
    } finally {
      _refreshInProgress = null;
    }
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await tokenStore.clear();
      return false;
    }
    final request = http.Request('POST', _baseUri.resolve('/api/auth/refresh'))
      ..headers['Accept'] = 'application/json'
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'refreshToken': refreshToken});
    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        if (response.statusCode == 401 || response.statusCode == 403) {
          await tokenStore.clear();
        }
        return false;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await tokenStore.saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      return true;
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to refresh your session.',
      );
    } on http.ClientException {
      throw const ApiException('Could not reach the LifePilot server.');
    } on FormatException {
      throw const ApiException(
        'The server returned an invalid refresh response.',
      );
    }
  }

  dynamic _decodeResponse(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        throw const ApiException('The server returned an invalid response.');
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map<String, dynamic>
          ? data['message'] as String?
          : null;
      throw ApiException(
        message ?? 'The request failed. Please try again.',
        statusCode: response.statusCode,
      );
    }
    return data;
  }
}
