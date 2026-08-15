enum TaskPriority { low, medium, high }

enum TaskStatus { none, overdue, dueToday }

class Task {
  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.completed = false,
  });

  final String id;
  String title;
  String description;
  DateTime? dueDate;
  TaskPriority priority;
  bool completed;

  TaskStatus status({DateTime? asOf}) {
    if (completed || dueDate == null) return TaskStatus.none;
    final today = _dateOnly(asOf ?? DateTime.now());
    final due = _dateOnly(dueDate!);
    if (due.isBefore(today)) return TaskStatus.overdue;
    if (due == today) return TaskStatus.dueToday;
    return TaskStatus.none;
  }

  String get statusLabel => switch (status()) {
    TaskStatus.overdue => 'Overdue',
    TaskStatus.dueToday => 'Due Today',
    TaskStatus.none => '',
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate?.toIso8601String(),
    'priority': priority.name,
    'completed': completed,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    dueDate: json['dueDate'] == null
        ? null
        : DateTime.parse(json['dueDate'] as String),
    priority: TaskPriority.values.firstWhere(
      (value) => value.name == json['priority'],
      orElse: () => TaskPriority.medium,
    ),
    completed: json['completed'] as bool? ?? false,
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

extension TaskPriorityDetails on TaskPriority {
  String get label => name[0].toUpperCase() + name.substring(1);
}
