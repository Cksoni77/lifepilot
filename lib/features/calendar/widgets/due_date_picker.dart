import 'package:flutter/material.dart';

class DueDatePicker extends StatelessWidget {
  const DueDatePicker({required this.date, required this.onChanged, super.key});
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(
      date == null
          ? 'Choose due date'
          : '${date!.year}-${date!.month}-${date!.day}',
    ),
    onTap: () async {
      final value = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        initialDate: date ?? DateTime.now(),
      );
      onChanged(value);
    },
  );
}
