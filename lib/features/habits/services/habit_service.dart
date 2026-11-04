import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

class HabitService {
  HabitService({required this.userId});

  final String userId;

  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key) ?? const [];
    return values
        .map(
          (value) => Habit.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      habits.map((habit) => jsonEncode(habit.toJson())).toList(),
    );
  }

  Future<void> addHabit(Habit habit) async {
    _validateHabit(habit);
    final habits = await loadHabits();
    if (habits.any((existing) => existing.id == habit.id)) {
      throw StateError('A habit with this ID already exists.');
    }
    habits.add(habit);
    await saveHabits(habits);
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    _validateHabit(updatedHabit);
    final habits = await loadHabits();
    final index = habits.indexWhere((habit) => habit.id == updatedHabit.id);
    if (index < 0) throw StateError('This habit no longer exists.');

    final existingDates = habits[index].completedDates;
    final mergedDates = {
      ...existingDates,
      ...updatedHabit.completedDates,
    }.toList()..sort();
    if (mergedDates.any((date) => date.isBefore(updatedHabit.startDate))) {
      throw StateError('Start date cannot be after a recorded completion.');
    }
    updatedHabit.completedDates
      ..clear()
      ..addAll(mergedDates);
    habits[index] = updatedHabit;
    await saveHabits(habits);
  }

  Future<void> deleteHabit(String habitId) async {
    final habits = await loadHabits();
    habits.removeWhere((habit) => habit.id == habitId);
    await saveHabits(habits);
  }

  Future<bool> markCompleted(String habitId, DateTime date) async {
    final habits = await loadHabits();
    final index = habits.indexWhere((habit) => habit.id == habitId);
    if (index < 0 || !habits[index].markCompleted(date)) return false;
    await saveHabits(habits);
    return true;
  }

  Future<bool> undoCompletion(String habitId, DateTime date) async {
    final habits = await loadHabits();
    final index = habits.indexWhere((habit) => habit.id == habitId);
    if (index < 0 || !habits[index].undoCompletion(date)) return false;
    await saveHabits(habits);
    return true;
  }

  String get _key => 'habits_$userId';

  void _validateHabit(Habit habit) {
    if (habit.name.trim().isEmpty) {
      throw ArgumentError('Habit name is required.');
    }
    if (habit.frequency == HabitFrequency.customDays &&
        habit.selectedWeekdays.isEmpty) {
      throw ArgumentError('Select at least one weekday for a custom schedule.');
    }
  }
}
