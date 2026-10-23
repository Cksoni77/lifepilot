enum TaskPriority {
  low,
  medium,
  high,
}

enum TaskStatus {
  none,
  overdue,
  dueToday,
}

enum TaskCategory {
  personal,
  work,
  health,
  finance,
}

extension TaskPriorityDetails on TaskPriority {
  String get label {
    return name[0].toUpperCase() + name.substring(1);
  }
}

extension TaskCategoryDetails on TaskCategory {
  String get label {
    switch (this) {
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.finance:
        return 'Finance';
    }
  }
}

class Task {
  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.category = TaskCategory.personal,
    this.priority = TaskPriority.medium,
    this.completed = false,
    this.dueDate,
    this.reminderDate,
    this.reminderEnabled = false,
    this.estimatedMinutes,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;

  String title;
  String description;

  TaskCategory category;
  TaskPriority priority;

  bool completed;

  DateTime? dueDate;

  DateTime? reminderDate;
  bool reminderEnabled;

  int? estimatedMinutes;

  final DateTime createdAt;

  DateTime? completedAt;

  // --------------------------------------------------
  // STATUS
  // --------------------------------------------------

  TaskStatus status({DateTime? asOf}) {
    if (completed || dueDate == null) {
      return TaskStatus.none;
    }

    final today = _dateOnly(asOf ?? DateTime.now());
    final due = _dateOnly(dueDate!);

    if (due.isBefore(today)) {
      return TaskStatus.overdue;
    }

    if (due == today) {
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

  bool get isOverdue {
    return status() == TaskStatus.overdue;
  }

  bool get isDueToday {
    return status() == TaskStatus.dueToday;
  }

  bool get hasDueDate {
    return dueDate != null;
  }

  bool get hasReminder {
    return reminderEnabled && reminderDate != null;
  }

  // --------------------------------------------------
  // AI CONTEXT
  // --------------------------------------------------

  Map<String, dynamic> toAIContext() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.label,
      'priority': priority.name,
      'completed': completed,
      'status': statusLabel.isEmpty ? 'Pending' : statusLabel,
      'dueDate': dueDate?.toIso8601String(),
      'reminderDate': reminderDate?.toIso8601String(),
      'estimatedMinutes': estimatedMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // --------------------------------------------------
  // JSON
  // --------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'completed': completed,
      'dueDate': dueDate?.toIso8601String(),
      'reminderDate': reminderDate?.toIso8601String(),
      'reminderEnabled': reminderEnabled,
      'estimatedMinutes': estimatedMinutes,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // --------------------------------------------------
  // JSON → TASK
  // --------------------------------------------------

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',

      category: TaskCategory.values.firstWhere(
        (value) => value.name == json['category'],
        orElse: () => TaskCategory.personal,
      ),

      priority: TaskPriority.values.firstWhere(
        (value) => value.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),

      completed: json['completed'] as bool? ?? false,

      dueDate: json['dueDate'] == null
          ? null
          : DateTime.tryParse(json['dueDate'] as String),

      reminderDate: json['reminderDate'] == null
          ? null
          : DateTime.tryParse(json['reminderDate'] as String),

      reminderEnabled:
          json['reminderEnabled'] as bool? ?? false,

      estimatedMinutes:
          (json['estimatedMinutes'] as num?)?.toInt(),

      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.tryParse(
                json['createdAt'] as String,
              ) ??
              DateTime.now(),

      completedAt: json['completedAt'] == null
          ? null
          : DateTime.tryParse(
              json['completedAt'] as String,
            ),
    );
  }
}

DateTime _dateOnly(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
  );
}