import 'package:flutter/material.dart';

import '../models/habit.dart';

class HabitStatistics extends StatelessWidget {
  const HabitStatistics({required this.habits, super.key});

  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final activeHabits = habits.where((habit) => habit.isActive).toList();
    final completedToday = activeHabits.where((habit) => habit.isCompletedOn(today)).length;
    final completionRate = activeHabits.isEmpty ? 0.0 : completedToday / activeHabits.length;
    final currentStreak = activeHabits.isEmpty
        ? 0
        : activeHabits.map((habit) => habit.currentStreak()).reduce((a, b) => a > b ? a : b);
    final longestStreak = activeHabits.isEmpty
        ? 0
        : activeHabits.map((habit) => habit.longestStreak()).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Habit Statistics', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _Stat(label: 'Total Habits', value: '${activeHabits.length}'),
                _Stat(label: 'Completed Today', value: '$completedToday/${activeHabits.length}'),
                _Stat(label: 'Completion Rate', value: '${(completionRate * 100).round()}%'),
                _Stat(label: 'Current Streak', value: '$currentStreak days'),
                _Stat(label: 'Longest Streak', value: '$longestStreak days'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 125,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
