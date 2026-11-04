class Goal {
  Goal({
    required this.id,
    required this.title,
    required this.category,
    this.progress = 0,
    this.targetDate,
  });

  final String id;
  String title;
  String category;
  double progress;
  DateTime? targetDate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'progress': progress,
    'targetDate': targetDate?.toIso8601String(),
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? 'Personal',
    progress: (json['progress'] as num?)?.toDouble() ?? 0,
    targetDate: json['targetDate'] == null
        ? null
        : DateTime.tryParse(json['targetDate'] as String),
  );
}
