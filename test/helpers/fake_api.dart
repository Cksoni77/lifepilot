import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifepilot/core/network/api_client.dart';

class MemoryTokenStore implements TokenStore {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens(String access, String refresh) async {
    accessToken = access;
    refreshToken = refresh;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

class FakeApiServer {
  FakeApiServer({
    List<Map<String, dynamic>> tasks = const [],
    List<Map<String, dynamic>> habits = const [],
    List<Map<String, dynamic>> goals = const [],
  }) : tasks = List.of(tasks),
       habits = List.of(habits),
       goals = List.of(goals);

  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> habits;
  final List<Map<String, dynamic>> goals;
  final Map<String, String> passwords = {};
  int _nextId = 0;

  ApiClient createClient({MemoryTokenStore? tokenStore}) => ApiClient(
    client: MockClient(_handle),
    tokenStore: tokenStore ?? MemoryTokenStore(),
    baseUri: Uri.parse('http://lifepilot.test'),
  );

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    final body = request.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;
    if (path == '/api/auth/register' || path == '/api/auth/login') {
      final email = (body['email'] as String).toLowerCase();
      if (path.endsWith('register')) {
        passwords[email] = body['password'] as String;
      } else if (passwords[email] != body['password']) {
        return _json(401, {'message': 'Email or password is incorrect'});
      }
      return _json(200, {
        'accessToken': 'test-access-token',
        'refreshToken': 'test-refresh-token',
        'user': {
          'id': 'test-user',
          'name': body['name'] ?? 'Test',
          'email': email,
        },
      });
    }
    if (path == '/api/auth/refresh') {
      return _json(200, {
        'accessToken': 'refreshed-access-token',
        'refreshToken': 'rotated-refresh-token',
        'user': {
          'id': 'test-user',
          'name': 'Test',
          'email': 'test@example.com',
        },
      });
    }
    if (path == '/api/auth/logout') return _json(200, {});
    if (path == '/api/users/me') {
      return _json(200, {
        'id': 'test-user',
        'name': 'Test',
        'email': 'test@example.com',
      });
    }
    if (path == '/api/tasks') {
      if (request.method == 'GET') return _json(200, tasks);
      if (request.method == 'POST') {
        final item = _task(body);
        tasks.add(item);
        return _json(201, item);
      }
    }
    if (path.startsWith('/api/tasks/')) {
      final parts = path.split('/');
      final id = parts[3];
      final index = tasks.indexWhere((item) => item['id'] == id);
      if (index < 0) return _json(404, {'message': 'Task not found'});
      if (parts.length == 5 && parts[4] == 'complete') {
        tasks[index]['completed'] = body['completed'];
        tasks[index]['completedAt'] = body['completed'] == true
            ? DateTime.now().toIso8601String()
            : null;
        return _json(200, tasks[index]);
      }
      if (request.method == 'PUT') {
        tasks[index] = _task(body, id: id);
        return _json(200, tasks[index]);
      }
      if (request.method == 'DELETE') {
        tasks.removeAt(index);
        return _json(200, {});
      }
      if (request.method == 'GET') return _json(200, tasks[index]);
    }
    if (path == '/api/habits/statistics') {
      return _json(200, {
        'totalHabits': habits.length,
        'completedThisWeek': 0,
        'scheduledThisWeek': 0,
      });
    }
    if (path == '/api/habits') {
      if (request.method == 'GET') return _json(200, habits);
      if (request.method == 'POST') {
        final item = _habit(body);
        habits.add(item);
        return _json(201, item);
      }
    }
    if (path.startsWith('/api/habits/')) {
      final parts = path.split('/');
      final id = parts[3];
      final index = habits.indexWhere((item) => item['id'] == id);
      if (parts.length == 5 && parts[4] == 'history') {
        return _json(200, index < 0 ? [] : habits[index]['completedDates']);
      }
      if (index < 0) return _json(404, {'message': 'Habit not found'});
      if (parts.length == 5 && parts[4] == 'complete') {
        final dates = List<String>.from(
          habits[index]['completedDates'] as List,
        );
        final date = body['date'] as String;
        if (!dates.contains(date)) dates.add(date);
        habits[index]['completedDates'] = dates;
        return _json(200, habits[index]);
      }
      if (parts.length == 4 && request.method == 'PUT') {
        habits[index] = _habit(body, id: id);
        return _json(200, habits[index]);
      }
      if (parts.length == 4 && request.method == 'DELETE') {
        habits.removeAt(index);
        return _json(200, {});
      }
      if (parts.length == 5 && parts[4] == 'completions') {
        final dates = List<String>.from(
          habits[index]['completedDates'] as List,
        );
        dates.remove(request.url.queryParameters['date']);
        habits[index]['completedDates'] = dates;
        return _json(200, habits[index]);
      }
    }
    if (path == '/api/goals') {
      if (request.method == 'GET') return _json(200, goals);
      if (request.method == 'POST') {
        final item = _goal(body);
        goals.add(item);
        return _json(201, item);
      }
    }
    if (path.startsWith('/api/goals/')) {
      final parts = path.split('/');
      final id = parts[3];
      final index = goals.indexWhere((item) => item['id'] == id);
      if (index < 0) return _json(404, {'message': 'Goal not found'});
      if (parts.length == 5 && parts[4] == 'progress') {
        goals[index]['progress'] = body['progress'];
        return _json(200, goals[index]);
      }
      if (request.method == 'PUT') {
        goals[index] = _goal(body, id: id);
        return _json(200, goals[index]);
      }
      if (request.method == 'DELETE') {
        goals.removeAt(index);
        return _json(200, {});
      }
    }
    if (path == '/api/ai/chat') {
      return _json(200, {
        'message': 'Test response',
        'intent': 'test',
        'relevantTaskIds': [],
        'recommendations': [],
        'suggestedActions': [],
        'explanation': 'Test server',
        'requiresConfirmation': false,
        'providerAvailable': false,
      });
    }
    return _json(404, {'message': 'Unknown test endpoint'});
  }

  Map<String, dynamic> _task(Map<String, dynamic> body, {String? id}) => {
    'id': id ?? body['clientId'] ?? 'test-task-${++_nextId}',
    'goalId': body['goalId'],
    'title': body['title'] ?? '',
    'description': body['description'] ?? '',
    'category': (body['category'] as String? ?? 'PERSONAL').toLowerCase(),
    'priority': (body['priority'] as String? ?? 'MEDIUM').toLowerCase(),
    'completed': body['completed'] ?? false,
    'dueDate': body['dueAt'] ?? body['dueDate'],
    'reminderDate': body['reminderAt'] ?? body['reminderDate'],
    'reminderEnabled': body['reminderEnabled'] ?? false,
    'estimatedMinutes': body['estimatedMinutes'],
    'createdAt': DateTime.now().toIso8601String(),
    'completedAt': body['completedAt'],
  };

  Map<String, dynamic> _habit(Map<String, dynamic> body, {String? id}) => {
    'id': id ?? body['clientId'] ?? 'test-habit-${++_nextId}',
    'name': body['name'] ?? '',
    'description': body['description'] ?? '',
    'frequency': body['frequency'] == 'customdays'
        ? 'customDays'
        : body['frequency'] ?? 'daily',
    'selectedWeekdays': body['selectedWeekdays'] ?? [],
    'targetDuration': body['targetDuration'],
    'durationUnit': body['durationUnit'] ?? 'minutes',
    'category': body['category'] ?? 'personal',
    'startDate': _dateOnly(body['startDate']),
    'completedDates': List<String>.from(
      (body['completedDates'] as List? ?? const []).map(_dateOnly),
    ),
  };

  Map<String, dynamic> _goal(Map<String, dynamic> body, {String? id}) => {
    'id': id ?? body['clientId'] ?? 'test-goal-${++_nextId}',
    'title': body['title'] ?? '',
    'description': body['description'] ?? '',
    'category': body['category'] ?? 'Personal',
    'progress': body['progress'] ?? 0,
    'targetDate': body['targetDate'],
    'milestones': body['milestones'] ?? [],
  };

  String? _dateOnly(dynamic value) =>
      value == null ? null : (value as String).split('T').first;

  http.Response _json(int status, Object body) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}

FakeApiServer installFakeApi({
  List<Map<String, dynamic>> tasks = const [],
  List<Map<String, dynamic>> habits = const [],
  List<Map<String, dynamic>> goals = const [],
}) {
  final server = FakeApiServer(tasks: tasks, habits: habits, goals: goals);
  ApiClient.instance = server.createClient();
  return server;
}
