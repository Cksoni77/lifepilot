import 'package:flutter/material.dart';

import '../../notifications/services/notification_service.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'add_task_sheet.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({
    required this.userId,
    this.initialFilter = 'All',
    super.key,
  });

  final String userId;
  final String initialFilter;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final TaskService _taskService;

  final _searchController = TextEditingController();

  final List<Task> tasks = [];

  late String _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;

    _taskService = TaskService(userId: widget.userId);

    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final loaded = await _taskService.loadTasks();

    if (!mounted) {
      return;
    }

    setState(() {
      tasks
        ..clear()
        ..addAll(loaded);
    });
  }

  // --------------------------------------------------
  // ADD TASK
  // --------------------------------------------------

  Future<void> _addTask() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return AddTaskSheet(onCreate: _createTask);
      },
    );
  }

  Future<void> _createTask(Task task) async {
    setState(() {
      tasks.insert(0, task);
    });

    await _taskService.addTask(task);

    if (task.hasReminder) {
      await NotificationService.instance.scheduleReminder(task);
    }
  }

  Future<void> _editTask(Task task) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTaskSheet(
        task: task,
        onCreate: (updatedTask) async {
          await _taskService.updateTask(updatedTask);
          if (updatedTask.hasReminder) {
            await NotificationService.instance.scheduleReminder(updatedTask);
          } else {
            await NotificationService.instance.cancelReminder(updatedTask);
          }
          if (!mounted) return;
          final index = tasks.indexWhere((item) => item.id == updatedTask.id);
          if (index >= 0) setState(() => tasks[index] = updatedTask);
        },
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be permanently removed.'),
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

    await _taskService.deleteTask(task.id);
    if (task.hasReminder) {
      await NotificationService.instance.cancelReminder(task);
    }
    if (!mounted) return;
    setState(() => tasks.removeWhere((item) => item.id == task.id));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task deleted')));
  }

  // --------------------------------------------------
  // COMPLETE TASK
  // --------------------------------------------------

  Future<void> _toggleTask(Task task, bool completed) async {
    setState(() {
      task.completed = completed;

      task.completedAt = completed ? DateTime.now() : null;
    });

    await _taskService.updateTask(task);

    if (completed) {
      await NotificationService.instance.cancelReminder(task);
    } else if (task.hasReminder) {
      await NotificationService.instance.scheduleReminder(task);
    }
  }

  // --------------------------------------------------
  // SEARCH / FILTER
  // --------------------------------------------------

  List<Task> get _visibleTasks {
    final query = _searchController.text.trim().toLowerCase();

    return tasks.where((task) {
      final matchesSearch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.category.label.toLowerCase().contains(query);

      if (!matchesSearch) {
        return false;
      }

      return switch (_filter) {
        'Today' => task.status() == TaskStatus.dueToday,

        'Overdue' => task.status() == TaskStatus.overdue,

        'Done' => task.completed,

        _ => true,
      };
    }).toList();
  }

  int _countFor(String filter) {
    return tasks.where((task) {
      return switch (filter) {
        'Today' => task.status() == TaskStatus.dueToday,

        'Overdue' => task.status() == TaskStatus.overdue,

        'Done' => task.completed,

        _ => true,
      };
    }).length;
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) {
              setState(() {});
            },
            decoration: const InputDecoration(
              hintText: 'Search tasks',
              prefixIcon: Icon(Icons.search),
            ),
          ),

          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Today', 'Overdue', 'Done'].map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$filter · ${_countFor(filter)}'),
                    selected: _filter == filter,
                    onSelected: (_) {
                      setState(() {
                        _filter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          if (_visibleTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.checklist_outlined,
                      size: 52,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    const Text('No tasks found'),
                  ],
                ),
              ),
            ),

          ..._visibleTasks.map(_taskCard),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  // --------------------------------------------------
  // TASK CARD
  // --------------------------------------------------

  Widget _taskCard(Task task) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged: (value) => _toggleTask(task, value ?? false),
          semanticLabel:
              'Mark ${task.title} ${task.completed ? 'incomplete' : 'complete'}',
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            decoration: task.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(_taskSubtitle(task)),
        onTap: () => _editTask(task),
        trailing: PopupMenuButton<String>(
          tooltip: 'Task actions',
          onSelected: (action) {
            if (action == 'edit') _editTask(task);
            if (action == 'delete') _deleteTask(task);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // SUBTITLE
  // --------------------------------------------------

  String _taskSubtitle(Task task) {
    final parts = <String>[
      task.category.label,
      '${task.priority.label} priority',
    ];

    if (task.statusLabel.isNotEmpty) {
      parts.add(task.statusLabel);
    } else if (task.dueDate != null) {
      parts.add(_formatDueDate(task.dueDate!));
    }

    if (task.estimatedMinutes != null) {
      parts.add('${task.estimatedMinutes} min');
    }

    return parts.join(' · ');
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final tomorrow = today.add(const Duration(days: 1));

    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    }

    if (dateOnly == tomorrow) {
      return 'Tomorrow';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
