import '../../../core/network/api_client.dart';
import '../models/habit.dart';

class HabitService {
  HabitService({required this.userId, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final String userId;
  final ApiClient _apiClient;

  Future<List<Habit>> loadHabits() async {
    final response = await _apiClient.get('/api/habits') as List<dynamic>;
    return response
        .map((value) => Habit.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final existing = await loadHabits();
    final existingIds = existing.map((habit) => habit.id).toSet();
    final desiredIds = <String>{};
    for (final habit in habits) {
      if (existingIds.contains(habit.id)) {
        desiredIds.add(habit.id);
        await updateHabit(habit);
      } else {
        await addHabit(habit);
      }
    }
    for (final habit in existing) {
      if (!desiredIds.contains(habit.id) &&
          habits.every((desired) => desired.id != habit.id)) {
        await deleteHabit(habit.id);
      }
    }
  }

  Future<void> addHabit(Habit habit) async {
    _validateHabit(habit);
    final response =
        await _apiClient.post('/api/habits', body: _toRequest(habit))
            as Map<String, dynamic>;
    habit.id = response['id'] as String;
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    _validateHabit(updatedHabit);
    final matches = (await loadHabits())
        .where((habit) => habit.id == updatedHabit.id)
        .toList();
    final existing = matches.isEmpty ? null : matches.first;
    if (existing == null) throw StateError('This habit no longer exists.');
    final mergedDates = {
      ...existing.completedDates,
      ...updatedHabit.completedDates,
    }.toList()..sort();
    if (mergedDates.any((date) => date.isBefore(updatedHabit.startDate))) {
      throw StateError('Start date cannot be after a recorded completion.');
    }
    updatedHabit.completedDates
      ..clear()
      ..addAll(mergedDates);
    await _apiClient.put(
      '/api/habits/${updatedHabit.id}',
      body: _toRequest(updatedHabit),
    );
  }

  Future<void> deleteHabit(String habitId) async {
    await _apiClient.delete('/api/habits/$habitId');
  }

  Future<bool> markCompleted(String habitId, DateTime date) async {
    final habits = await loadHabits();
    final index = habits.indexWhere((habit) => habit.id == habitId);
    if (index < 0 || !habits[index].markCompleted(date)) return false;
    await _apiClient.post(
      '/api/habits/$habitId/complete',
      body: {'date': _dateOnly(date)},
    );
    return true;
  }

  Future<bool> undoCompletion(String habitId, DateTime date) async {
    final habits = await loadHabits();
    final index = habits.indexWhere((habit) => habit.id == habitId);
    if (index < 0 || !habits[index].undoCompletion(date)) return false;
    await _apiClient.delete(
      '/api/habits/$habitId/completions?date=${_dateOnly(date)}',
    );
    return true;
  }

  void _validateHabit(Habit habit) {
    if (habit.name.trim().isEmpty) {
      throw ArgumentError('Habit name is required.');
    }
    if (habit.frequency == HabitFrequency.customDays &&
        habit.selectedWeekdays.isEmpty) {
      throw ArgumentError('Select at least one weekday for a custom schedule.');
    }
  }

  Map<String, dynamic> _toRequest(Habit habit) => {
    'clientId': habit.id,
    'name': habit.name,
    'description': habit.description,
    'frequency': habit.frequency.name,
    'selectedWeekdays': habit.selectedWeekdays,
    'targetDuration': habit.targetDuration,
    'durationUnit': habit.durationUnit.name,
    'category': habit.category.name,
    'startDate': _dateOnly(habit.startDate),
    'completedDates': habit.completedDates.map(_dateOnly).toList(),
  };

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
