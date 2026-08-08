import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/user.dart';
import '../models/user_preferences.dart';
import '../services/app_controller.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late String _avatar;
  late String _theme;
  late bool _notificationsEnabled;
  late bool _reminderEnabled;
  late TaskPriority _defaultPriority;
  bool _isSaving = false;

  static const _avatars = <String>['person', 'face', 'self_improvement', 'rocket_launch'];

  @override
  void initState() {
    super.initState();
    final controller = AppController.of(context);
    final user = controller.user!;
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _avatar = user.avatarPath ?? 'person';
    _theme = controller.preferences.theme;
    _notificationsEnabled = controller.preferences.notificationsEnabled;
    _reminderEnabled = controller.preferences.reminderEnabled;
    _defaultPriority = controller.preferences.defaultTaskPriority;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid name and email.')));
      return;
    }
    setState(() => _isSaving = true);
    final controller = AppController.of(context);
    final updatedUser = User(id: controller.user!.id, name: name, email: email, avatarPath: _avatar);
    final updatedPreferences = UserPreferences(
      theme: _theme,
      notificationsEnabled: _notificationsEnabled,
      reminderEnabled: _reminderEnabled,
      defaultTaskPriority: _defaultPriority,
    );
    await controller.updateProfile(updatedUser, updatedPreferences);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute<void>(builder: (_) => const LoginScreen()), (_) => false);
  }

  IconData _avatarIcon(String avatar) {
    switch (avatar) {
      case 'face':
        return Icons.face_outlined;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'rocket_launch':
        return Icons.rocket_launch_outlined;
      default:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(56),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(mainAxisSize: MainAxisSize.min, children: _avatars.map((avatar) => ListTile(leading: Icon(_avatarIcon(avatar)), title: Text(avatar == 'person' ? 'Default avatar' : 'Avatar ${_avatars.indexOf(avatar)}'), onTap: () { setState(() => _avatar = avatar); Navigator.pop(context); })).toList()),
                ),
              ),
              child: CircleAvatar(radius: 52, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(_avatarIcon(_avatar), size: 52, color: Theme.of(context).colorScheme.primary)),
            ),
          ),
          Center(child: TextButton.icon(onPressed: () {}, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Choose avatar'))),
          const SizedBox(height: 12),
          Text('Personal information', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 12),
          TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline))),
          const SizedBox(height: 28),
          Text('Preferences', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(initialValue: _theme, decoration: const InputDecoration(labelText: 'Theme', prefixIcon: Icon(Icons.brightness_6_outlined)), items: const [DropdownMenuItem(value: 'system', child: Text('System default')), DropdownMenuItem(value: 'light', child: Text('Light')), DropdownMenuItem(value: 'dark', child: Text('Dark'))], onChanged: (value) { if (value != null) setState(() => _theme = value); }),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Notifications'), subtitle: const Text('Allow task reminders and updates'), value: _notificationsEnabled, onChanged: (value) => setState(() => _notificationsEnabled = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Reminders'), subtitle: const Text('Schedule reminders for tasks'), value: _reminderEnabled, onChanged: (value) => setState(() => _reminderEnabled = value)),
          DropdownButtonFormField<TaskPriority>(initialValue: _defaultPriority, decoration: const InputDecoration(labelText: 'Default task priority'), items: TaskPriority.values.map((priority) => DropdownMenuItem(value: priority, child: Text(priority.label))).toList(), onChanged: (value) { if (value != null) setState(() => _defaultPriority = value); }),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: _isSaving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(_isSaving ? 'Saving...' : 'Save changes')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Log out')),
        ],
      ),
    );
  }
}

