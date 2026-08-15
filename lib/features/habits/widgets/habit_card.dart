import 'package:flutter/material.dart';

import '../models/habit.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({required this.habit, super.key});
  final Habit habit;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(habit.name),
      subtitle: Text('${habit.currentStreak()} day streak'),
    ),
  );
}
