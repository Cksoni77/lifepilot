import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class TaskService {
  TaskService({
    required this.userId,
  });

  final String userId;

  // --------------------------------------------------
  // LOAD
  // --------------------------------------------------

  Future<List<Task>> loadTasks() async {
    final prefs =
        await SharedPreferences.getInstance();

    final values =
        prefs.getStringList(_key) ?? const [];

    return values
        .map(
          (value) => Task.fromJson(
            jsonDecode(value)
                as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // --------------------------------------------------
  // SAVE ALL
  // --------------------------------------------------

  Future<void> saveTasks(
    List<Task> tasks,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setStringList(
      _key,
      tasks
          .map(
            (task) => jsonEncode(
              task.toJson(),
            ),
          )
          .toList(),
    );
  }

  // --------------------------------------------------
  // ADD
  // --------------------------------------------------

  Future<void> addTask(Task task) async {
    final tasks = await loadTasks();

    tasks.add(task);

    await saveTasks(tasks);
  }

  // --------------------------------------------------
  // UPDATE
  // --------------------------------------------------

  Future<void> updateTask(
    Task updatedTask,
  ) async {
    final tasks = await loadTasks();

    final index = tasks.indexWhere(
      (task) => task.id == updatedTask.id,
    );

    if (index == -1) {
      return;
    }

    tasks[index] = updatedTask;

    await saveTasks(tasks);
  }

  // --------------------------------------------------
  // DELETE
  // --------------------------------------------------

  Future<void> deleteTask(
    String taskId,
  ) async {
    final tasks = await loadTasks();

    tasks.removeWhere(
      (task) => task.id == taskId,
    );

    await saveTasks(tasks);
  }

  // --------------------------------------------------
  // COMPLETE
  // --------------------------------------------------

  Future<void> setCompleted(
    String taskId,
    bool completed,
  ) async {
    final tasks = await loadTasks();

    final index = tasks.indexWhere(
      (task) => task.id == taskId,
    );

    if (index == -1) {
      return;
    }

    final task = tasks[index];

    task.completed = completed;

    task.completedAt =
        completed ? DateTime.now() : null;

    await saveTasks(tasks);
  }

  // --------------------------------------------------
  // AI
  // --------------------------------------------------

  Future<List<Map<String, dynamic>>>
      getTasksForAI() async {
    final tasks = await loadTasks();

    return tasks
        .map(
          (task) => task.toAIContext(),
        )
        .toList();
  }

  // --------------------------------------------------
  // STORAGE KEY
  // --------------------------------------------------

  String get _key => 'tasks_$userId';
}