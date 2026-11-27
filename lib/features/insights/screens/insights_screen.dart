import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../habits/models/habit.dart';
import '../../habits/services/habit_service.dart';
import '../../tasks/models/task.dart';
import '../../tasks/services/task_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({required this.userId, super.key});

  final String userId;

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _range = 'Week';
  List<Task> _tasks = [];
  List<Habit> _habits = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final tasks = await TaskService(userId: widget.userId).loadTasks();
      final habits = await HabitService(userId: widget.userId).loadHabits();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _habits = habits;
        _loadError = null;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _isLoading = false;
      });
    }
  }

  DateTime get _rangeStart {
    final today = _dateOnly(DateTime.now());
    return switch (_range) {
      'Month' => today.subtract(const Duration(days: 29)),
      'Year' => today.subtract(const Duration(days: 364)),
      _ => today.subtract(const Duration(days: 6)),
    };
  }

  List<Task> get _rangeTasks =>
      _tasks.where((task) => !task.createdAt.isBefore(_rangeStart)).toList();

  int get _completedCount => _rangeTasks.where((task) => task.completed).length;

  int get _bestStreak => _habits.fold<int>(
    0,
    (best, habit) =>
        habit.longestStreak() > best ? habit.longestStreak() : best,
  );

  List<_ChartBucket> get _chartBuckets {
    final now = _dateOnly(DateTime.now());
    if (_range == 'Year') {
      return List.generate(12, (index) {
        final month = DateTime(now.year, now.month - 11 + index);
        final count = _tasks.where((task) {
          final completedAt = task.completedAt;
          return task.completed &&
              completedAt != null &&
              completedAt.year == month.year &&
              completedAt.month == month.month;
        }).length;
        return _ChartBucket(_monthAbbreviation(month.month), count);
      });
    }
    if (_range == 'Month') {
      return List.generate(4, (index) {
        final start = now.subtract(Duration(days: (3 - index) * 7 + 6));
        final end = start.add(const Duration(days: 7));
        final count = _completedBetween(start, end);
        return _ChartBucket('W${index + 1}', count);
      });
    }
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final nextDay = date.add(const Duration(days: 1));
      return _ChartBucket(
        const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1],
        _completedBetween(date, nextDay),
      );
    });
  }

  int _completedBetween(DateTime start, DateTime end) => _tasks.where((task) {
    final completedAt = task.completedAt;
    return task.completed &&
        completedAt != null &&
        !completedAt.isBefore(start) &&
        completedAt.isBefore(end);
  }).length;

  @override
  Widget build(BuildContext context) {
    final completionRate = _rangeTasks.isEmpty
        ? 0
        : _completedCount / _rangeTasks.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Week', label: Text('Week')),
                    ButtonSegment(value: 'Month', label: Text('Month')),
                    ButtonSegment(value: 'Year', label: Text('Year')),
                  ],
                  selected: {_range},
                  onSelectionChanged: (value) =>
                      setState(() => _range = value.first),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Task completion',
                        value: '${(completionRate * 100).round()}%',
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        label: 'Best streak',
                        value: '$_bestStreak days',
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CompletionChart(buckets: _chartBuckets),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.insights_outlined, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _rangeTasks.isEmpty
                              ? 'Complete tasks and build habits to see patterns here.'
                              : 'You completed $_completedCount of ${_rangeTasks.length} tasks in this period. Insights are based on your saved activity.',
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

class _ChartBucket {
  const _ChartBucket(this.label, this.count);
  final String label;
  final int count;
}

class _CompletionChart extends StatelessWidget {
  const _CompletionChart({required this.buckets});

  final List<_ChartBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxCount = buckets.fold<int>(
      1,
      (maximum, bucket) => bucket.count > maximum ? bucket.count : maximum,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completed tasks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 150,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: buckets.length * 38,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: buckets
                        .map(
                          (bucket) => SizedBox(
                            width: 38,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${bucket.count}',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 20,
                                  height: 100 * bucket.count / maxCount,
                                  decoration: BoxDecoration(
                                    color: bucket.count == 0
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest
                                        : AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  bucket.label,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _monthAbbreviation(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];
