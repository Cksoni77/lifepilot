import 'package:flutter/material.dart';

import '../../features/tasks/models/task.dart';

class PriorityChip extends StatelessWidget {
  const PriorityChip({required this.priority, super.key});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _colorFor(priority).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: _colorFor(priority),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _colorFor(TaskPriority value) => switch (value) {
    TaskPriority.low => Colors.green,
    TaskPriority.medium => Colors.orange,
    TaskPriority.high => Colors.red,
  };
}
