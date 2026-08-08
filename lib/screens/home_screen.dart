import 'package:flutter/material.dart';

import '../models/task.dart';
import 'calendar_screen.dart';
import 'habit_screen.dart';
import 'profile_screen.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';
import '../widgets/task_card.dart';

enum _TaskFilter { all, completed, pending, overdue, dueToday, highPriority }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Task> _tasks = [];
  final TextEditingController _taskController = TextEditingController();
  final TaskService _taskService = TaskService();
  String _selectedCategory = Task.defaultCategory;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDueDate;
  DateTime? _selectedReminderDate;
  bool _sortByPriority = false;
  String _searchQuery = '';
  _TaskFilter _activeFilter = _TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  bool _matchesFilter(Task task) {
    switch (_activeFilter) {
      case _TaskFilter.all:
        return true;
      case _TaskFilter.completed:
        return task.completed;
      case _TaskFilter.pending:
        return !task.completed;
      case _TaskFilter.overdue:
        return task.status() == TaskStatus.overdue;
      case _TaskFilter.dueToday:
        return task.status() == TaskStatus.dueToday;
      case _TaskFilter.highPriority:
        return task.priority == TaskPriority.high;
    }
  }

  String _filterLabel(_TaskFilter filter) {
    switch (filter) {
      case _TaskFilter.all:
        return 'All';
      case _TaskFilter.completed:
        return 'Completed';
      case _TaskFilter.pending:
        return 'Pending';
      case _TaskFilter.overdue:
        return 'Overdue';
      case _TaskFilter.dueToday:
        return 'Due Today';
      case _TaskFilter.highPriority:
        return 'High Priority';
    }
  }

  Future<void> _loadTasks() async {
    final loadedTasks = await _taskService.loadTasks();
    if (!mounted) {
      return;
    }

    setState(() {
      _tasks
        ..clear()
        ..addAll(loadedTasks);
    });
  }

  Future<void> _addTask() async {
    final newTaskTitle = _taskController.text.trim();
    if (newTaskTitle.isEmpty) return;

    final task = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: newTaskTitle,
      category: _selectedCategory,
      priority: _selectedPriority,
      dueDate: _selectedDueDate,
      reminderDate: _selectedReminderDate,
      reminderEnabled: _selectedReminderDate != null,
    );

    final updatedTasks = [..._tasks, task];
    await _taskService.saveTasks(updatedTasks);
    await NotificationService.instance.scheduleReminder(task);

    if (!mounted) return;
    setState(() {
      _tasks = updatedTasks;
      _taskController.clear();
      _selectedDueDate = null;
      _selectedReminderDate = null;
    });
  }

  Future<void> _toggleTaskCompletion(int index, bool? value) async {
    _tasks[index].completed = value ?? false;
    final updatedTasks = [..._tasks];
    await _taskService.saveTasks(updatedTasks);
    if (value == true) {
      await NotificationService.instance.cancelReminder(updatedTasks[index]);
    } else if (updatedTasks[index].reminderDate != null) {
      await NotificationService.instance.scheduleReminder(updatedTasks[index]);
    }

    if (!mounted) return;
    setState(() {
      _tasks = updatedTasks;
    });
  }

  Future<void> _deleteTask(int index) async {
    final updatedTasks = _tasks
        .where((t) => _tasks.indexOf(t) != index)
        .toList();
    await _taskService.saveTasks(updatedTasks);

    if (!mounted) return;
    setState(() {
      _tasks = updatedTasks;
    });
  }

  Future<void> _editTask(Task task) async {
    final titleController = TextEditingController(text: task.title);
    var category = task.category;
    var priority = task.priority;
    var dueDate = task.dueDate;
    var reminderDate = task.reminderDate;
    var reminderEnabled = task.reminderEnabled && reminderDate != null;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: Task.supportedCategories
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => category = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: TaskPriority.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => priority = value);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                    dueDate == null
                        ? 'No due date'
                        : 'Due: ${_formatDate(dueDate!)}',
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setDialogState(() => dueDate = picked);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reminder'),
                  subtitle: reminderDate == null
                      ? const Text('No reminder set')
                      : Text(_formatReminder(reminderDate!)),
                  value: reminderEnabled,
                  onChanged: (value) async {
                    if (value && reminderDate == null) {
                      final picked = await _pickReminderDateForDialog(
                        context,
                        null,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          reminderDate = picked;
                          reminderEnabled = true;
                        });
                      }
                    } else {
                      setDialogState(() => reminderEnabled = value);
                    }
                  },
                ),
                if (reminderEnabled)
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await _pickReminderDateForDialog(
                        context,
                        reminderDate,
                      );
                      if (picked != null) {
                        setDialogState(() => reminderDate = picked);
                      }
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Change reminder time'),
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
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );

    final title = titleController.text.trim();
    titleController.dispose();
    if (shouldSave != true || title.isEmpty) return;
    final updatedTask = Task(
      id: task.id,
      title: title,
      completed: task.completed,
      category: category,
      priority: priority,
      dueDate: dueDate,
      reminderDate: reminderEnabled ? reminderDate : null,
      reminderEnabled: reminderEnabled,
    );
    final taskIndex = _tasks.indexWhere((item) => item.id == task.id);
    if (taskIndex == -1) return;
    final updatedTasks = [..._tasks]..[taskIndex] = updatedTask;
    await _taskService.saveTasks(updatedTasks);
    await NotificationService.instance.cancelReminder(task);
    if (updatedTask.reminderEnabled) {
      await NotificationService.instance.scheduleReminder(updatedTask);
    }
    if (!mounted) return;
    setState(() => _tasks = updatedTasks);
  }

  Future<DateTime?> _pickReminderDateForDialog(
    BuildContext dialogContext,
    DateTime? current,
  ) async {
    final pickedDate = await showDatePicker(
      context: dialogContext,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !dialogContext.mounted) return null;
    final pickedTime = await showTimePicker(
      context: dialogContext,
      initialTime: TimeOfDay.fromDateTime(current ?? DateTime.now()),
    );
    if (pickedTime == null) return null;
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _formatReminder(DateTime date) =>
      '${_formatDate(date)} ${TimeOfDay.fromDateTime(date).format(context)}';

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (!mounted) {
      return;
    }

    if (pickedDate != null) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
    }
  }

  Future<void> _pickReminderDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedReminderDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (!mounted || pickedDate == null) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _selectedReminderDate ?? DateTime.now(),
      ),
    );

    if (!mounted || pickedTime == null) {
      return;
    }

    setState(() {
      _selectedReminderDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  List<Task> get _sortedTasks {
    final query = _searchQuery.trim().toLowerCase();
    final sortedTasks = _tasks.where((task) {
      final searchableText = '${task.title} ${task.category}'.toLowerCase();
      return (query.isEmpty || searchableText.contains(query)) &&
          _matchesFilter(task);
    }).toList();
    if (_sortByPriority) {
      sortedTasks.sort((a, b) {
        final priorityOrder = {
          TaskPriority.high: 0,
          TaskPriority.medium: 1,
          TaskPriority.low: 2,
        };
        return (priorityOrder[a.priority] ?? 3).compareTo(
          priorityOrder[b.priority] ?? 3,
        );
      });
    }
    return sortedTasks;
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = _tasks.where((task) => task.completed).length;
    final pendingTasks = _tasks.length - completedTasks;
    final overdueTasks = _tasks
        .where((task) => task.status() == TaskStatus.overdue)
        .length;
    final dueTodayTasks = _tasks
        .where((task) => task.status() == TaskStatus.dueToday)
        .length;
    final highPriorityTasks = _tasks
        .where((task) => task.priority == TaskPriority.high && !task.completed)
        .length;
    final completionRate = _tasks.isEmpty
        ? 0.0
        : completedTasks / _tasks.length;
    final displayedTasks = _sortedTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LifePilot'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const CalendarScreen()),
            ),
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Calendar',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const HabitScreen()),
            ),
            icon: const Icon(Icons.track_changes_outlined),
            tooltip: 'Habit tracker',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Form section - scrollable
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Good Morning 👋',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Total Tasks: ${_tasks.length}'),
                    Text('Completed: $completedTasks/${_tasks.length}'),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Productivity',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 20,
                              runSpacing: 8,
                              children: [
                                Text('Total\n${_tasks.length}'),
                                Text('Completed\n$completedTasks'),
                                Text('Pending\n$pendingTasks'),
                                Text('Overdue\n$overdueTasks'),
                                Text('High Priority\n$highPriorityTasks'),
                                Text('Due Today\n$dueTodayTasks'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(value: completionRate),
                            const SizedBox(height: 4),
                            Text(
                              'Completion rate: ${(completionRate * 100).round()}%',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _taskController,
                      onSubmitted: (_) => _addTask(),
                      decoration: const InputDecoration(
                        hintText: 'Enter Task',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: Task.supportedCategories
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Priority',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TaskPriority>(
                      key: const Key('priorityDropdown'),
                      initialValue: _selectedPriority,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: TaskPriority.values
                          .map(
                            (priority) => DropdownMenuItem<TaskPriority>(
                              value: priority,
                              child: Text(priority.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPriority = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDueDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              _selectedDueDate == null
                                  ? 'Pick Due Date'
                                  : 'Due: ${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickReminderDate,
                            icon: const Icon(Icons.notifications_none),
                            label: Text(
                              _selectedReminderDate == null
                                  ? 'Reminder'
                                  : 'Remind: ${_selectedReminderDate!.day}/${_selectedReminderDate!.month}/${_selectedReminderDate!.year}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sort by Priority'),
                      value: _sortByPriority,
                      onChanged: (value) {
                        setState(() {
                          _sortByPriority = value;
                        });
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search tasks',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _TaskFilter.values.map((filter) {
                        return ChoiceChip(
                          label: Text(_filterLabel(filter)),
                          selected: _activeFilter == filter,
                          onSelected: (_) =>
                              setState(() => _activeFilter = filter),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Add Task Button - always visible
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addTask,
                child: const Text('Add Task'),
              ),
            ),
          ),
          // Tasks section header and list
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8),
            child: Text(
              'Today\'s Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: displayedTasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks yet.\nAdd your first task!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: displayedTasks.length,
                      itemBuilder: (context, index) {
                        final task = displayedTasks[index];
                        final taskIndex = _tasks.indexOf(task);
                        return TaskCard(
                          task: task,
                          index: taskIndex,
                          onToggle: (value) =>
                              _toggleTaskCompletion(taskIndex, value),
                          onDelete: () => _deleteTask(taskIndex),
                          onEdit: () => _editTask(task),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
