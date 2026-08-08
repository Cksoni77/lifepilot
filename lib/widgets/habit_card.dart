import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../utils/date_utils.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({required this.habit, required this.onToggleToday, super.key});

  final Habit habit;
  final VoidCallback onToggleToday;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final completedToday = habit.isCompletedOn(today);
    final progress = habit.completionRate();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(habit.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                Checkbox(value: completedToday, onChanged: (_) => onToggleToday()),
              ],
            ),
            if (habit.description.isNotEmpty) Text(habit.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(habit.frequency.label)),
                const SizedBox(width: 8),
                Text('Current: ${habit.currentStreak()} days'),
                const SizedBox(width: 8),
                Text('Best: ${habit.longestStreak()} days'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: LinearProgressIndicator(value: progress)),
                const SizedBox(width: 8),
                Text('${(progress * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Created ${habit.createdDate.day} ${shortMonthName(habit.createdDate.month)} ${habit.createdDate.year}'),
          ],
        ),
      ),
    );
  }
}
