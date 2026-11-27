import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../auth/screens/sign_in_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../../tasks/services/task_service.dart';
import '../services/legacy_data_migration_service.dart';
import '../../../shared_controllers/app_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _importingLegacyData = false;

  Future<void> _importLegacyData(AppController controller) async {
    final user = controller.user;
    if (user == null || _importingLegacyData) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import previous local data?'),
        content: const Text(
          'Tasks, habits, and goals saved on this device will be copied to '
          'your account. Your original local data will not be deleted. '
          'You can safely retry if the import is interrupted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _importingLegacyData = true);
    try {
      final result = await LegacyDataMigrationService().importFor(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Copied or confirmed ${result.tasks} tasks, ${result.habits} '
            'habits, and ${result.goals} goals. Local copies were kept.',
          ),
        ),
      );
    } on ApiException catch (error) {
      _showMessage(error.message);
    } on StateError catch (error) {
      _showMessage(error.message.toString());
    } on FormatException catch (error) {
      _showMessage(error.message.toString());
    } on ArgumentError catch (error) {
      _showMessage(error.message.toString());
    } finally {
      if (mounted) setState(() => _importingLegacyData = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setNotifications(AppController controller, bool enabled) async {
    await controller.setNotificationsEnabled(enabled);
    await _syncTaskRemindersWithFeedback(controller);
  }

  Future<void> _setReminders(AppController controller, bool enabled) async {
    await controller.setRemindersEnabled(enabled);
    await _syncTaskRemindersWithFeedback(controller);
  }

  Future<void> _syncTaskRemindersWithFeedback(AppController controller) async {
    try {
      await _syncTaskReminders(controller);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _syncTaskReminders(AppController controller) async {
    if (!controller.notificationsEnabled || !controller.remindersEnabled) {
      await NotificationService.instance.cancelAll();
      return;
    }
    final userId = controller.user?.id;
    if (userId == null) return;
    final tasks = await TaskService(userId: userId).loadTasks();
    for (final task in tasks) {
      if (task.hasReminder && !task.completed) {
        await NotificationService.instance.scheduleReminder(task);
      } else {
        await NotificationService.instance.cancelReminder(task);
      }
    }
  }

  Future<void> _logout(AppController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in to your LifePilot account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.logout();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppController.of(context);
    final user = controller.user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -----------------------------------------
          // Profile Header
          // -----------------------------------------
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),

                const SizedBox(height: 16),

                Text(
                  user?.name ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),

                const SizedBox(height: 4),

                Text(
                  user?.email ?? 'user@email.com',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // -----------------------------------------
          // Personal Information
          // -----------------------------------------
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Name'),
            subtitle: Text(user?.name ?? 'Not available'),
          ),

          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(user?.email ?? 'Not available'),
          ),

          const Divider(height: 32),

          // -----------------------------------------
          // Preferences
          // -----------------------------------------
          Text('Preferences', style: Theme.of(context).textTheme.titleMedium),

          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(controller.themeMode)),
            onTap: () {
              _showThemeOptions(context, controller);
            },
          ),

          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Allow LifePilot to send notifications'),
            value: controller.notificationsEnabled,
            onChanged: (value) => _setNotifications(controller, value),
          ),

          SwitchListTile(
            secondary: const Icon(Icons.alarm_outlined),
            title: const Text('Task reminders'),
            subtitle: const Text('Schedule alerts for tasks with reminders'),
            value: controller.remindersEnabled,
            onChanged: controller.notificationsEnabled
                ? (value) => _setReminders(controller, value)
                : null,
          ),

          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Import previous local data'),
            subtitle: const Text(
              'Copy tasks, habits, and goals from this device',
            ),
            trailing: _importingLegacyData
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            enabled: !_importingLegacyData,
            onTap: () => _importLegacyData(controller),
          ),

          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () => _logout(controller),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeOptions(BuildContext context, AppController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choose Theme',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              RadioGroup<ThemeMode>(
                groupValue: controller.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value == null) return;

                  unawaited(controller.setThemeMode(value));
                  Navigator.pop(context);
                },
                child: const Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text('System Default'),
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Light'),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Dark'),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
