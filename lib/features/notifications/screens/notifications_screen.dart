import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile/services/user_service.dart';
import '../../tasks/models/task.dart';
import '../../tasks/services/task_service.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({required this.userId, super.key});

  final String userId;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _remindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final service = TaskService(userId: widget.userId);
    final tasks = await service.loadTasks();
    final preferences = await UserService().loadPreferences();
    if (!mounted) return;
    setState(() {
      _remindersEnabled =
          preferences.notificationsEnabled && preferences.reminderEnabled;
      _tasks =
          tasks
              .where(
                (task) =>
                    _remindersEnabled &&
                    task.hasReminder &&
                    !task.completed &&
                    task.reminderDate!.isAfter(DateTime.now()),
              )
              .toList()
            ..sort((a, b) => a.reminderDate!.compareTo(b.reminderDate!));
      _isLoading = false;
    });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all reminders?'),
        content: const Text('This removes reminder times from your tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final service = TaskService(userId: widget.userId);
    final allTasks = await service.loadTasks();
    for (final task in allTasks) {
      task.reminderEnabled = false;
      task.reminderDate = null;
    }
    await service.saveTasks(allTasks);
    await NotificationService.instance.cancelAll();
    if (!mounted) return;
    setState(() => _tasks.clear());
  }

  Future<void> _clearReminder(Task task) async {
    task.reminderEnabled = false;
    task.reminderDate = null;
    await TaskService(userId: widget.userId).updateTask(task);
    await NotificationService.instance.cancelReminder(task);
    if (!mounted) return;
    setState(() => _tasks.removeWhere((item) => item.id == task.id));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Reminders'),
      actions: [
        if (_tasks.isNotEmpty)
          TextButton(onPressed: _clearAll, child: const Text('Clear all')),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _tasks.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 44,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _remindersEnabled
                        ? 'No upcoming reminders'
                        : 'Reminders are off',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _remindersEnabled
                        ? 'Add a reminder to a task and it will appear here.'
                        : 'Turn on notifications and task reminders in Profile settings.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: _tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _ReminderCard(
              task: _tasks[index],
              onClear: () => _clearReminder(_tasks[index]),
            ),
          ),
  );
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.task, required this.onClear});
  final Task task;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryTint,
          child: const Icon(Icons.alarm_outlined, color: AppColors.primary),
        ),
        title: Text(task.title),
        subtitle: Text('Reminder ${_formatDateTime(task.reminderDate!)}'),
        trailing: IconButton(
          onPressed: onClear,
          tooltip: 'Remove reminder',
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime date) =>
    '${date.day}/${date.month}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
