import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/app_notification.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static final items = <AppNotification>[
    AppNotification(
      id: 'ai',
      title: 'AI suggestion',
      body: 'Move "Read" to mornings for a better streak?',
      type: NotificationType.aiSuggestion,
      timestamp: DateTime(2026, 8, 8),
    ),
    AppNotification(
      id: 'done',
      title: 'Task completed',
      body: '"Morning workout" marked done. Nice work.',
      type: NotificationType.taskCompleted,
      timestamp: DateTime(2026, 8, 8),
    ),
    AppNotification(
      id: 'streak',
      title: 'Streak reminder',
      body: 'Log "Water" before midnight to keep your streak.',
      type: NotificationType.streakReminder,
      timestamp: DateTime(2026, 8, 8),
    ),
    AppNotification(
      id: 'event',
      title: 'Event tomorrow',
      body: '"Team sync" at 10:00 AM.',
      type: NotificationType.event,
      timestamp: DateTime(2026, 8, 7),
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [TextButton(onPressed: () {}, child: const Text('Clear all'))],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(
          'TODAY',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textFaint,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...items.take(3).map((item) => _NotificationCard(item: item)),
        const SizedBox(height: 12),
        Text(
          'EARLIER',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textFaint,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _NotificationCard(item: items.last),
      ],
    ),
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});
  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.type) {
      NotificationType.aiSuggestion => AppColors.accentPurple,
      NotificationType.taskCompleted => AppColors.primary,
      NotificationType.streakReminder => AppColors.accentOrange,
      NotificationType.event => AppColors.textFaint,
    };
    final icon = switch (item.type) {
      NotificationType.aiSuggestion => Icons.auto_awesome,
      NotificationType.taskCompleted => Icons.check_circle_outline,
      NotificationType.streakReminder => Icons.local_fire_department_outlined,
      NotificationType.event => Icons.calendar_month_outlined,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(item.body),
        trailing: Text(
          item.type == NotificationType.event ? 'Yesterday' : '2m ago',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
