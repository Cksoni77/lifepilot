import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/date_utils.dart';

enum CalendarViewMode { month, week }

class CalendarView extends StatelessWidget {
  const CalendarView({
    required this.displayedMonth,
    required this.selectedDate,
    required this.tasks,
    required this.mode,
    required this.onDateSelected,
    super.key,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;
  final List<Task> tasks;
  final CalendarViewMode mode;
  final ValueChanged<DateTime> onDateSelected;

  int _taskCount(DateTime date) {
    return tasks.where((task) => task.dueDate != null && isSameDay(task.dueDate!, date)).length;
  }

  @override
  Widget build(BuildContext context) {
    final dates = mode == CalendarViewMode.month
        ? _monthDates(displayedMonth)
        : List<DateTime>.generate(
            7,
            (index) => mondayOfWeek(selectedDate).add(Duration(days: index)),
          );

    return Column(
      children: [
        if (mode == CalendarViewMode.month)
          Row(
            children: const [
              Expanded(child: Center(child: Text('Mon'))),
              Expanded(child: Center(child: Text('Tue'))),
              Expanded(child: Center(child: Text('Wed'))),
              Expanded(child: Center(child: Text('Thu'))),
              Expanded(child: Center(child: Text('Fri'))),
              Expanded(child: Center(child: Text('Sat'))),
              Expanded(child: Center(child: Text('Sun'))),
            ],
          ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dates.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: mode == CalendarViewMode.month ? 7 : 1,
            mainAxisExtent: mode == CalendarViewMode.month ? 58 : 72,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final date = dates[index];
            final count = _taskCount(date);
            final isSelected = isSameDay(date, selectedDate);
            final isToday = isSameDay(date, DateTime.now());
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onDateSelected(date),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  border: Border.all(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: mode == CalendarViewMode.month
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontWeight: isToday || isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (count > 0)
                            Text(
                              '● $count',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_weekdayName(date.weekday)} ${date.day} ${shortMonthName(date.month)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (count > 0)
                            Chip(
                              label: Text('$count task${count == 1 ? '' : 's'}'),
                              visualDensity: VisualDensity.compact,
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

  List<DateTime> _monthDates(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final leadingDays = first.weekday - DateTime.monday;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    return List<DateTime>.generate(
      cellCount,
      (index) => first.add(Duration(days: index - leadingDays)),
    );
  }

  String _weekdayName(int weekday) {
    const names = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }
}
