import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _range = 'Week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Week', label: Text('Week')),
              ButtonSegment(value: 'Month', label: Text('Month')),
              ButtonSegment(value: 'Year', label: Text('Year')),
            ],
            selected: {_range},
            onSelectionChanged: (value) => setState(() => _range = value.first),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Task completion',
                  value: '82%',
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Best streak',
                  value: '🔥 6',
                  color: AppColors.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _WeeklyChart(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentPurpleTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, color: AppColors.accentPurple),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You\'re most productive Thursday mornings - consider scheduling deep work then.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart();

  @override
  Widget build(BuildContext context) {
    const values = [.48, .72, .58, .95, .78, .36, .62];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasks completed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final value in values)
                    Container(
                      width: 24,
                      height: 110 * value,
                      decoration: BoxDecoration(
                        color: value == .95
                            ? AppColors.primary
                            : AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('M'),
                Text('T'),
                Text('W'),
                Text('T'),
                Text('F'),
                Text('S'),
                Text('S'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
