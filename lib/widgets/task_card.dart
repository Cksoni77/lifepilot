import 'package:flutter/material.dart';

import '../models/task.dart';
import 'priority_chip.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.index,
    super.key,
  });

  final Task task;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;
  final int index;

  @override
  Widget build(BuildContext context) {
    final status = task.status();
    final statusText = status == TaskStatus.overdue
        ? '🔴 Overdue'
        : status == TaskStatus.dueToday
            ? '🟡 Due Today'
            : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: task.completed,
              onChanged: onToggle,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${task.priority.label} ${task.title}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(task.category),
                      const SizedBox(width: 10),
                      PriorityChip(priority: task.priority),
                    ],
                  ),
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Due: ${task.displayDueLabel.isNotEmpty ? task.displayDueLabel : task.formattedDueDate}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (task.reminderDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reminder: ${task.formattedReminderDate}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                  if (statusText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: status == TaskStatus.overdue ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
