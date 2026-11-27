import '../../../core/network/api_client.dart';
import '../models/goal.dart';

class GoalService {
  GoalService({required this.userId, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final String userId;
  final ApiClient _apiClient;

  Future<List<Goal>> loadGoals() async {
    final response = await _apiClient.get('/api/goals') as List<dynamic>;
    return response
        .map((value) => Goal.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveGoals(List<Goal> goals) async {
    final existing = await loadGoals();
    final existingIds = existing.map((goal) => goal.id).toSet();
    final desiredIds = <String>{};
    for (final goal in goals) {
      if (existingIds.contains(goal.id)) {
        desiredIds.add(goal.id);
        await _apiClient.put('/api/goals/${goal.id}', body: _toRequest(goal));
      } else {
        final response =
            await _apiClient.post('/api/goals', body: _toRequest(goal))
                as Map<String, dynamic>;
        goal.id = response['id'] as String;
      }
    }
    for (final goal in existing) {
      if (!desiredIds.contains(goal.id) &&
          goals.every((desired) => desired.id != goal.id)) {
        await _apiClient.delete('/api/goals/${goal.id}');
      }
    }
  }

  Map<String, dynamic> _toRequest(Goal goal) => {
    'clientId': goal.id,
    'title': goal.title,
    'description': '',
    'category': goal.category,
    'progress': goal.progress.clamp(0, 1),
    'targetDate': goal.targetDate == null
        ? null
        : '${goal.targetDate!.year.toString().padLeft(4, '0')}-'
              '${goal.targetDate!.month.toString().padLeft(2, '0')}-'
              '${goal.targetDate!.day.toString().padLeft(2, '0')}',
    'milestones': <String>[],
  };
}
