import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({required this.userId, super.key});

  final String userId;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selected = DateTime(2026, 8, 8);
  bool _monthView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
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
                onSelected: (date) => setState(() => _selected = date),
              )
            else
              _WeekCalendar(selected: _selected),
            const Divider(height: 28),
            Text(
              'Tasks for ${_selected.month}/${_selected.day}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.accentOrangeTint,
                  child: Icon(
                    Icons.work_outline,
                    color: AppColors.accentOrange,
                  ),
                ),
                title: Text('Team sync call'),
                subtitle: Text('10:00 AM'),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.selected, required this.onSelected});
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(42, (index) => DateTime(2026, 7, 27 + index));
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.chevron_left),
            const Spacer(),
            Text('August 2026', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            const Icon(Icons.chevron_right),
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
            final active =
                day.year == selected.year &&
                day.month == selected.month &&
                day.day == selected.day;
            final color = active
                ? Colors.white
                : day.month == 8
                ? AppColors.textPrimary
                : AppColors.textFaint;
            return GestureDetector(
              onTap: () => onSelected(day),
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: color,
                          fontWeight: active ? FontWeight.w800 : null,
                        ),
                      ),
                    ),
                  ),
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
  const _WeekCalendar({required this.selected});
  final DateTime selected;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(7, (index) {
      final date = selected.subtract(
        Duration(days: selected.weekday - 1 - index),
      );
      return Column(
        children: [
          Text(
            ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          CircleAvatar(
            backgroundColor: index == selected.weekday - 1
                ? AppColors.primary
                : AppColors.primaryTint,
            foregroundColor: index == selected.weekday - 1
                ? Colors.white
                : AppColors.textPrimary,
            child: Text('${date.day}'),
          ),
        ],
      );
    }),
  );
}
