import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({required this.userId, super.key});
  final String userId;

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final habits = <Habit>[
    Habit(id: 'exercise', name: 'Exercise'),
    Habit(id: 'water', name: 'Drink water'),
    Habit(id: 'read', name: 'Read 20 min'),
  ];
  final completed = <String>{'exercise', 'water'};

  Future<void> _addHabit() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddHabitDialog(),
    );
    if (!mounted || name == null) {
      return;
    }
    final habit = Habit(id: DateTime.now().toIso8601String(), name: name);
    setState(() => habits.add(habit));
    await HabitService(userId: widget.userId).saveHabits(habits);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(name), Text('$name added to your habits.')],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Habit Tracker')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        Text(
          'Build consistency one day at a time.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        const _HabitStats(),
        const SizedBox(height: 16),
        ...habits.map(_habitCard),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _addHabit,
      icon: const Icon(Icons.add),
      label: const Text('Add habit'),
    ),
  );

  Widget _habitCard(Habit habit) {
    final isDone = completed.contains(habit.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  habit.id == 'water'
                      ? Icons.water_drop_outlined
                      : habit.id == 'read'
                      ? Icons.book_outlined
                      : Icons.local_fire_department_outlined,
                  color: habit.id == 'read'
                      ? AppColors.accentPurple
                      : habit.id == 'water'
                      ? AppColors.primary
                      : AppColors.accentOrange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        habit.id == 'water'
                            ? '8 glasses a day'
                            : habit.id == 'read'
                            ? 'Before bed'
                            : 'Every day',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(
                    () => isDone
                        ? completed.remove(habit.id)
                        : completed.add(habit.id),
                  ),
                  icon: Icon(isDone ? Icons.check : Icons.circle_outlined),
                  tooltip: isDone ? 'Mark incomplete' : 'Mark complete',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Daily · Current ${isDone ? 3 : 0}d · Best 5d',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
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
              value: isDone ? .67 : .05,
              color: AppColors.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitStats extends StatelessWidget {
  const _HabitStats();

  @override
  Widget build(BuildContext context) => Card(
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
          const Row(
            children: [
              Expanded(
                child: _Stat(label: 'Total habits', value: '3'),
              ),
              Expanded(
                child: _Stat(label: 'Completed today', value: '2/3'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Completion rate',
                  value: '67%',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _Stat(label: 'Current streak', value: '🔥 3 days'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
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

class _AddHabitDialog extends StatefulWidget {
  const _AddHabitDialog();
  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add habit'),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Habit name'),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Give your habit a name'
            : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pop(context, _controller.text.trim());
          }
        },
        child: const Text('Create habit'),
      ),
    ],
  );
}
