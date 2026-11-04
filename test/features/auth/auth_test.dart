import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/features/auth/services/auth_service.dart';
import 'package:lifepilot/features/habits/models/habit.dart';
import 'package:lifepilot/features/habits/services/habit_service.dart';
import 'package:lifepilot/features/profile/models/user_preferences.dart';
import 'package:lifepilot/features/profile/services/user_service.dart';
import 'package:lifepilot/features/tasks/models/task.dart';
import 'package:lifepilot/features/tasks/services/task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/fake_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'register, login, refreshable session, and logout use the backend',
    () async {
      final server = FakeApiServer();
      final tokens = MemoryTokenStore();
      final auth = AuthService(
        apiClient: server.createClient(tokenStore: tokens),
      );

      final user = await auth.register(
        name: 'Chhotu Soni',
        email: 'user@email.com',
        password: 'strong-password-123',
      );
      expect(user.email, 'user@email.com');
      expect(tokens.accessToken, isNotNull);
      expect(await auth.isLoggedIn(), isTrue);
      expect((await auth.currentUser())?.name, 'Test');
      expect(
        await auth.login(email: 'user@email.com', password: 'wrong-password'),
        isNull,
      );
      expect(
        await auth.login(
          email: 'user@email.com',
          password: 'strong-password-123',
        ),
        isNotNull,
      );

      await auth.logout();
      expect(tokens.accessToken, isNull);
      expect(await auth.currentUser(), isNull);
    },
  );

  test(
    'legacy local credentials are erased without discarding profile data',
    () async {
      SharedPreferences.setMockInitialValues({
        'local_users': jsonEncode({
          'legacy-id': {
            'user': {
              'id': 'legacy-id',
              'name': 'Legacy',
              'email': 'old@example.com',
            },
            'password': 'plain-text-secret',
            'passwordHash': 'old-hash',
            'passwordSalt': 'old-salt',
          },
        }),
        'local_user_password': 'plain-text-secret',
        'local_auth_token': 'legacy-id',
        'tasks_legacy-id': ['{"title":"keep my task"}'],
      });

      final auth = AuthService(apiClient: FakeApiServer().createClient());
      expect(await auth.currentUser(), isNull);

      final prefs = await SharedPreferences.getInstance();
      final account =
          (jsonDecode(prefs.getString('local_users')!) as Map).values.single
              as Map;
      expect(account['user']['name'], 'Legacy');
      expect(account.containsKey('password'), isFalse);
      expect(account.containsKey('passwordHash'), isFalse);
      expect(prefs.containsKey('local_user_password'), isFalse);
      expect(prefs.containsKey('local_auth_token'), isFalse);
      expect(prefs.getStringList('tasks_legacy-id'), [
        '{"title":"keep my task"}',
      ]);
    },
  );

  test('preferences round-trip with theme and notification settings', () async {
    final service = UserService();
    const preferences = UserPreferences(
      theme: 'dark',
      notificationsEnabled: false,
      reminderEnabled: true,
    );

    await service.savePreferences(preferences);
    final restored = await service.loadPreferences();

    expect(restored.theme, 'dark');
    expect(restored.notificationsEnabled, isFalse);
    expect(restored.reminderEnabled, isTrue);
  });

  test(
    'remote task and habit data use separate authenticated API stores',
    () async {
      final firstApi = FakeApiServer().createClient();
      final secondApi = FakeApiServer().createClient();
      final firstTask = TaskService(userId: 'user-a', apiClient: firstApi);
      final secondTask = TaskService(userId: 'user-b', apiClient: secondApi);
      final firstHabit = HabitService(userId: 'user-a', apiClient: firstApi);
      final secondHabit = HabitService(userId: 'user-b', apiClient: secondApi);

      await firstTask.addTask(Task(id: 'task-a', title: 'Private task'));
      await firstHabit.addHabit(Habit(id: 'habit-a', name: 'Private habit'));

      expect(await secondTask.loadTasks(), isEmpty);
      expect(await secondHabit.loadHabits(), isEmpty);
      expect((await firstTask.loadTasks()).single.title, 'Private task');
      expect((await firstHabit.loadHabits()).single.name, 'Private habit');
    },
  );
}
