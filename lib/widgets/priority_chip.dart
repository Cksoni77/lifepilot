import 'package:flutter/material.dart';

import '../models/task.dart';

class PriorityChip extends StatelessWidget {
  const PriorityChip({required this.priority, super.key});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: priority.color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
