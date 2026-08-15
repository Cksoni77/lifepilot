class Habit {
  Habit({required this.id, required this.name, List<DateTime>? completedDates})
    : completedDates =
          completedDates?.map(_dateOnly).toList(growable: true) ?? <DateTime>[];

  final String id;
  String name;
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
    'completedDates': completedDates
        .map((date) => date.toIso8601String())
        .toList(),
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    completedDates: (json['completedDates'] as List<dynamic>? ?? const [])
        .map((date) => DateTime.parse(date as String))
        .toList(),
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
