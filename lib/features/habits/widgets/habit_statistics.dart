import 'package:flutter/material.dart';

class HabitStatistics extends StatelessWidget {
  const HabitStatistics({
    required this.currentStreak,
    required this.longestStreak,
    super.key,
  });
  final int currentStreak;
  final int longestStreak;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [Text('Current: $currentStreak'), Text('Best: $longestStreak')],
  );
}
