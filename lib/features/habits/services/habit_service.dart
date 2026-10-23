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

  String get _key => 'habits_$userId';
}
