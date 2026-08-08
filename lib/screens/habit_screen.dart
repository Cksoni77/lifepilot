import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/habit_service.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_statistics.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final HabitService _habitService = HabitService();
  List<Habit> _habits = <Habit>[];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await _habitService.loadHabits();
    if (!mounted) return;
    setState(() => _habits = habits);
  }

  Future<void> _showAddHabitDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    var frequency = HabitFrequency.daily;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Habit name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HabitFrequency>(
                initialValue: frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: HabitFrequency.values
                    .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => frequency = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Create habit')),
          ],
        ),
      ),
    );
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
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
    await _habitService.saveHabits(updatedHabits);
    if (!mounted) return;
    setState(() => _habits = updatedHabits);
  }

  Future<void> _toggleToday(Habit habit) async {
    habit.setCompletedOn(DateTime.now(), !habit.isCompletedOn(DateTime.now()));
    await _habitService.saveHabits(_habits);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Tracker')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHabitDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add habit'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Build consistency one day at a time.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          HabitStatistics(habits: _habits),
          const SizedBox(height: 16),
          if (_habits.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No habits yet. Add your first daily routine.'),
              ),
            )
          else
            ..._habits.where((habit) => habit.isActive).map(
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
