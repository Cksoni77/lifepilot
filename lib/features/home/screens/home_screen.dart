import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../ai_chat/screens/ai_chat_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../habits/screens/habit_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../tasks/models/task.dart';
import '../../tasks/screens/add_task_sheet.dart';
import '../../tasks/screens/task_list_screen.dart';
import '../../tasks/services/notification_service.dart';
import '../../tasks/services/task_service.dart';
import '../widgets/ai_suggestion_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(
        userId: widget.userId,
      ),
      CalendarScreen(
        userId: widget.userId,
      ),
      const AiChatScreen(),
      HabitScreen(
        userId: widget.userId,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// ======================================================
// DASHBOARD
// ======================================================

class _Dashboard extends StatefulWidget {
  const _Dashboard({
    required this.userId,
  });

  final String userId;

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  late final TaskService _taskService;

  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _taskService = TaskService(
      userId: widget.userId,
    );

    _loadTasks();
  }

  // ====================================================
  // LOAD TASKS
  // ====================================================

  Future<void> _loadTasks() async {
    final tasks = await _taskService.loadTasks();

    if (!mounted) {
      return;
    }

    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  // ====================================================
  // ADD TASK
  // ====================================================

  Future<void> _openAddTask() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return AddTaskSheet(
          onCreate: (task) async {
            await _taskService.addTask(task);

            if (task.hasReminder) {
              await NotificationService.instance
                  .scheduleReminder(task);
            }

            if (!mounted) {
              return;
            }

            await _loadTasks();
          },
        );
      },
    );
  }

  // ====================================================
  // OPEN ALL TASKS
  // ====================================================

  Future<void> _openTaskList() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TaskListScreen(
          userId: widget.userId,
        ),
      ),
    );

    // Refresh dashboard after returning.
    await _loadTasks();
  }

  // ====================================================
  // COMPLETE TASK
  // ====================================================

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

    await _loadTasks();
  }

  // ====================================================
  // TODAY'S TASKS
  // ====================================================

  List<Task> get _todayTasks {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return _tasks
        .where((task) {
          if (task.dueDate == null) {
            return false;
          }

          final due = task.dueDate!;

          final dueDay = DateTime(
            due.year,
            due.month,
            due.day,
          );

          return dueDay == today;
        })
        .toList()
      ..sort(_sortTasks);
  }

  // ====================================================
  // TASK SORTING
  // ====================================================

  int _sortTasks(
    Task a,
    Task b,
  ) {
    // Incomplete tasks first.
    if (a.completed != b.completed) {
      return a.completed ? 1 : -1;
    }

    // Then by priority.
    final priorityComparison =
        _priorityValue(
      a.priority,
    ).compareTo(
      _priorityValue(
        b.priority,
      ),
    );

    if (priorityComparison != 0) {
      return priorityComparison;
    }

    // Then by due time.
    if (a.dueDate != null &&
        b.dueDate != null) {
      return a.dueDate!
          .compareTo(b.dueDate!);
    }

    return 0;
  }

  int _priorityValue(
    TaskPriority priority,
  ) {
    switch (priority) {
      case TaskPriority.high:
        return 0;

      case TaskPriority.medium:
        return 1;

      case TaskPriority.low:
        return 2;
    }
  }

  // ====================================================
  // TODAY'S COMPLETION
  // ====================================================

  int get _todayCompletedCount {
    return _todayTasks
        .where((task) => task.completed)
        .length;
  }

  int get _todayTotalCount {
    return _todayTasks.length;
  }

  double get _todayProgress {
    if (_todayTotalCount == 0) {
      return 0;
    }

    return _todayCompletedCount /
        _todayTotalCount;
  }

  // ====================================================
  // BUILD
  // ====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTasks,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              100,
            ),
            children: [
              _buildHeader(context),

              const SizedBox(height: 12),

              _buildGreeting(context),

              const SizedBox(height: 16),

              _buildTodayBalance(context),

              const SizedBox(height: 14),

              _buildAiSuggestion(),

              _buildTasksHeader(),

              _buildTodayTasks(),

              _buildHabitHeader(),

              _buildHabitProgress(),
            ],
          ),
        ),
      ),

      // IMPORTANT:
      // + now means "Add Task".
      floatingActionButton:
          FloatingActionButton(
        onPressed: _openAddTask,
        tooltip: 'Add task',
        child: const Icon(Icons.add),
      ),
    );
  }

  // ====================================================
  // HEADER
  // ====================================================

  Widget _buildHeader(
    BuildContext context,
  ) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(width: 9),

        Text(
          'LifePilot',
          style: Theme.of(
            context,
          ).textTheme.titleLarge,
        ),

        const Spacer(),

        IconButton(
          onPressed: () =>
              _showNotifications(context),
          icon: const Icon(
            Icons.notifications_none,
          ),
          tooltip: 'Notifications',
        ),

        const CircleAvatar(
          radius: 18,
          backgroundColor:
              AppColors.primary,
          child: Text(
            'C',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ====================================================
  // GREETING
  // ====================================================

  Widget _buildGreeting(
    BuildContext context,
  ) {
    final hour =
        DateTime.now().hour;

    String greeting;

    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(
            color:
                AppColors.textSecondary,
          ),
        ),

        Text(
          'Chhotu 👋',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall,
        ),
      ],
    );
  }

  // ====================================================
  // TODAY'S BALANCE
  // ====================================================

  Widget _buildTodayBalance(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ProgressRing(
            progress: _todayProgress,
            label:
                '${(_todayProgress * 100).round()}%',
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "TODAY'S BALANCE",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _todayTotalCount == 0
                      ? 'No tasks for today'
                      : '$_todayCompletedCount of $_todayTotalCount done',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _todayTotalCount == 0
                      ? 'Enjoy your free time ✨'
                      : _todayCompletedCount ==
                              _todayTotalCount
                          ? '🎉 Everything done!'
                          : 'Keep going — nice pace',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // AI SUGGESTION
  // ====================================================

  Widget _buildAiSuggestion() {
    return AiSuggestionCard(
      message:
          'You\'ve skipped "Read" 2 days running - want me to move it to mornings?',
    );
  }

  // ====================================================
  // TASK HEADER
  // ====================================================

  Widget _buildTasksHeader() {
    return _SectionHeader(
      title: "Today's tasks",
      action: 'View all',
      onPressed: _openTaskList,
    );
  }

  // ====================================================
  // TODAY'S TASKS
  // ====================================================

  Widget _buildTodayTasks() {
    if (_isLoading) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical: 20,
        ),
        child: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_todayTasks.isEmpty) {
      return Card(
        child: Padding(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons
                    .checklist_outlined,
                size: 42,
                color:
                    AppColors
                        .textSecondary,
              ),

              const SizedBox(height: 10),

              const Text(
                'No tasks for today',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Add a task to get your day organized.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      AppColors
                          .textSecondary,
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed:
                    _openAddTask,
                icon: const Icon(
                  Icons.add,
                ),
                label:
                    const Text(
                  'Add task',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show maximum 3 tasks on dashboard.
    final previewTasks =
        _todayTasks.take(3).toList();

    return Column(
      children: [
        ...previewTasks.map(
          (task) => Padding(
            padding:
                const EdgeInsets.only(
              bottom: 10,
            ),
            child: _TaskPreview(
              task: task,
              onChanged: (value) {
                _toggleTask(
                  task,
                  value,
                );
              },
            ),
          ),
        ),

        if (_todayTasks.length > 3)
          Align(
            alignment:
                Alignment.centerLeft,
            child: TextButton(
              onPressed:
                  _openTaskList,
              child: Text(
                '+ ${_todayTasks.length - 3} more tasks',
              ),
            ),
          ),
      ],
    );
  }

  // ====================================================
  // HABIT HEADER
  // ====================================================

  Widget _buildHabitHeader() {
    return _SectionHeader(
      title: 'Habit progress',
      action: 'See all',
      onPressed: () {
        // Habit navigation is already
        // available through bottom navigation.
        // We will connect this directly
        // to HabitScreen later if required.
      },
    );
  }

  // ====================================================
  // HABIT PREVIEW
  // ====================================================

  Widget _buildHabitProgress() {
    return Row(
      children: const [
        Expanded(
          child: _HabitPreview(
            icon:
                Icons
                    .local_fire_department_outlined,
            title: 'Exercise',
            subtitle:
                '3 day streak',
            color:
                AppColors.accentOrange,
          ),
        ),

        SizedBox(width: 10),

        Expanded(
          child: _HabitPreview(
            icon:
                Icons.water_drop_outlined,
            title: 'Water',
            subtitle:
                '5 day streak',
            color:
                AppColors.primary,
          ),
        ),
      ],
    );
  }

  // ====================================================
  // NOTIFICATIONS
  // ====================================================

  void _showNotifications(
    BuildContext context,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return const SafeArea(
          child: Padding(
            padding:
                EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  Icons
                      .notifications_none,
                  size: 40,
                ),

                SizedBox(height: 12),

                Text(
                  'You are all caught up.',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Your reminders and updates will appear here.',
                  textAlign:
                      TextAlign.center,
                ),

                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ======================================================
// SECTION HEADER
// ======================================================

class _SectionHeader
    extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onPressed,
  });

  final String title;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        0,
        20,
        0,
        10,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium,
          ),

          const Spacer(),

          TextButton(
            onPressed: onPressed,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// TASK PREVIEW
// ======================================================

class _TaskPreview
    extends StatelessWidget {
  const _TaskPreview({
    required this.task,
    required this.onChanged,
  });

  final Task task;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: CheckboxListTile(
        value: task.completed,

        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },

        controlAffinity:
            ListTileControlAffinity.leading,

        secondary: task.priority ==
                TaskPriority.high
            ? Chip(
                label: const Text(
                  'High',
                ),
                backgroundColor:
                    AppColors
                        .accentOrangeTint,
              )
            : null,

        title: Text(
          task.title,
          style: TextStyle(
            fontWeight:
                FontWeight.w600,
            decoration: task.completed
                ? TextDecoration
                    .lineThrough
                : null,
            color: task.completed
                ? AppColors.textFaint
                : null,
          ),
        ),

        subtitle: Text(
          _buildSubtitle(),
        ),

        side: BorderSide.none,
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[
      task.category.label,
    ];

    if (task.dueDate != null) {
      parts.add(
        _formatTime(
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

  String _formatTime(
    DateTime date,
  ) {
    final hour =
        date.hour % 12 == 0
            ? 12
            : date.hour % 12;

    final minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    final period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }
}

// ======================================================
// HABIT PREVIEW
// ======================================================

class _HabitPreview
    extends StatelessWidget {
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
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
            ),

            const SizedBox(height: 8),

            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium,
            ),

            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}