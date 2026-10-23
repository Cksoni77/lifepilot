import 'package:flutter/material.dart';

class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({required this.values, super.key});
  final List<double> values;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: values
        .map(
          (value) => Container(
            width: 18,
            height: 100 * value.clamp(0, 1),
            color: Theme.of(context).colorScheme.primary,
          ),
        )
        .toList(),
  );
}
