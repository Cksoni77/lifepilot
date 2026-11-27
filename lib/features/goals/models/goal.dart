class Goal {
  Goal({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    List<String>? milestones,
    this.progress = 0,
    this.targetDate,
  }) : milestones = List<String>.of(milestones ?? const []);

  String id;
  String title;
  String category;
  String description;
  final List<String> milestones;
  double progress;
  DateTime? targetDate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'description': description,
    'milestones': milestones,
    'progress': progress,
    'targetDate': targetDate?.toIso8601String(),
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? 'Personal',
    description: json['description'] as String? ?? '',
    milestones: (json['milestones'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    progress: (json['progress'] as num?)?.toDouble() ?? 0,
    targetDate: json['targetDate'] == null
        ? null
        : DateTime.tryParse(json['targetDate'] as String),
  );
}
