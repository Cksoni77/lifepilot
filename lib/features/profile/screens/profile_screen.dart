import 'package:flutter/material.dart';

import '../../../shared_controllers/app_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _resetOnboarding() async {
    final controller = AppController.of(context);

    await controller.resetOnboarding();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Onboarding reset. Restart the app to test.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppController.of(context);
    final user = controller.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
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
                  child: Icon(
                    Icons.person,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  user?.email ?? 'user@email.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // -----------------------------------------
          // Personal Information
          // -----------------------------------------
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Name'),
            subtitle: Text(
              user?.name ?? 'Not available',
            ),
          ),

          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(
              user?.email ?? 'Not available',
            ),
          ),

          const Divider(height: 32),

          // -----------------------------------------
          // Preferences
          // -----------------------------------------
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            subtitle: Text(
              _themeLabel(controller.themeMode),
            ),
            onTap: () {
              _showThemeOptions(context, controller);
            },
          ),

          const Divider(height: 32),

          // -----------------------------------------
          // Development / Testing
          // -----------------------------------------
          const Text(
            'Development',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reset Onboarding'),
            subtitle: const Text(
              'Development testing only',
            ),
            onTap: _resetOnboarding,
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

  void _showThemeOptions(
    BuildContext context,
    AppController controller,
  ) {
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              RadioGroup<ThemeMode>(
                groupValue: controller.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value == null) return;

                  controller.setThemeMode(value);
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