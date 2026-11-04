import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/goal.dart';

class GoalService {
  GoalService({required this.userId});

  final String userId;

  Future<List<Goal>> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key) ?? const [];
    return values
        .map(
          (value) => Goal.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveGoals(List<Goal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      goals.map((goal) => jsonEncode(goal.toJson())).toList(),
    );
  }

  String get _key => 'goals_$userId';
}
