import 'package:flutter/material.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({
    required this.selectedDay,
    required this.onDaySelected,
    super.key,
  });
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) => CalendarDatePicker(
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
    initialDate: selectedDay,
    onDateChanged: onDaySelected,
  );
}
