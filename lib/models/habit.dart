import '../utils/date_utils.dart';

enum HabitFrequency { daily, weekly }

extension HabitFrequencyExtension on HabitFrequency {
  String get label {
    switch (this) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
    }
  }
}

class Habit {
  final String id;
  String name;
  String description;
  HabitFrequency frequency;
  DateTime createdDate;
  List<DateTime> completedDates;
  bool isActive;

  Habit({
    required this.id,
    required this.name,
    this.description = '',
    this.frequency = HabitFrequency.daily,
    DateTime? createdDate,
    List<DateTime>? completedDates,
    this.isActive = true,
  })  : createdDate = startOfDay(createdDate ?? DateTime.now()),
        completedDates = (completedDates ?? <DateTime>[])
            .map(startOfDay)
            .toSet()
            .toList()
          ..sort();

  bool isCompletedOn(DateTime date) {
    final day = startOfDay(date);
    return completedDates.any((completedDate) => isSameDay(completedDate, day));
  }

  void setCompletedOn(DateTime date, bool completed) {
    final day = startOfDay(date);
    completedDates.removeWhere((completedDate) => isSameDay(completedDate, day));
    if (completed) {
      completedDates.add(day);
      completedDates.sort();
    }
  }

  int currentStreak({DateTime? asOf}) {
    if (!isActive) return 0;
    var cursor = startOfDay(asOf ?? DateTime.now());
    if (!isCompletedOn(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (isCompletedOn(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int longestStreak() {
    if (completedDates.isEmpty) return 0;
    final dates = completedDates.map(startOfDay).toSet().toList()..sort();
    var longest = 1;
    var current = 1;
    for (var index = 1; index < dates.length; index++) {
      if (dates[index].difference(dates[index - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  double completionRate({int days = 7, DateTime? asOf}) {
    if (days <= 0) return 0;
    final end = startOfDay(asOf ?? DateTime.now());
    final start = end.subtract(Duration(days: days - 1));
    final completed = completedDates.where((date) {
      final day = startOfDay(date);
      return !day.isBefore(start) && !day.isAfter(end);
    }).length;
    return completed / days;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'frequency': frequency.name,
      'createdDate': createdDate.toIso8601String(),
      'completedDates': completedDates.map((date) => date.toIso8601String()).toList(),
      'isActive': isActive,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      frequency: HabitFrequency.values.firstWhere(
        (value) => value.name == (json['frequency'] as String? ?? 'daily'),
        orElse: () => HabitFrequency.daily,
      ),
      createdDate: DateTime.parse(json['createdDate'] as String),
      completedDates: (json['completedDates'] as List<dynamic>? ?? <dynamic>[])
          .map((date) => DateTime.parse(date as String))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
