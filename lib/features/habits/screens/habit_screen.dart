import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import 'habit_form_sheet.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({required this.userId, super.key});
  final String userId;

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final habits = <Habit>[];
  late final HabitService _habitService;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _habitService = HabitService(userId: widget.userId);
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final loaded = await _habitService.loadHabits();
      if (!mounted) return;
      setState(() {
        habits
          ..clear()
          ..addAll(loaded);
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

  Future<void> _addHabit() async {
    Habit? savedHabit;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => HabitFormSheet(
        onSave: (habit) async {
          await _habitService.addHabit(habit);
          savedHabit = habit;
          if (mounted) setState(() => habits.add(habit));
        },
      ),
    );
    if (mounted && savedHabit != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${savedHabit!.name} added to your habits.')),
      );
    }
  }

  Future<void> _toggleToday(Habit habit) async {
    final today = _dateOnly(DateTime.now());
    final isDone = habit.completedDates.any((date) => _sameDay(date, today));
    bool changed;
    try {
      changed = isDone
          ? await _habitService.undoCompletion(habit.id, today)
          : await _habitService.markCompleted(habit.id, today);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    }
    if (!mounted) return;
    if (!changed && !isDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This habit is not scheduled for today.')),
      );
      return;
    }
    await _loadHabits();
  }

  Future<void> _editHabit(Habit habit) async {
    Habit? updatedHabit;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => HabitFormSheet(
        habit: habit,
        onSave: (updated) async {
          await _habitService.updateHabit(updated);
          updatedHabit = updated;
          if (!mounted) return;
          final index = habits.indexWhere((item) => item.id == updated.id);
          if (index >= 0) setState(() => habits[index] = updated);
        },
      ),
    );
    if (mounted && updatedHabit != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${updatedHabit!.name} updated.')));
    }
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          '"${habit.name}" and its completion history will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _habitService.deleteHabit(habit.id);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    }
    if (!mounted) return;
    setState(() => habits.removeWhere((item) => item.id == habit.id));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${habit.name} deleted.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Habit Tracker')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        Text(
          'Build consistency one day at a time.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_loadError != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(_loadError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _loadHabits,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          _HabitStats(habits: habits),
          const SizedBox(height: 16),
          if (habits.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No habits yet. Add one to start tracking your consistency.',
                ),
              ),
            )
          else
            ...habits.map(_habitCard),
        ],
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _addHabit,
      icon: const Icon(Icons.add),
      label: const Text('Add habit'),
    ),
  );

  Widget _habitCard(Habit habit) {
    final today = _dateOnly(DateTime.now());
    final isDone = habit.completedDates.any((date) => _sameDay(date, today));
    final canComplete =
        isDone ||
        (!today.isBefore(habit.startDate) && habit.isScheduledOn(today));
    final weekDates = List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
    final weekCount = weekDates
        .where(
          (date) => habit.completedDates.any((done) => _sameDay(done, date)),
        )
        .length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.track_changes_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _frequencySummary(habit),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Habit actions',
                  onSelected: (action) {
                    if (action == 'edit') _editHabit(habit);
                    if (action == 'delete') _deleteHabit(habit);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                IconButton(
                  onPressed: canComplete ? () => _toggleToday(habit) : null,
                  icon: Icon(
                    isDone ? Icons.check_circle : Icons.circle_outlined,
                  ),
                  tooltip: isDone
                      ? 'Mark incomplete'
                      : canComplete
                      ? 'Mark complete'
                      : 'Not scheduled today',
                ),
              ],
            ),
            if (habit.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  habit.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                [
                  habit.category.label,
                  if (habit.targetDuration != null)
                    '${_displayDuration(habit.targetDuration!)} ${habit.durationUnit.label.toLowerCase()}',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Current ${habit.currentStreak()}d · Best ${habit.longestStreak()}d',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  isDone ? 'On track' : 'To do',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: weekCount / 7,
              color: AppColors.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final date in weekDates)
                  CircleAvatar(
                    radius: 11,
                    backgroundColor:
                        habit.completedDates.any((done) => _sameDay(done, date))
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Text(
                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            habit.completedDates.any(
                              (done) => _sameDay(done, date),
                            )
                            ? Colors.white
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitStats extends StatelessWidget {
  const _HabitStats({required this.habits});

  final List<Habit> habits;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final completedToday = habits
        .where(
          (habit) => habit.completedDates.any((date) => _sameDay(date, today)),
        )
        .length;
    final bestActiveStreak = habits.fold<int>(
      0,
      (longest, habit) =>
          habit.currentStreak() > longest ? habit.currentStreak() : longest,
    );
    final completionRate = habits.isEmpty
        ? 0.0
        : completedToday / habits.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habit statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Total habits',
                    value: '${habits.length}',
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Completed today',
                    value: '$completedToday/${habits.length}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Completion rate',
                    value: '${(completionRate * 100).round()}%',
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Best active streak',
                    value: '$bestActiveStreak days',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
      ),
    ],
  );
}

String _frequencySummary(Habit habit) {
  if (habit.frequency != HabitFrequency.customDays) {
    return habit.frequency.label;
  }
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return habit.selectedWeekdays.map((day) => weekdays[day - 1]).join(', ');
}

String _displayDuration(double duration) => duration == duration.roundToDouble()
    ? duration.toInt().toString()
    : '$duration';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
