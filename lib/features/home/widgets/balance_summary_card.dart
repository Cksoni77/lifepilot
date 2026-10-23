import 'package:flutter/material.dart';

class BalanceSummaryCard extends StatelessWidget {
  const BalanceSummaryCard({
    required this.completed,
    required this.total,
    super.key,
  });
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: const Text('Today\'s balance'),
      subtitle: Text('$completed of $total tasks complete'),
    ),
  );
}
