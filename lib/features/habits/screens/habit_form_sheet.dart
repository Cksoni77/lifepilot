import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import 'package:flutter/services.dart';

import '../models/habit.dart';

class HabitFormSheet extends StatefulWidget {
  const HabitFormSheet({required this.onSave, this.habit, super.key});

  final Habit? habit;
  final Future<void> Function(Habit habit) onSave;

  @override
  State<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<HabitFormSheet> {
  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;
  late HabitFrequency _frequency;
  late HabitDurationUnit _durationUnit;
  late HabitCategory _category;
  late DateTime _startDate;
  late final Set<int> _selectedWeekdays;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _nameController = TextEditingController(text: habit?.name ?? '');
    _descriptionController = TextEditingController(
      text: habit?.description ?? '',
    );
    _durationController = TextEditingController(
      text: habit?.targetDuration?.toString() ?? '',
    );
    _frequency = habit?.frequency ?? HabitFrequency.daily;
    _durationUnit = habit?.durationUnit ?? HabitDurationUnit.minutes;
    _category = habit?.category ?? HabitCategory.personal;
    _startDate = habit?.startDate ?? _dateOnly(DateTime.now());
    _selectedWeekdays = {...?habit?.selectedWeekdays};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _chooseStartDate() async {
    final today = _dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate.isAfter(today) ? today : _startDate,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Choose habit start date',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _startDate = _dateOnly(selected);
      _errorMessage = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    if (_frequency == HabitFrequency.customDays && _selectedWeekdays.isEmpty) {
      setState(() => _errorMessage = 'Select at least one weekday.');
      return;
    }

    final durationText = _durationController.text.trim();
    final duration = durationText.isEmpty
        ? null
        : double.tryParse(durationText);
    if (durationText.isNotEmpty && (duration == null || duration <= 0)) {
      setState(
        () => _errorMessage = 'Target duration must be greater than zero.',
      );
      return;
    }

    final existing = widget.habit;
    if (existing != null &&
        existing.completedDates.any((date) => date.isBefore(_startDate))) {
      setState(
        () =>
            _errorMessage = 'Start date cannot be after a recorded completion.',
      );
      return;
    }

    final habit = Habit(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      frequency: _frequency,
      selectedWeekdays: _frequency == HabitFrequency.customDays
          ? (_selectedWeekdays.toList()..sort())
          : const [],
      targetDuration: duration,
      durationUnit: _durationUnit,
      category: _category,
      startDate: _startDate,
      completedDates: existing?.completedDates,
    );

    setState(() => _isSaving = true);
    try {
      await widget.onSave(habit);
      if (mounted) Navigator.pop(context);
    } on StateError catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message.toString());
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on ArgumentError catch (error) {
      if (mounted) setState(() => _errorMessage = error.message.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.bottom;
    final sheetHeight = (availableHeight * .92).clamp(0.0, 760.0).toDouble();
    final theme = Theme.of(context);

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.habit == null ? 'Add Habit' : 'Edit Habit',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    TextFormField(
                      key: const Key('habit-name'),
                      controller: _nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Habit name',
                        hintText: 'Daily Exercise',
                        prefixIcon: Icon(Icons.edit_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Give your habit a name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('habit-description'),
                      controller: _descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Walk or exercise for at least 30 minutes.',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('Schedule', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<HabitFrequency>(
                      key: const Key('habit-frequency'),
                      initialValue: _frequency,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      items: HabitFrequency.values
                          .map(
                            (frequency) => DropdownMenuItem(
                              value: frequency,
                              child: Text(frequency.label),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _frequency = value;
                                  _errorMessage = null;
                                });
                              }
                            },
                    ),
                    if (_frequency == HabitFrequency.customDays) ...[
                      const SizedBox(height: 12),
                      Text('Repeat on', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (
                            var index = 0;
                            index < _weekdayNames.length;
                            index++
                          )
                            FilterChip(
                              label: Text(_weekdayNames[index]),
                              selected: _selectedWeekdays.contains(index + 1),
                              onSelected: _isSaving
                                  ? null
                                  : (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedWeekdays.add(index + 1);
                                        } else {
                                          _selectedWeekdays.remove(index + 1);
                                        }
                                        _errorMessage = null;
                                      });
                                    },
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 22),
                    Text('Target', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const Key('habit-duration'),
                            controller: _durationController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Duration',
                              helperText: 'Optional',
                              hintText: '30',
                              prefixIcon: Icon(Icons.timer_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<HabitDurationUnit>(
                            key: const Key('habit-duration-unit'),
                            initialValue: _durationUnit,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                            ),
                            items: HabitDurationUnit.values
                                .map(
                                  (unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _durationUnit = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text('Details', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<HabitCategory>(
                      key: const Key('habit-category'),
                      initialValue: _category,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: HabitCategory.values
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _category = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('habit-start-date'),
                      onPressed: _isSaving ? null : _chooseStartDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('Starts ${_formatDate(_startDate)}'),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_errorMessage != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                          semanticsLabel: 'Form error: $_errorMessage',
                        ),
                      ),
                    ),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cancelButton = OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      );
                      final saveButton = FilledButton.icon(
                        key: const Key('habit-save'),
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          _isSaving
                              ? 'Saving'
                              : widget.habit == null
                              ? 'Create habit'
                              : 'Save',
                        ),
                      );
                      if (constraints.maxWidth < 340) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            saveButton,
                            const SizedBox(height: 8),
                            cancelButton,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: cancelButton),
                          const SizedBox(width: 12),
                          Expanded(child: saveButton),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
