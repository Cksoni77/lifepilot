import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'add_task_sheet.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({required this.userId, super.key});
  final String userId;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _searchController = TextEditingController();
  final tasks = <Task>[
    Task(
      id: 'report',
      title: 'Finish Q3 report',
      description: 'Work · Today · 5:00 PM',
      priority: TaskPriority.high,
      dueDate: _todayAt(17),
    ),
    Task(
      id: 'bill',
      title: 'Pay electricity bill',
      description: 'Finance · Today',
      priority: TaskPriority.medium,
      dueDate: _todayAt(18),
    ),
    Task(
      id: 'dentist',
      title: 'Book dentist appointment',
      description: 'Health · Tomorrow',
      priority: TaskPriority.low,
      dueDate: _todayAt(17).add(const Duration(days: 1)),
    ),
    Task(
      id: 'grocery',
      title: 'Grocery shopping',
      description: 'Personal · Overdue',
      priority: TaskPriority.low,
      dueDate: _todayAt(10).subtract(const Duration(days: 1)),
    ),
  ];
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    TaskService(userId: widget.userId).loadTasks().then((loaded) {
      if (mounted && loaded.isNotEmpty) {
        setState(() {
          tasks
            ..clear()
            ..addAll(loaded);
        });
      }
    });
  }

  Future<void> _addTask() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTaskSheet(
        onCreate: (_) {},
        onCreateDetails: (title, category, priority) {
          setState(
            () => tasks.insert(
              0,
              Task(
                id: DateTime.now().toIso8601String(),
                title: title,
                description: '$category · Today',
                priority: priority,
                dueDate: _todayAt(17),
              ),
            ),
          );
          TaskService(userId: widget.userId).saveTasks(tasks);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Tasks'),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.tune),
          tooltip: 'Filter',
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search tasks',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Today', 'Overdue', 'Done']
                .map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$filter · ${_countFor(filter)}'),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        ..._visibleTasks.map(_taskCard),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _addTask,
      child: const Icon(Icons.add),
    ),
  );

  List<Task> get _visibleTasks {
    final query = _searchController.text.trim().toLowerCase();
    return tasks.where((task) {
      final matchesSearch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);
      if (!matchesSearch) return false;
      return switch (_filter) {
        'Today' => task.status() == TaskStatus.dueToday,
        'Overdue' => task.status() == TaskStatus.overdue,
        'Done' => task.completed,
        _ => true,
      };
    }).toList();
  }

  int _countFor(String filter) => tasks.where((task) {
    return switch (filter) {
      'Today' => task.status() == TaskStatus.dueToday,
      'Overdue' => task.status() == TaskStatus.overdue,
      'Done' => task.completed,
      _ => true,
    };
  }).length;

  Widget _taskCard(Task task) => Card(
    child: CheckboxListTile(
      value: task.completed,
      onChanged: (value) {
        setState(() => task.completed = value ?? false);
        TaskService(userId: widget.userId).saveTasks(tasks);
      },
      secondary: CircleAvatar(
        backgroundColor: _priorityTint(task.priority),
        child: Icon(
          Icons.work_outline,
          color: _priorityColor(task.priority),
          size: 18,
        ),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          decoration: task.completed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(task.description),
      controlAffinity: ListTileControlAffinity.leading,
      side: BorderSide.none,
    ),
  );

  Color _priorityColor(TaskPriority priority) => switch (priority) {
    TaskPriority.high => AppColors.danger,
    TaskPriority.medium => AppColors.warning,
    TaskPriority.low => AppColors.primary,
  };
  Color _priorityTint(TaskPriority priority) => switch (priority) {
    TaskPriority.high => const Color(0xFFFDE8E8),
    TaskPriority.medium => const Color(0xFFFFF3DC),
    TaskPriority.low => AppColors.primaryTint,
  };
}

DateTime _todayAt(int hour) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour);
}
