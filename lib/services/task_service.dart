import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class TaskService {
  static const String _tasksKey = 'tasks';

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskJsonList = prefs.getStringList(_tasksKey);

    if (taskJsonList == null || taskJsonList.isEmpty) {
      return [];
    }

    return taskJsonList
        .map(
          (taskJson) => Task.fromJson(
            jsonDecode(taskJson) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final taskJsonList = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList(_tasksKey, taskJsonList);
  }

  Future<List<Task>> addTask(List<Task> tasks, Task task) async {
    tasks.add(task);
    await saveTasks(tasks);
    return tasks;
  }

  Future<List<Task>> updateTask(List<Task> tasks, int index, Task updatedTask) async {
    if (index < 0 || index >= tasks.length) return tasks;
    tasks[index] = updatedTask;
    await saveTasks(tasks);
    return tasks;
  }

  Future<List<Task>> deleteTask(List<Task> tasks, int index) async {
    if (index < 0 || index >= tasks.length) return tasks;
    tasks.removeAt(index);
    await saveTasks(tasks);
    return tasks;
  }
}
