import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { none, overdue, dueToday }

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }
}

class Task {
  static const String defaultCategory = '🏠 Personal';
  static const List<String> supportedCategories = <String>[
    '💼 Work',
    '🏠 Personal',
    '📚 Study',
    '🏋 Health',
    '🛒 Shopping',
    '💰 Finance',
    '🎯 Goals',
    '📌 Others',
  ];

  String id;
  String title;
  bool completed;
  String category;
  TaskPriority priority;
  DateTime? dueDate;
  DateTime? reminderDate;
  bool reminderEnabled;

  Task({
    required this.id,
    required this.title,
    this.completed = false,
    this.category = defaultCategory,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.reminderDate,
    this.reminderEnabled = false,
  });

  TaskStatus status({DateTime? now}) {
    if (completed || dueDate == null) {
      return TaskStatus.none;
    }

    final currentDate = _startOfDay(now ?? DateTime.now());
    final taskDueDate = _startOfDay(dueDate!);

    if (taskDueDate.isBefore(currentDate)) {
      return TaskStatus.overdue;
    }

    if (taskDueDate.isAtSameMomentAs(currentDate)) {
      return TaskStatus.dueToday;
    }

    return TaskStatus.none;
  }

  String get statusLabel {
    switch (status()) {
      case TaskStatus.overdue:
        return 'Overdue';
      case TaskStatus.dueToday:
        return 'Due Today';
      case TaskStatus.none:
        return '';
    }
  }

  String get displayDueLabel {
    if (dueDate == null) {
      return '';
    }

    final today = _startOfDay(DateTime.now());
    final due = _startOfDay(dueDate!);
    final difference = due.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    }
    if (difference == -1) {
      return 'Yesterday';
    }
    if (difference == 1) {
      return 'Tomorrow';
    }

    return formattedDueDate;
  }

  String get formattedDueDate {
    if (dueDate == null) {
      return '';
    }

    return '${_monthName(dueDate!.month)} ${dueDate!.day}, ${dueDate!.year}';
  }

  String get formattedReminderDate {
    if (reminderDate == null) {
      return '';
    }

    final hour = reminderDate!.hour % 12 == 0 ? 12 : reminderDate!.hour % 12;
    final minute = reminderDate!.minute.toString().padLeft(2, '0');
    final suffix = reminderDate!.hour >= 12 ? 'PM' : 'AM';

    return '${_monthName(reminderDate!.month)} ${reminderDate!.day}, ${reminderDate!.year} $hour:$minute $suffix';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'category': category,
      'priority': priority.name,
      'dueDate': dueDate?.toIso8601String(),
      'reminderDate': reminderDate?.toIso8601String(),
      'reminderEnabled': reminderEnabled,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] ?? '',
      completed: json['completed'] ?? false,
      category: json['category'] as String? ?? defaultCategory,
      priority: TaskPriority.values.firstWhere(
        (value) => value.name == (json['priority'] as String? ?? 'medium'),
        orElse: () => TaskPriority.medium,
      ),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      reminderDate: json['reminderDate'] != null
          ? DateTime.parse(json['reminderDate'] as String)
          : null,
      reminderEnabled: json['reminderEnabled'] ?? false,    
    );
  }
}

DateTime _startOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String _monthName(int month) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[month - 1];
}