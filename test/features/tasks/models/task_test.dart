import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/features/tasks/models/task.dart';

void main() {
  group('Task status', () {
    test('statusLabel reflects today and overdue dates relative to now', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final overdueTask = Task(
        id: 'overdue',
        title: 'Pay invoice',
        dueDate: today.subtract(const Duration(days: 1)),
      );

      final dueTodayTask = Task(
        id: 'today',
        title: 'Review plan',
        dueDate: today,
      );

      expect(overdueTask.status(asOf: today), TaskStatus.overdue);
      expect(overdueTask.statusLabel, 'Overdue');

      expect(dueTodayTask.status(asOf: today), TaskStatus.dueToday);
      expect(dueTodayTask.statusLabel, 'Due Today');
    });

    test('marks overdue incomplete task', () {
      final today = DateTime.now();
      final asOf = DateTime(today.year, today.month, today.day);

      final task = Task(
        id: '1',
        title: 'Submit report',
        dueDate: asOf.subtract(const Duration(days: 1)),
      );

      expect(task.status(asOf: asOf), TaskStatus.overdue);

      expect(task.statusLabel, 'Overdue');
    });

    test('marks task due today', () {
      final today = DateTime.now();
      final asOf = DateTime(today.year, today.month, today.day);

      final task = Task(id: '2', title: 'Prepare slides', dueDate: asOf);

      expect(task.status(asOf: asOf), TaskStatus.dueToday);

      expect(task.statusLabel, 'Due Today');
    });

    test('returns none for completed overdue task', () {
      final today = DateTime.now();
      final asOf = DateTime(today.year, today.month, today.day);

      final task = Task(
        id: '3',
        title: 'Archive notes',
        completed: true,
        dueDate: asOf.subtract(const Duration(days: 1)),
      );

      expect(task.status(asOf: asOf), TaskStatus.none);
    });

    test('returns none for future task', () {
      final today = DateTime.now();
      final asOf = DateTime(today.year, today.month, today.day);

      final task = Task(
        id: '4',
        title: 'Plan meeting',
        dueDate: asOf.add(const Duration(days: 4)),
      );

      expect(task.status(asOf: asOf), TaskStatus.none);
    });
  });

  group('Task JSON', () {
    test('serializes and restores task', () {
      final original = Task(
        id: 'task-001',
        title: 'Finish project',
        description: 'Final project work',
        category: TaskCategory.work,
        priority: TaskPriority.high,
        completed: false,
        dueDate: DateTime(2026, 8, 20, 17),
        reminderDate: DateTime(2026, 8, 20, 16),
        reminderEnabled: true,
        estimatedMinutes: 120,
      );

      final json = original.toJson();

      final restored = Task.fromJson(json);

      expect(restored.id, original.id);

      expect(restored.title, original.title);

      expect(restored.description, original.description);

      expect(restored.category, TaskCategory.work);

      expect(restored.priority, TaskPriority.high);

      expect(restored.estimatedMinutes, 120);

      expect(restored.reminderEnabled, true);
    });
  });

  group('Task AI context', () {
    test('creates AI-friendly context', () {
      final task = Task(
        id: 'task-ai',
        title: 'Complete report',
        category: TaskCategory.work,
        priority: TaskPriority.high,
        dueDate: DateTime(2026, 8, 16),
        estimatedMinutes: 90,
      );

      final context = task.toAIContext();

      expect(context['id'], 'task-ai');

      expect(context['title'], 'Complete report');

      expect(context['category'], 'Work');

      expect(context['priority'], 'high');

      expect(context['estimatedMinutes'], 90);

      expect(context['completed'], false);
    });
  });

  group('Task helpers', () {
    test('detects due date', () {
      final task = Task(id: '1', title: 'Test', dueDate: DateTime(2026, 8, 20));

      expect(task.hasDueDate, true);
    });

    test('detects reminder', () {
      final task = Task(
        id: '1',
        title: 'Test',
        reminderDate: DateTime(2026, 8, 20, 10),
        reminderEnabled: true,
      );

      expect(task.hasReminder, true);
    });
  });
}
