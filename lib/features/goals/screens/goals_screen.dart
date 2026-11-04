import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({required this.userId, super.key});

  final String userId;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late final GoalService _service;
  final List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = GoalService(userId: widget.userId);
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await _service.loadGoals();
    if (!mounted) return;
    setState(() {
      _goals
        ..clear()
        ..addAll(goals);
      _isLoading = false;
    });
  }

  Future<void> _editGoal([Goal? existing]) async {
    final goal = await showDialog<Goal>(
      context: context,
      builder: (_) => _GoalEditor(goal: existing),
    );
    if (!mounted || goal == null) return;
    setState(() {
      final index = _goals.indexWhere((item) => item.id == goal.id);
      if (index < 0) {
        _goals.add(goal);
      } else {
        _goals[index] = goal;
      }
    });
    await _service.saveGoals(_goals);
  }

  Future<void> _deleteGoal(Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('"${goal.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _goals.removeWhere((item) => item.id == goal.id));
    await _service.saveGoals(_goals);
  }

  Future<void> _saveProgress(Goal goal, double progress) async {
    setState(() => goal.progress = progress);
    await _service.saveGoals(_goals);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Goals'),
      actions: [
        IconButton(
          onPressed: () => _editGoal(),
          icon: const Icon(Icons.add),
          tooltip: 'Add goal',
        ),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _goals.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.track_changes_outlined, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    'No goals yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create a goal and track progress as you move forward.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _editGoal(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add goal'),
                  ),
                ],
              ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                '${_goals.length} ${_goals.length == 1 ? 'goal' : 'goals'} · ${_goals.where((goal) => goal.progress >= 1).length} completed',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ..._goals.map(
                (goal) => _GoalCard(
                  goal: goal,
                  onEdit: () => _editGoal(goal),
                  onDelete: () => _deleteGoal(goal),
                  onProgressChanged: (progress) =>
                      _saveProgress(goal, progress),
                ),
              ),
            ],
          ),
  );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
    required this.onProgressChanged,
  });

  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<double> onProgressChanged;

  @override
  Widget build(BuildContext context) {
    final color = goal.category == 'Work'
        ? AppColors.accentOrange
        : goal.category == 'Personal'
        ? AppColors.accentPurple
        : AppColors.primary;
    final icon = goal.category == 'Health'
        ? Icons.track_changes
        : goal.category == 'Work'
        ? Icons.work_outline
        : Icons.book_outlined;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        goal.category,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(goal.progress * 100).round()}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Goal actions',
                  onSelected: (action) {
                    if (action == 'edit') onEdit();
                    if (action == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: goal.progress,
              color: color,
              minHeight: 6,
              borderRadius: BorderRadius.circular(6),
            ),
            Slider(
              value: goal.progress.clamp(0, 1),
              onChanged: onProgressChanged,
              semanticFormatterCallback: (value) =>
                  '${(value * 100).round()}% complete',
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalEditor extends StatefulWidget {
  const _GoalEditor({this.goal});

  final Goal? goal;

  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late String _category;
  late double _progress;
  DateTime? _targetDate;

  static const _categories = ['Personal', 'Work', 'Health', 'Finance'];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.goal?.title ?? '');
    _category = widget.goal?.category ?? _categories.first;
    _progress = widget.goal?.progress ?? 0;
    _targetDate = widget.goal?.targetDate;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _chooseTargetDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date != null && mounted) setState(() => _targetDate = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Goal(
        id: widget.goal?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        category: _category,
        progress: _progress,
        targetDate: _targetDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.goal == null ? 'Add goal' : 'Edit goal'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Goal'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a goal' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 8),
            if (widget.goal != null) ...[
              Text('Progress ${(100 * _progress).round()}%'),
              Slider(
                value: _progress.clamp(0, 1),
                onChanged: (value) => setState(() => _progress = value),
              ),
            ],
            TextButton.icon(
              onPressed: _chooseTargetDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                _targetDate == null
                    ? 'Set target date'
                    : 'Target ${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}
