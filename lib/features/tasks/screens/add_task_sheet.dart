import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/task.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({required this.onCreate, this.onCreateDetails, super.key});

  final ValueChanged<String> onCreate;
  final void Function(String title, String category, TaskPriority priority)?
  onCreateDetails;

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  TaskPriority _priority = TaskPriority.low;
  String _category = 'Personal';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    widget.onCreateDetails?.call(title, _category, _priority);
    if (widget.onCreateDetails == null) widget.onCreate(title);
    Navigator.pop(context);
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
            Text('New task', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'Task title',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _chooseCategory,
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.home_work_outlined),
                ),
                child: Row(
                  children: [
                    Text(
                      _category,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                      onSelected: (_) => setState(() => _priority = priority),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add),
                    label: const Text('Add task'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseCategory() async {
    final category = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Personal', 'Work', 'Health', 'Finance']
              .map(
                (value) => ListTile(
                  leading: Icon(
                    value == 'Personal'
                        ? Icons.home_work_outlined
                        : value == 'Work'
                        ? Icons.work_outline
                        : value == 'Health'
                        ? Icons.favorite_border
                        : Icons.account_balance_wallet_outlined,
                  ),
                  title: Text(value),
                  trailing: value == _category
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, value),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (category != null && mounted) {
      setState(() => _category = category);
    }
  }
}
