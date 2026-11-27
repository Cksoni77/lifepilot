import 'package:flutter/material.dart';

class CalendarTaskList extends StatelessWidget {
  const CalendarTaskList({required this.tasks, super.key});
  final List<String> tasks;

  @override
  Widget build(BuildContext context) => Column(
    children: tasks.map((task) => ListTile(title: Text(task))).toList(),
  );
}
