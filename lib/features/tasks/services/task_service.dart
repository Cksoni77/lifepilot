import '../../../core/network/api_client.dart';
import '../models/task.dart';

class TaskService {
  TaskService({required this.userId, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final String userId;
  final ApiClient _apiClient;

  // --------------------------------------------------
  // LOAD
  // --------------------------------------------------

  Future<List<Task>> loadTasks() async {
    final response = await _apiClient.get('/api/tasks') as List<dynamic>;
    return response
        .map((value) => Task.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  // --------------------------------------------------
  // SAVE ALL
  // --------------------------------------------------

  Future<void> saveTasks(List<Task> tasks) async {
    final remoteTasks = await loadTasks();
    final remoteById = {for (final task in remoteTasks) task.id: task};
    final desiredIds = <String>{};

    for (final task in tasks) {
      final existing = remoteById[task.id];
      if (existing == null) {
        await addTask(task);
      } else {
        desiredIds.add(task.id);
        await updateTask(task);
        if (existing.completed != task.completed) {
          await setCompleted(task.id, task.completed);
        }
      }
    }

    for (final task in remoteTasks) {
      if (!desiredIds.contains(task.id) &&
          tasks.every((desired) => desired.id != task.id)) {
        await deleteTask(task.id);
      }
    }
  }

  // --------------------------------------------------
  // ADD
  // --------------------------------------------------

  Future<void> addTask(Task task) async {
    final response =
        await _apiClient.post('/api/tasks', body: _toRequest(task))
            as Map<String, dynamic>;
    task.id = response['id'] as String;
  }

  // --------------------------------------------------
  // UPDATE
  // --------------------------------------------------

  Future<void> updateTask(Task updatedTask) async {
    await _apiClient.put(
      '/api/tasks/${updatedTask.id}',
      body: _toRequest(updatedTask),
    );
  }

  // --------------------------------------------------
  // DELETE
  // --------------------------------------------------

  Future<void> deleteTask(String taskId) async {
    await _apiClient.delete('/api/tasks/$taskId');
  }

  // --------------------------------------------------
  // COMPLETE
  // --------------------------------------------------

  Future<void> setCompleted(String taskId, bool completed) async {
    await _apiClient.patch(
      '/api/tasks/$taskId/complete',
      body: {'completed': completed},
    );
  }

  // --------------------------------------------------
  // AI
  // --------------------------------------------------

  Future<List<Map<String, dynamic>>> getTasksForAI() async {
    final tasks = await loadTasks();

    return tasks.map((task) => task.toAIContext()).toList();
  }

  // --------------------------------------------------
  // STORAGE KEY
  // --------------------------------------------------

  Map<String, dynamic> _toRequest(Task task) => {
    'clientId': task.id,
    'title': task.title,
    'description': task.description,
    'category': task.category.name.toUpperCase(),
    'priority': task.priority.name.toUpperCase(),
    'dueAt': _withOffset(task.dueDate),
    'reminderAt': _withOffset(task.reminderDate),
    'reminderEnabled': task.reminderEnabled,
    'estimatedMinutes': task.estimatedMinutes,
    'goalId': task.goalId,
  };

  String? _withOffset(DateTime? date) {
    if (date == null || date.isUtc) return date?.toIso8601String();
    final offset = date.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = offset.inMinutes
        .abs()
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '${date.toIso8601String()}$sign$hours:$minutes';
  }
}
