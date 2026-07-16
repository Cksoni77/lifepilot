import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

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

  String title;
  bool completed;
  String category;
  TaskPriority priority;

  Task({
    required this.title,
    this.completed = false,
    this.category = defaultCategory,
    this.priority = TaskPriority.medium,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'completed': completed,
      'category': category,
      'priority': priority.name,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'] ?? '',
      completed: json['completed'] ?? false,
      category: json['category'] as String? ?? defaultCategory,
      priority: TaskPriority.values.firstWhere(
        (value) => value.name == (json['priority'] as String? ?? 'medium'),
        orElse: () => TaskPriority.medium,
      ),
    );
  }
}