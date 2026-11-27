import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifepilot/core/network/api_client.dart';

void main() {
  test('sends the stored access token as a bearer token', () async {
    final client = ApiClient(
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer access-token');
        return http.Response('{}', 200);
      }),
      tokenStore: _MemoryTokenStore()..accessToken = 'access-token',
      baseUri: Uri.parse('https://api.example.test'),
    );

    await client.get('/api/users/me');
  });
}

class _MemoryTokenStore implements TokenStore {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}
