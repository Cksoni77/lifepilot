import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/models/task.dart';

void main() {
  group('Task due date status', () {
    test(
      'marks overdue tasks when due date is before today and task is incomplete',
      () {
        final task = Task(
          id: 'task-001',
          title: 'Submit report',
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(task.status(), TaskStatus.overdue);
        expect(task.statusLabel, 'Overdue');
      },
    );

    test(
      'marks due today tasks when due date matches today and task is incomplete',
      () {
        final task = Task(
          id: 'task-002',
          title: 'Prepare slides',
          dueDate: DateTime.now(),
        );

        expect(task.status(), TaskStatus.dueToday);
        expect(task.statusLabel, 'Due Today');
      },
    );

    test(
      'returns none for completed tasks even if due date is in the past',
      () {
        final task = Task(
          id: 'task-003',
          title: 'Archive notes',
          completed: true,
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(task.status(), TaskStatus.none);
        expect(task.statusLabel, '');
      },
    );
  });
}