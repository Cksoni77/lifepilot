import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../utils/date_utils.dart';
import '../widgets/calendar_task_list.dart';
import '../widgets/calendar_view.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({required this.userId, super.key});

  final String userId;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final TaskService _taskService = TaskService(userId: widget.userId);
  List<Task> _tasks = <Task>[];
  DateTime _selectedDate = startOfDay(DateTime.now());
  late DateTime _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  CalendarViewMode _viewMode = CalendarViewMode.month;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _taskService.loadTasks();
    if (!mounted) return;
    setState(() => _tasks = tasks);
  }

  void _moveMonth(int amount) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + amount);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = startOfDay(date);
      if (_viewMode == CalendarViewMode.month &&
          (date.month != _displayedMonth.month || date.year != _displayedMonth.year)) {
        _displayedMonth = DateTime(date.year, date.month);
      }
    });
  }

  List<Task> get _selectedTasks {
    return _tasks.where((task) => task.dueDate != null && isSameDay(task.dueDate!, _selectedDate)).toList();
  }

  Future<void> _toggleTask(Task task) async {
    task.completed = !task.completed;
    await _taskService.saveTasks(_tasks);
    if (!mounted) return;
    setState(() {});
  }

  void _goToToday() {
    final today = startOfDay(DateTime.now());
    setState(() {
      _selectedDate = today;
      _displayedMonth = DateTime(today.year, today.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _viewMode == CalendarViewMode.month
        ? monthAndYear(_displayedMonth)
        : 'Week of ${_selectedDate.day} ${shortMonthName(_selectedDate.month)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            onPressed: _goToToday,
            icon: const Icon(Icons.today_outlined),
            tooltip: 'Today',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _viewMode == CalendarViewMode.month
                    ? () => _moveMonth(-1)
                    : () => _selectDate(_selectedDate.subtract(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: _viewMode == CalendarViewMode.month
                    ? () => _moveMonth(1)
                    : () => _selectDate(_selectedDate.add(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<CalendarViewMode>(
            segments: const [
              ButtonSegment(value: CalendarViewMode.month, label: Text('Month'), icon: Icon(Icons.calendar_month)),
              ButtonSegment(value: CalendarViewMode.week, label: Text('Week'), icon: Icon(Icons.view_week)),
            ],
            selected: {_viewMode},
            onSelectionChanged: (selection) => setState(() => _viewMode = selection.first),
          ),
          const SizedBox(height: 20),
          CalendarView(
            displayedMonth: _displayedMonth,
            selectedDate: _selectedDate,
            tasks: _tasks,
            mode: _viewMode,
            onDateSelected: _selectDate,
          ),
          const Divider(height: 32),
          CalendarTaskList(
            date: _selectedDate,
            tasks: _selectedTasks,
            onToggle: _toggleTask,
          ),
        ],
      ),
    );
  }
}
