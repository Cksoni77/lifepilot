import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/features/tasks/models/task.dart';

void main() {
  group('Task status', () {
    test(
      'marks overdue incomplete task',
      () {
        final task = Task(
          id: '1',
          title: 'Submit report',
          dueDate: DateTime(2026, 8, 15),
        );

        expect(
          task.status(
            asOf: DateTime(2026, 8, 16),
          ),
          TaskStatus.overdue,
        );

        expect(
          task.statusLabel,
          'Overdue',
        );
      },
    );

    test(
      'marks task due today',
      () {
        final task = Task(
          id: '2',
          title: 'Prepare slides',
          dueDate: DateTime(2026, 8, 16),
        );

        expect(
          task.status(
            asOf: DateTime(2026, 8, 16),
          ),
          TaskStatus.dueToday,
        );

        expect(
          task.statusLabel,
          'Due Today',
        );
      },
    );

    test(
      'returns none for completed overdue task',
      () {
        final task = Task(
          id: '3',
          title: 'Archive notes',
          completed: true,
          dueDate: DateTime(2026, 8, 15),
        );

        expect(
          task.status(
            asOf: DateTime(2026, 8, 16),
          ),
          TaskStatus.none,
        );
      },
    );

    test(
      'returns none for future task',
      () {
        final task = Task(
          id: '4',
          title: 'Plan meeting',
          dueDate: DateTime(2026, 8, 20),
        );

        expect(
          task.status(
            asOf: DateTime(2026, 8, 16),
          ),
          TaskStatus.none,
        );
      },
    );
  });

  group('Task JSON', () {
    test(
      'serializes and restores task',
      () {
        final original = Task(
          id: 'task-001',
          title: 'Finish project',
          description: 'Final project work',
          category: TaskCategory.work,
          priority: TaskPriority.high,
          completed: false,
          dueDate: DateTime(2026, 8, 20, 17),
          reminderDate:
              DateTime(2026, 8, 20, 16),
          reminderEnabled: true,
          estimatedMinutes: 120,
        );

        final json = original.toJson();

        final restored =
            Task.fromJson(json);

        expect(
          restored.id,
          original.id,
        );

        expect(
          restored.title,
          original.title,
        );

        expect(
          restored.description,
          original.description,
        );

        expect(
          restored.category,
          TaskCategory.work,
        );

        expect(
          restored.priority,
          TaskPriority.high,
        );

        expect(
          restored.estimatedMinutes,
          120,
        );

        expect(
          restored.reminderEnabled,
          true,
        );
      },
    );
  });

  group('Task AI context', () {
    test(
      'creates AI-friendly context',
      () {
        final task = Task(
          id: 'task-ai',
          title: 'Complete report',
          category: TaskCategory.work,
          priority: TaskPriority.high,
          dueDate: DateTime(2026, 8, 16),
          estimatedMinutes: 90,
        );

        final context =
            task.toAIContext();

        expect(
          context['id'],
          'task-ai',
        );

        expect(
          context['title'],
          'Complete report',
        );

        expect(
          context['category'],
          'Work',
        );

        expect(
          context['priority'],
          'high',
        );

        expect(
          context['estimatedMinutes'],
          90,
        );

        expect(
          context['completed'],
          false,
        );
      },
    );
  });

  group('Task helpers', () {
    test(
      'detects due date',
      () {
        final task = Task(
          id: '1',
          title: 'Test',
          dueDate:
              DateTime(2026, 8, 20),
        );

        expect(
          task.hasDueDate,
          true,
        );
      },
    );

    test(
      'detects reminder',
      () {
        final task = Task(
          id: '1',
          title: 'Test',
          reminderDate:
              DateTime(2026, 8, 20, 10),
          reminderEnabled: true,
        );

        expect(
          task.hasReminder,
          true,
        );
      },
    );
  });
}