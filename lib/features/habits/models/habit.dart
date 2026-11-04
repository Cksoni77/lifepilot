enum HabitFrequency { daily, weekdays, weekends, customDays }

enum HabitDurationUnit { minutes, hours }

enum HabitCategory { health, fitness, personal, learning, work, other }

extension HabitFrequencyDetails on HabitFrequency {
  String get label => switch (this) {
    HabitFrequency.daily => 'Daily',
    HabitFrequency.weekdays => 'Weekdays',
    HabitFrequency.weekends => 'Weekends',
    HabitFrequency.customDays => 'Custom days',
  };
}

extension HabitDurationUnitDetails on HabitDurationUnit {
  String get label => switch (this) {
    HabitDurationUnit.minutes => 'Minutes',
    HabitDurationUnit.hours => 'Hours',
  };
}

extension HabitCategoryDetails on HabitCategory {
  String get label => name[0].toUpperCase() + name.substring(1);
}

class Habit {
  Habit({
    required this.id,
    required this.name,
    this.description = '',
    this.frequency = HabitFrequency.daily,
    List<int>? selectedWeekdays,
    this.targetDuration,
    this.durationUnit = HabitDurationUnit.minutes,
    this.category = HabitCategory.personal,
    DateTime? startDate,
    List<DateTime>? completedDates,
  }) : selectedWeekdays = _normalizeWeekdays(selectedWeekdays),
       startDate = _dateOnly(startDate ?? _defaultStartDate(completedDates)),
       completedDates = _normalizeCompletedDates(completedDates) {
    if (targetDuration != null && targetDuration! <= 0) {
      throw ArgumentError.value(targetDuration, 'targetDuration');
    }
    if (this.completedDates.any((date) => date.isBefore(this.startDate))) {
      throw ArgumentError('Completion dates cannot be before the start date.');
    }
  }

  String id;
  String name;
  String description;
  HabitFrequency frequency;
  final List<int> selectedWeekdays;
  double? targetDuration;
  HabitDurationUnit durationUnit;
  HabitCategory category;
  DateTime startDate;
  final List<DateTime> completedDates;

  int currentStreak({DateTime? asOf}) {
    final today = _dateOnly(asOf ?? DateTime.now());
    final days = completedDates.map(_dateOnly).toSet();
    var cursor = days.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  bool isScheduledOn(DateTime date) => switch (frequency) {
    HabitFrequency.daily => true,
    HabitFrequency.weekdays =>
      date.weekday >= DateTime.monday && date.weekday <= DateTime.friday,
    HabitFrequency.weekends =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday,
    HabitFrequency.customDays => selectedWeekdays.contains(date.weekday),
  };

  bool markCompleted(DateTime date) {
    final normalized = _dateOnly(date);
    if (normalized.isBefore(startDate) ||
        !isScheduledOn(normalized) ||
        completedDates.any((completed) => _sameDay(completed, normalized))) {
      return false;
    }
    completedDates.add(normalized);
    completedDates.sort();
    return true;
  }

  bool undoCompletion(DateTime date) {
    final initialLength = completedDates.length;
    completedDates.removeWhere((completed) => _sameDay(completed, date));
    return completedDates.length != initialLength;
  }

  int longestStreak() {
    final days = completedDates.map(_dateOnly).toSet().toList()..sort();
    var longest = 0;
    var current = 0;
    DateTime? previous;
    for (final day in days) {
      current = previous != null && day.difference(previous).inDays == 1
          ? current + 1
          : 1;
      if (current > longest) longest = current;
      previous = day;
    }
    return longest;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'frequency': frequency.name,
    'selectedWeekdays': selectedWeekdays,
    'targetDuration': targetDuration,
    'durationUnit': durationUnit.name,
    'category': category.name,
    'startDate': startDate.toIso8601String(),
    'completedDates': completedDates
        .map((date) => date.toIso8601String())
        .toList(),
  };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final completedDates = _parseCompletionDates(json['completedDates']);
    final startDateValue = json['startDate'];
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      frequency: HabitFrequency.values.firstWhere(
        (value) => value.name == json['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      selectedWeekdays: (json['selectedWeekdays'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((day) => day.toInt())
          .toList(),
      targetDuration: (json['targetDuration'] as num?)?.toDouble(),
      durationUnit: HabitDurationUnit.values.firstWhere(
        (value) => value.name == json['durationUnit'],
        orElse: () => HabitDurationUnit.minutes,
      ),
      category: HabitCategory.values.firstWhere(
        (value) => value.name == json['category'],
        orElse: () => HabitCategory.personal,
      ),
      startDate: startDateValue is String
          ? DateTime.tryParse(startDateValue) ??
                _defaultStartDate(completedDates)
          : _defaultStartDate(completedDates),
      completedDates: completedDates,
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _defaultStartDate(List<DateTime>? completedDates) {
  if (completedDates == null || completedDates.isEmpty) {
    return _dateOnly(DateTime.now());
  }
  return completedDates
      .map(_dateOnly)
      .reduce((first, second) => first.isBefore(second) ? first : second);
}

List<int> _normalizeWeekdays(List<int>? weekdays) =>
    (weekdays ?? const <int>[])
        .where((day) => day >= 1 && day <= 7)
        .toSet()
        .toList()
      ..sort();

List<DateTime> _normalizeCompletedDates(List<DateTime>? dates) =>
    (dates ?? const <DateTime>[]).map(_dateOnly).toSet().toList()..sort();

List<DateTime> _parseCompletionDates(Object? value) {
  if (value is! List) return [];
  return value
      .whereType<String>()
      .map(DateTime.tryParse)
      .whereType<DateTime>()
      .toList();
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
