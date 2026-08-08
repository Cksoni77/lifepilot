import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/habit_service.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_statistics.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({required this.userId, super.key});

  final String userId;

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  late final HabitService _habitService = HabitService(userId: widget.userId);
  List<Habit> _habits = <Habit>[];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      final habits = await _habitService.loadHabits();
      if (!mounted) return;
      setState(() {
        _habits = habits;
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'We could not load your habits. Please try again.';
      });
    }
  }

  Future<void> _showAddHabitDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var frequency = HabitFrequency.daily;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New habit'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Habit name',
                    hintText: 'e.g. Read for 30 minutes',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Give your habit a name'
                      : null,
                ),
                TextField(
                  controller: descriptionController,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<HabitFrequency>(
                  initialValue: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: HabitFrequency.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => frequency = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Create habit'),
            ),
          ],
        ),
      ),
    );
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    nameController.dispose();
    descriptionController.dispose();
    if (shouldSave != true || name.isEmpty) return;

    final habit = Habit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      description: description,
      frequency: frequency,
    );
    final updatedHabits = [..._habits, habit];
    try {
      await _habitService.saveHabits(updatedHabits);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this habit. Please try again.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _habits = updatedHabits;
      _loadError = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${habit.name} added to your habits.')),
    );
  }

  Future<void> _toggleToday(Habit habit) async {
    habit.setCompletedOn(DateTime.now(), !habit.isCompletedOn(DateTime.now()));
    try {
      await _habitService.saveHabits(_habits);
    } catch (_) {
      habit.setCompletedOn(
        DateTime.now(),
        !habit.isCompletedOn(DateTime.now()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update this habit. Please try again.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final activeHabits = _habits.where((habit) => habit.isActive).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Tracker')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHabitDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add habit'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Build consistency one day at a time.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                HabitStatistics(habits: _habits),
                const SizedBox(height: 16),
                if (_loadError != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 40),
                          const SizedBox(height: 8),
                          Text(_loadError!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _loadHabits,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (activeHabits.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No habits yet. Add your first daily routine.',
                      ),
                    ),
                  )
                else
                  ...activeHabits.map(
                    (habit) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: HabitCard(
                        habit: habit,
                        onToggleToday: () => _toggleToday(habit),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
