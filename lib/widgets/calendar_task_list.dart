import 'package:flutter/material.dart';

import '../models/task.dart';

class CalendarTaskList extends StatelessWidget {
  const CalendarTaskList({
    required this.date,
    required this.tasks,
    required this.onToggle,
    super.key,
  });

  final DateTime date;
  final List<Task> tasks;
  final ValueChanged<Task> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tasks for ${date.day}/${date.month}/${date.year}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const Text('No tasks due on this date.')
        else
          ...tasks.map(
            (task) => Card(
              child: CheckboxListTile(
                value: task.completed,
                onChanged: (_) => onToggle(task),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text('${task.category} • ${task.priority.label}'),
                secondary: task.reminderEnabled
                    ? const Icon(Icons.notifications_active_outlined)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
