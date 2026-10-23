import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../notifications/services/notification_service.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'add_task_sheet.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  State<TaskListScreen> createState() =>
      _TaskListScreenState();
}

class _TaskListScreenState
    extends State<TaskListScreen> {
  late final TaskService _taskService;

  final _searchController =
      TextEditingController();

  final List<Task> tasks = [];

  String _filter = 'All';

  @override
  void initState() {
    super.initState();

    _taskService = TaskService(
      userId: widget.userId,
    );

    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final loaded =
        await _taskService.loadTasks();

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
        return AddTaskSheet(
          onCreate: _createTask,
        );
      },
    );
  }

  Future<void> _createTask(
    Task task,
  ) async {
    setState(() {
      tasks.insert(0, task);
    });

    await _taskService.addTask(task);

    if (task.hasReminder) {
      await NotificationService.instance
          .scheduleReminder(task);
    }
  }

  // --------------------------------------------------
  // COMPLETE TASK
  // --------------------------------------------------

  Future<void> _toggleTask(
    Task task,
    bool completed,
  ) async {
    setState(() {
      task.completed = completed;

      task.completedAt =
          completed ? DateTime.now() : null;
    });

    await _taskService.updateTask(task);

    if (completed) {
      await NotificationService.instance
          .cancelReminder(task);
    } else if (task.hasReminder) {
      await NotificationService.instance
          .scheduleReminder(task);
    }
  }

  // --------------------------------------------------
  // SEARCH / FILTER
  // --------------------------------------------------

  List<Task> get _visibleTasks {
    final query =
        _searchController.text
            .trim()
            .toLowerCase();

    return tasks.where((task) {
      final matchesSearch =
          query.isEmpty ||
          task.title
              .toLowerCase()
              .contains(query) ||
          task.description
              .toLowerCase()
              .contains(query) ||
          task.category.label
              .toLowerCase()
              .contains(query);

      if (!matchesSearch) {
        return false;
      }

      return switch (_filter) {
        'Today' =>
          task.status() ==
              TaskStatus.dueToday,

        'Overdue' =>
          task.status() ==
              TaskStatus.overdue,

        'Done' =>
          task.completed,

        _ => true,
      };
    }).toList();
  }

  int _countFor(
    String filter,
  ) {
    return tasks.where((task) {
      return switch (filter) {
        'Today' =>
          task.status() ==
              TaskStatus.dueToday,

        'Overdue' =>
          task.status() ==
              TaskStatus.overdue,

        'Done' =>
          task.completed,

        _ => true,
      };
    }).length;
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.tune,
            ),
            tooltip: 'Filter',
          ),
        ],
      ),

      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          100,
        ),
        children: [
          TextField(
            controller:
                _searchController,
            onChanged: (_) {
              setState(() {});
            },
            decoration:
                const InputDecoration(
              hintText:
                  'Search tasks',
              prefixIcon:
                  Icon(Icons.search),
            ),
          ),

          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection:
                Axis.horizontal,
            child: Row(
              children: [
                'All',
                'Today',
                'Overdue',
                'Done',
              ].map((filter) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    right: 8,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      '$filter · ${_countFor(filter)}',
                    ),
                    selected:
                        _filter == filter,
                    onSelected: (_) {
                      setState(() {
                        _filter =
                            filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          if (_visibleTasks.isEmpty)
            const Padding(
              padding:
                  EdgeInsets.only(
                top: 80,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons
                          .checklist_outlined,
                      size: 52,
                      color:
                          AppColors
                              .textSecondary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No tasks found',
                    ),
                  ],
                ),
              ),
            ),

          ..._visibleTasks.map(
            _taskCard,
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: _addTask,
        child:
            const Icon(Icons.add),
      ),
    );
  }

  // --------------------------------------------------
  // TASK CARD
  // --------------------------------------------------

  Widget _taskCard(
    Task task,
  ) {
    return Card(
      child: CheckboxListTile(
        value: task.completed,

        onChanged: (value) {
          _toggleTask(
            task,
            value ?? false,
          );
        },

        secondary: CircleAvatar(
          backgroundColor:
              _priorityTint(
            task.priority,
          ),
          child: Icon(
            _categoryIcon(
              task.category,
            ),
            color:
                _priorityColor(
              task.priority,
            ),
            size: 18,
          ),
        ),

        title: Text(
          task.title,
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
            decoration:
                task.completed
                    ? TextDecoration
                        .lineThrough
                    : null,
          ),
        ),

        subtitle: Text(
          _taskSubtitle(task),
        ),

        controlAffinity:
            ListTileControlAffinity
                .leading,

        side: BorderSide.none,
      ),
    );
  }

  // --------------------------------------------------
  // SUBTITLE
  // --------------------------------------------------

  String _taskSubtitle(
    Task task,
  ) {
    final parts = <String>[
      task.category.label,
    ];

    if (task.statusLabel.isNotEmpty) {
      parts.add(
        task.statusLabel,
      );
    } else if (task.dueDate != null) {
      parts.add(
        _formatDueDate(
          task.dueDate!,
        ),
      );
    }

    if (task.estimatedMinutes !=
        null) {
      parts.add(
        '${task.estimatedMinutes} min',
      );
    }

    return parts.join(' · ');
  }

  String _formatDueDate(
    DateTime date,
  ) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final tomorrow =
        today.add(
      const Duration(days: 1),
    );

    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (dateOnly == today) {
      return 'Today';
    }

    if (dateOnly == tomorrow) {
      return 'Tomorrow';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // --------------------------------------------------
  // CATEGORY ICON
  // --------------------------------------------------

  IconData _categoryIcon(
    TaskCategory category,
  ) {
    switch (category) {
      case TaskCategory.personal:
        return Icons.home_work_outlined;

      case TaskCategory.work:
        return Icons.work_outline;

      case TaskCategory.health:
        return Icons.favorite_border;

      case TaskCategory.finance:
        return Icons
            .account_balance_wallet_outlined;
    }
  }

  // --------------------------------------------------
  // PRIORITY COLORS
  // --------------------------------------------------

  Color _priorityColor(
    TaskPriority priority,
  ) {
    return switch (priority) {
      TaskPriority.high =>
        AppColors.danger,

      TaskPriority.medium =>
        AppColors.warning,

      TaskPriority.low =>
        AppColors.primary,
    };
  }

  Color _priorityTint(
    TaskPriority priority,
  ) {
    return switch (priority) {
      TaskPriority.high =>
        const Color(0xFFFDE8E8),

      TaskPriority.medium =>
        const Color(0xFFFFF3DC),

      TaskPriority.low =>
        AppColors.primaryTint,
    };
  }
}