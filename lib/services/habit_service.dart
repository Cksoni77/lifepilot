import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

class HabitService {
  HabitService({required this.userId});

  final String userId;

  String get _habitsKey => 'habits_$userId';

  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitJsonList = prefs.getStringList(_habitsKey) ?? <String>[];
    return habitJsonList
        .map((habitJson) => Habit.fromJson(jsonDecode(habitJson) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _habitsKey,
      habits.map((habit) => jsonEncode(habit.toJson())).toList(),
    );
  }
}
