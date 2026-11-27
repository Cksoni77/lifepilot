import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifepilot/core/network/api_client.dart';
import 'package:lifepilot/features/auth/models/user.dart';
import 'package:lifepilot/features/profile/services/legacy_data_migration_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const legacyUserId = 'local-user-1';
  const goalServerId = '00000000-0000-0000-0000-000000000001';
  final user = User(
    id: '00000000-0000-0000-0000-000000000010',
    name: 'Test User',
    email: 'user@example.com',
  );

  test(
    'imports legacy data retry-safely without deleting local copies',
    () async {
      final localData = {
        'local_users': jsonEncode({
          legacyUserId: {
            'user': {'id': legacyUserId, 'email': 'USER@example.com'},
          },
        }),
        'goals_$legacyUserId': [
          jsonEncode({
            'id': 'goal-1',
            'title': 'Read more',
            'category': 'Personal',
            'description': 'Keep reading',
            'milestones': ['Finish a book'],
            'progress': 0.25,
          }),
        ],
        'habits_$legacyUserId': [
          jsonEncode({
            'id': 'habit-1',
            'name': 'Read daily',
            'frequency': 'daily',
            'startDate': '2025-01-01',
            'completedDates': ['2025-01-02'],
          }),
        ],
        'tasks_$legacyUserId': [
          jsonEncode({
            'id': 'task-1',
            'title': 'Read a chapter',
            'category': 'personal',
            'priority': 'high',
            'completed': true,
            'completedAt': '2025-01-02T10:00:00Z',
            'goalId': 'goal-1',
          }),
        ],
      };
      SharedPreferences.setMockInitialValues(localData);

      final importedIds = <String, String>{};
      final sentRequests = <http.Request>[];
      final client = ApiClient(
        client: MockClient((request) async {
          sentRequests.add(request);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final clientId = body['clientId'] as String;
          final remoteId = importedIds.putIfAbsent(clientId, () {
            return request.url.path.endsWith('/goals')
                ? goalServerId
                : '00000000-0000-0000-0000-${importedIds.length.toString().padLeft(12, '0')}';
          });
          return http.Response(jsonEncode({'id': remoteId}), 201);
        }),
        tokenStore: _TestTokenStore(),
        baseUri: Uri.parse('https://api.example.test'),
      );
      final service = LegacyDataMigrationService(apiClient: client);

      final first = await service.importFor(user);
      final second = await service.importFor(user);

      expect(first.tasks, 1);
      expect(first.habits, 1);
      expect(first.goals, 1);
      expect(second.tasks, 1);
      expect(second.habits, 1);
      expect(second.goals, 1);
      expect(sentRequests, hasLength(6));
      expect(importedIds, hasLength(3));

      final goalRequest = sentRequests.firstWhere(
        (request) => request.url.path.endsWith('/goals'),
      );
      final habitRequest = sentRequests.firstWhere(
        (request) => request.url.path.endsWith('/habits'),
      );
      final taskRequest = sentRequests.firstWhere(
        (request) => request.url.path.endsWith('/tasks'),
      );
      final taskBody = jsonDecode(taskRequest.body) as Map<String, dynamic>;
      expect(
        jsonDecode(goalRequest.body)['clientId'],
        'legacy:$legacyUserId:goal:goal-1',
      );
      expect(
        jsonDecode(habitRequest.body)['clientId'],
        'legacy:$legacyUserId:habit:habit-1',
      );
      expect(taskBody['clientId'], 'legacy:$legacyUserId:task:task-1');
      expect(taskBody['goalId'], goalServerId);
      expect(taskBody['completed'], isTrue);
      expect(taskBody['completedAt'], '2025-01-02T10:00:00.000Z');

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getStringList('tasks_$legacyUserId'),
        localData['tasks_$legacyUserId'],
      );
      expect(
        preferences.getStringList('habits_$legacyUserId'),
        localData['habits_$legacyUserId'],
      );
      expect(
        preferences.getStringList('goals_$legacyUserId'),
        localData['goals_$legacyUserId'],
      );
    },
  );

  test(
    'validates all local records before sending any import request',
    () async {
      SharedPreferences.setMockInitialValues({
        'local_users': jsonEncode({
          legacyUserId: {
            'user': {'id': legacyUserId, 'email': user.email},
          },
        }),
        'goals_$legacyUserId': [
          jsonEncode({'id': 'goal-1', 'title': 'Goal', 'category': 'Personal'}),
        ],
        'tasks_$legacyUserId': ['not-json'],
      });
      var requestCount = 0;
      final client = ApiClient(
        client: MockClient((request) async {
          requestCount++;
          return http.Response('{}', 201);
        }),
        tokenStore: _TestTokenStore(),
        baseUri: Uri.parse('https://api.example.test'),
      );

      await expectLater(
        LegacyDataMigrationService(apiClient: client).importFor(user),
        throwsA(isA<FormatException>()),
      );
      expect(requestCount, 0);
    },
  );
}

class _TestTokenStore implements TokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => 'test-token';

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {}
}
