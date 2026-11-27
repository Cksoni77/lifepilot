import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../auth/models/user.dart';
import '../../goals/models/goal.dart';
import '../../goals/services/goal_service.dart';
import '../../habits/models/habit.dart';
import '../../habits/services/habit_service.dart';
import '../../tasks/models/task.dart';
import '../../tasks/services/task_service.dart';

class LegacyImportResult {
  const LegacyImportResult({
    required this.tasks,
    required this.habits,
    required this.goals,
  });

  final int tasks;
  final int habits;
  final int goals;
}

class LegacyDataMigrationService {
  LegacyDataMigrationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<LegacyImportResult> importFor(User user) async {
    final preferences = await SharedPreferences.getInstance();
    final localUserId = _findLocalUserId(preferences, user.email);
    final goals = _readRecords<Goal>(
      preferences,
      'goals_$localUserId',
      Goal.fromJson,
      'goal',
    );
    final habits = _readRecords<Habit>(
      preferences,
      'habits_$localUserId',
      Habit.fromJson,
      'habit',
    );
    final tasks = _readRecords<Task>(
      preferences,
      'tasks_$localUserId',
      Task.fromJson,
      'task',
    );
    final goalClientIds = {
      for (final goal in goals)
        goal.id: _clientId(localUserId, 'goal', goal.id),
    };
    final habitClientIds = {
      for (final habit in habits)
        habit.id: _clientId(localUserId, 'habit', habit.id),
    };
    final taskClientIds = {
      for (final task in tasks)
        task.id: _clientId(localUserId, 'task', task.id),
    };

    final goalsByLegacyId = <String, String>{};
    final goalService = GoalService(userId: user.id, apiClient: _apiClient);
    for (final goal in goals) {
      final legacyId = goal.id;
      goal.id = goalClientIds[legacyId]!;
      await goalService.addGoal(goal);
      goalsByLegacyId[legacyId] = goal.id;
    }

    final habitService = HabitService(userId: user.id, apiClient: _apiClient);
    for (final habit in habits) {
      habit.id = habitClientIds[habit.id]!;
      await habitService.addHabit(habit);
    }

    final taskService = TaskService(userId: user.id, apiClient: _apiClient);
    for (final task in tasks) {
      final legacyId = task.id;
      task.id = taskClientIds[legacyId]!;
      task.goalId = goalsByLegacyId[task.goalId];
      await taskService.addTask(task);
    }

    return LegacyImportResult(
      tasks: tasks.length,
      habits: habits.length,
      goals: goals.length,
    );
  }

  String _findLocalUserId(SharedPreferences preferences, String email) {
    final rawAccounts = preferences.getString('local_users');
    if (rawAccounts == null) {
      throw StateError('No previous local account data was found.');
    }
    final decoded = jsonDecode(rawAccounts);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Previous local account data is invalid.');
    }

    for (final entry in decoded.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;
      final localUser = value['user'];
      if (localUser is! Map<String, dynamic>) continue;
      final localEmail = localUser['email'];
      if (localEmail is String &&
          localEmail.toLowerCase() == email.toLowerCase()) {
        return entry.key;
      }
    }
    throw StateError(
      'No previous local account matches ${email.trim()}. '
      'Sign in with the account used before the migration.',
    );
  }

  List<T> _readRecords<T>(
    SharedPreferences preferences,
    String key,
    T Function(Map<String, dynamic>) fromJson,
    String recordType,
  ) {
    final rawRecords = preferences.getStringList(key) ?? const <String>[];
    return List<T>.generate(rawRecords.length, (index) {
      try {
        final decoded = jsonDecode(rawRecords[index]);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Expected an object.');
        }
        return fromJson(decoded);
      } on FormatException catch (error) {
        throw FormatException(
          'Cannot import $recordType ${index + 1}: ${error.message}',
        );
      } on TypeError catch (error) {
        throw FormatException(
          'Cannot import $recordType ${index + 1}: invalid data format ($error).',
        );
      } on ArgumentError catch (error) {
        throw FormatException(
          'Cannot import $recordType ${index + 1}: ${error.message}.',
        );
      }
    });
  }

  String _clientId(String localUserId, String recordType, String recordId) {
    final id = 'legacy:$localUserId:$recordType:$recordId';
    if (id.length > 80) {
      throw FormatException(
        'The legacy $recordType identifier is too long to import safely.',
      );
    }
    return id;
  }
}
