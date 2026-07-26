import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../widgets/task_card.dart';

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
  bool _sortByPriority = false;

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
      title: newTaskTitle,
      category: _selectedCategory,
      priority: _selectedPriority,
    );

    final updatedTasks = [..._tasks, task];
    await _taskService.saveTasks(updatedTasks);

    if (!mounted) return;
    setState(() {
      _tasks = updatedTasks;
      _taskController.clear();
    });
  }

  Future<void> _toggleTaskCompletion(int index, bool? value) async {
    _tasks[index].completed = value ?? false;
    final updatedTasks = [..._tasks];
    await _taskService.saveTasks(updatedTasks);

    if (!mounted) return;
    setState(() {
      _tasks = updatedTasks;
    });
  }

  Future<void> _deleteTask(int index) async {
    final updatedTasks = _tasks.where((t) => _tasks.indexOf(t) != index).toList();
    await _taskService.saveTasks(updatedTasks);

    if (!mounted) return;
    setState(() {
      _tasks = updatedTasks;
    });
  }

  List<Task> get _sortedTasks {
    final sortedTasks = List<Task>.from(_tasks);
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
    final displayedTasks = _sortedTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LifePilot'),
      ),
      body: Column(
        children: [
          // Form section - scrollable
          Expanded(
            flex: 2,
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
                          onToggle: (value) => _toggleTaskCompletion(taskIndex, value),
                          onDelete: () => _deleteTask(taskIndex),
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