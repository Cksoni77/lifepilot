import 'package:flutter/material.dart';

import '../models/goal.dart';

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({required this.goal, super.key});
  final Goal goal;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(goal.title),
      subtitle: LinearProgressIndicator(value: goal.progress),
    ),
  );
}
