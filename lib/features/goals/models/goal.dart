class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.category,
    required this.progress,
    this.targetDate,
  });

  final String id;
  final String title;
  final String category;
  final double progress;
  final DateTime? targetDate;
}
