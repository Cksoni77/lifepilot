import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class TaskService {
  TaskService({required this.userId});

  final String userId;

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key) ?? const [];
    return values
        .map(
          (value) => Task.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      tasks.map((task) => jsonEncode(task.toJson())).toList(),
    );
  }

  String get _key => 'tasks_$userId';
}
