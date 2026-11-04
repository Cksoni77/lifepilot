import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/task.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({required this.onCreate, this.task, super.key});

  final Future<void> Function(Task) onCreate;
  final Task? task;

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedMinutesController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  TaskCategory _category = TaskCategory.personal;

  DateTime? _dueDate;
  DateTime? _reminderDate;
  bool _reminderEnabled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task == null) return;
    _titleController.text = task.title;
    _descriptionController.text = task.description;
    _estimatedMinutesController.text = task.estimatedMinutes?.toString() ?? '';
    _priority = task.priority;
    _category = task.category;
    _dueDate = task.dueDate;
    _reminderDate = task.reminderDate;
    _reminderEnabled = task.reminderEnabled;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedMinutesController.dispose();
    super.dispose();
  }

  Future<void> _chooseDueDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _dueDate = selected;
    });
  }

  Future<void> _chooseReminder() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: _reminderDate != null
          ? TimeOfDay.fromDateTime(_reminderDate!)
          : TimeOfDay.now(),
    );

    if (time == null || !mounted) {
      return;
    }

    setState(() {
      _reminderDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      _reminderEnabled = true;
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    final estimatedText = _estimatedMinutesController.text.trim();

    final estimatedMinutes = int.tryParse(estimatedText);
    if (estimatedText.isNotEmpty &&
        (estimatedMinutes == null || estimatedMinutes <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an estimate greater than zero')),
      );
      return;
    }
    if (_reminderEnabled &&
        _reminderDate != null &&
        !_reminderDate!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a reminder time in the future')),
      );
      return;
    }

    final task = Task(
      id: widget.task?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      description: _descriptionController.text.trim(),
      category: _category,
      priority: _priority,
      dueDate: _dueDate,
      reminderDate: _reminderEnabled ? _reminderDate : null,
      reminderEnabled: _reminderEnabled && _reminderDate != null,
      estimatedMinutes: estimatedMinutes,
      completed: widget.task?.completed ?? false,
      createdAt: widget.task?.createdAt,
      completedAt: widget.task?.completedAt,
    );

    setState(() => _isSaving = true);
    try {
      await widget.onCreate(task);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save this task. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                widget.task == null ? 'New task' : 'Edit task',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 14),

              // TITLE
              TextField(
                controller: _titleController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'Task title',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),

              const SizedBox(height: 12),

              // DESCRIPTION
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),

              const SizedBox(height: 12),

              // CATEGORY
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _chooseCategory,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _category.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // PRIORITY
              Row(
                children: TaskPriority.values.map((priority) {
                  final selected = _priority == priority;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: priority == TaskPriority.high ? 0 : 8,
                      ),
                      child: ChoiceChip(
                        label: Text(priority.label),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) {
                          setState(() {
                            _priority = priority;
                          });
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // DUE DATE
              OutlinedButton.icon(
                onPressed: _chooseDueDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _dueDate == null
                      ? 'Set due date'
                      : 'Due: ${_formatDate(_dueDate!)}',
                ),
              ),

              const SizedBox(height: 8),

              // REMINDER
              OutlinedButton.icon(
                onPressed: _chooseReminder,
                icon: const Icon(Icons.notifications_outlined),
                label: Text(
                  _reminderDate == null
                      ? 'Set reminder'
                      : 'Reminder: ${_formatDateTime(_reminderDate!)}',
                ),
              ),

              if (_reminderEnabled)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _reminderEnabled = false;
                        _reminderDate = null;
                      });
                    },
                    child: const Text('Remove reminder'),
                  ),
                ),

              const SizedBox(height: 4),

              // ESTIMATED TIME
              TextField(
                controller: _estimatedMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Estimated time in minutes',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: Text(
                        _isSaving
                            ? 'Saving'
                            : widget.task == null
                            ? 'Add task'
                            : 'Save',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseCategory() async {
    final category = await showModalBottomSheet<TaskCategory>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: TaskCategory.values.map((category) {
              return ListTile(
                leading: Icon(_categoryIcon(category)),
                title: Text(category.label),
                trailing: category == _category
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, category),
              );
            }).toList(),
          ),
        );
      },
    );

    if (category != null && mounted) {
      setState(() {
        _category = category;
      });
    }
  }

  IconData _categoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.personal:
        return Icons.home_work_outlined;
      case TaskCategory.work:
        return Icons.work_outline;
      case TaskCategory.health:
        return Icons.favorite_border;
      case TaskCategory.finance:
        return Icons.account_balance_wallet_outlined;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.day}/${date.month} $hour:$minute';
  }
}
