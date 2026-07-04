class Task {

  String title;
  bool completed;

  Task({
    required this.title,
    this.completed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'completed': completed,
    };
  }

  factory Task.fromJson(
      Map<String, dynamic> json) {
    return Task(
      title: json['title'] ?? '',
      completed: json['completed'] ?? false,
    );
  }
}