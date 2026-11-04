import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../notifications/services/notification_service.dart';
import '../../tasks/models/task.dart';
import '../../tasks/screens/add_task_sheet.dart';
import '../../tasks/services/task_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({required this.userId, super.key});

  final String userId;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selected;
  late DateTime _visibleMonth;
  bool _monthView = true;
  bool _isLoading = true;
  late final TaskService _taskService;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selected = DateTime(today.year, today.month, today.day);
    _visibleMonth = DateTime(today.year, today.month);
    _taskService = TaskService(userId: widget.userId);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _taskService.loadTasks();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  List<Task> get _selectedTasks =>
      _tasks.where((task) {
        final dueDate = task.dueDate;
        return dueDate != null && _sameDay(dueDate, _selected);
      }).toList()..sort(
        (a, b) => a.completed == b.completed
            ? a.title.compareTo(b.title)
            : a.completed
            ? 1
            : -1,
      );

  void _selectDate(DateTime date) {
    setState(() {
      _selected = _dateOnly(date);
      _visibleMonth = DateTime(date.year, date.month);
    });
  }

  void _changeMonth(int offset) {
    final month = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    setState(() {
      _visibleMonth = month;
      _selected = DateTime(
        month.year,
        month.month,
        _selected.day.clamp(1, lastDay),
      );
    });
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
          final index = _tasks.indexWhere((item) => item.id == updatedTask.id);
          if (index >= 0) setState(() => _tasks[index] = updatedTask);
        },
      ),
    );
  }

  Future<void> _toggleTask(Task task, bool completed) async {
    task.completed = completed;
    task.completedAt = completed ? DateTime.now() : null;
    await _taskService.updateTask(task);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                Text(
                  'Calendar',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Month')),
                ButtonSegment(value: false, label: Text('Week')),
              ],
              selected: {_monthView},
              onSelectionChanged: (value) =>
                  setState(() => _monthView = value.first),
            ),
            const SizedBox(height: 16),
            if (_monthView)
              _MonthCalendar(
                selected: _selected,
                visibleMonth: _visibleMonth,
                tasks: _tasks,
                onSelected: _selectDate,
                onMonthChanged: _changeMonth,
              )
            else
              _WeekCalendar(
                selected: _selected,
                tasks: _tasks,
                onSelected: _selectDate,
              ),
            const Divider(height: 28),
            Text(
              'Tasks for ${_monthName(_selected.month)} ${_selected.day}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_selectedTasks.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No tasks scheduled for this day.'),
                ),
              )
            else
              ..._selectedTasks.map(
                (task) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.completed,
                      onChanged: (value) => _toggleTask(task, value ?? false),
                      semanticLabel:
                          'Mark ${task.title} ${task.completed ? 'incomplete' : 'complete'}',
                    ),
                    title: Text(task.title),
                    subtitle: Text(
                      '${task.category.label} · ${task.priority.label}',
                    ),
                    onTap: () => _editTask(task),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.selected,
    required this.visibleMonth,
    required this.tasks,
    required this.onSelected,
    required this.onMonthChanged,
  });
  final DateTime selected;
  final DateTime visibleMonth;
  final List<Task> tasks;
  final ValueChanged<DateTime> onSelected;
  final ValueChanged<int> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month);
    final gridStart = firstOfMonth.subtract(
      Duration(days: firstOfMonth.weekday - 1),
    );
    final days = List.generate(
      42,
      (index) => gridStart.add(Duration(days: index)),
    );
    final today = _dateOnly(DateTime.now());
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => onMonthChanged(-1),
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            ),
            Expanded(
              child: Text(
                '${_monthName(visibleMonth.month)} ${visibleMonth.year}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: () => onMonthChanged(1),
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map(
                (day) =>
                    Text(day, style: Theme.of(context).textTheme.bodySmall),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            final active = _sameDay(day, selected);
            final isToday = _sameDay(day, today);
            final hasTasks = tasks.any(
              (task) => task.dueDate != null && _sameDay(task.dueDate!, day),
            );
            final inMonth = day.month == visibleMonth.month;
            return Semantics(
              button: true,
              label:
                  '${_monthName(day.month)} ${day.day}${isToday ? ', today' : ''}${hasTasks ? ', has tasks' : ''}',
              selected: active,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onSelected(day),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !active
                            ? Border.all(color: AppColors.primary)
                            : null,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: active
                              ? Colors.white
                              : inMonth
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).disabledColor,
                          fontWeight: active || isToday
                              ? FontWeight.w800
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 4,
                      child: hasTasks
                          ? const DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.accentOrange,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(width: 4, height: 4),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WeekCalendar extends StatelessWidget {
  const _WeekCalendar({
    required this.selected,
    required this.tasks,
    required this.onSelected,
  });
  final DateTime selected;
  final List<Task> tasks;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(7, (index) {
      final date = selected.subtract(
        Duration(days: selected.weekday - 1 - index),
      );
      final active = _sameDay(date, selected);
      final hasTasks = tasks.any(
        (task) => task.dueDate != null && _sameDay(task.dueDate!, date),
      );
      return Expanded(
        child: Semantics(
          button: true,
          label:
              '${_monthName(date.month)} ${date.day}${hasTasks ? ', has tasks' : ''}',
          selected: active,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => onSelected(date),
            child: Column(
              children: [
                Text(
                  ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                CircleAvatar(
                  backgroundColor: active
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: active
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  child: Text('${date.day}'),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 4,
                  child: hasTasks
                      ? const DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 4, height: 4),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];
