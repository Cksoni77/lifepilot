import 'package:flutter/material.dart';

import 'task.dart';

class UserPreferences {
  const UserPreferences({
    this.theme = 'system',
    this.notificationsEnabled = true,
    this.reminderEnabled = true,
    this.defaultTaskPriority = TaskPriority.medium,
    this.startOfWeek = DateTime.monday,
  });

  final String theme;
  final bool notificationsEnabled;
  final bool reminderEnabled;
  final TaskPriority defaultTaskPriority;
  final int startOfWeek;

  ThemeMode get themeMode {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  UserPreferences copyWith({
    String? theme,
    bool? notificationsEnabled,
    bool? reminderEnabled,
    TaskPriority? defaultTaskPriority,
    int? startOfWeek,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      defaultTaskPriority: defaultTaskPriority ?? this.defaultTaskPriority,
      startOfWeek: startOfWeek ?? this.startOfWeek,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'notificationsEnabled': notificationsEnabled,
      'reminderEnabled': reminderEnabled,
      'defaultTaskPriority': defaultTaskPriority.name,
      'startOfWeek': startOfWeek,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] as String? ?? 'system',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      defaultTaskPriority: TaskPriority.values.firstWhere(
        (value) => value.name == (json['defaultTaskPriority'] as String? ?? 'medium'),
        orElse: () => TaskPriority.medium,
      ),
      startOfWeek: json['startOfWeek'] as int? ?? DateTime.monday,
    );
  }
}
