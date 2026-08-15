import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../ai_chat/screens/ai_chat_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../habits/screens/habit_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../tasks/screens/task_list_screen.dart';
import '../widgets/ai_suggestion_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.userId, super.key});

  final String userId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(userId: widget.userId, onOpenTasks: () => _select(0)),
      CalendarScreen(userId: widget.userId),
      const AiChatScreen(),
      HabitScreen(userId: widget.userId),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  void _select(int index) => setState(() => _selectedIndex = index);
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.userId, required this.onOpenTasks});

  final String userId;
  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.auto_awesome, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  'LifePilot',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showNotifications(context),
                  icon: const Icon(Icons.notifications_none),
                  tooltip: 'Notifications',
                ),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text('C', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Good afternoon',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            Text('Chhotu 👋', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const ProgressRing(progress: .64, label: '64%'),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "TODAY'S BALANCE",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '3 of 5 done - nice pace',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '🔥 3-day streak      2 due today',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AiSuggestionCard(
              message:
                  'You\'ve skipped "Read" 2 days running - want me to move it to mornings?',
            ),
            _SectionHeader(
              title: "Today's tasks",
              action: 'View all',
              onPressed: () => _openTaskList(context),
            ),
            _TaskPreview(
              title: 'Finish Q3 report',
              subtitle: 'Work · 5:00 PM',
              priority: 'High',
            ),
            const SizedBox(height: 10),
            const _TaskPreview(
              title: 'Morning workout',
              subtitle: 'Health · 7:00 AM',
              completed: true,
            ),
            _SectionHeader(
              title: 'Habit progress',
              action: 'See all',
              onPressed: () {},
            ),
            Row(
              children: const [
                Expanded(
                  child: _HabitPreview(
                    icon: Icons.local_fire_department_outlined,
                    title: 'Exercise',
                    subtitle: '3 day streak',
                    color: AppColors.accentOrange,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _HabitPreview(
                    icon: Icons.water_drop_outlined,
                    title: 'Water',
                    subtitle: '5 day streak',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskList(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openTaskList(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => TaskListScreen(userId: userId)),
  );

  void _showNotifications(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (_) => const Padding(
      padding: EdgeInsets.all(24),
      child: Text('You are all caught up.'),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onPressed,
  });
  final String title;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
    child: Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    ),
  );
}

class _TaskPreview extends StatelessWidget {
  const _TaskPreview({
    required this.title,
    required this.subtitle,
    this.priority,
    this.completed = false,
  });
  final String title;
  final String subtitle;
  final String? priority;
  final bool completed;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(
        completed ? Icons.check_circle_outline : Icons.radio_button_unchecked,
        color: AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          decoration: completed ? TextDecoration.lineThrough : null,
          color: completed ? AppColors.textFaint : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: priority == null
          ? null
          : Chip(
              label: Text(priority!),
              backgroundColor: AppColors.accentOrangeTint,
            ),
    ),
  );
}

class _HabitPreview extends StatelessWidget {
  const _HabitPreview({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}
