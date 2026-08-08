import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/models/habit.dart';
import 'package:lifepilot/models/task.dart';
import 'package:lifepilot/screens/habit_screen.dart';
import 'package:lifepilot/utils/date_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('habit creation validates and displays the new habit', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HabitScreen(userId: 'test-user')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add habit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create habit'));
    await tester.pump();
    expect(find.text('Give your habit a name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Read daily');
    await tester.tap(find.text('Create habit'));
    await tester.pumpAndSettle();
    expect(find.text('Read daily'), findsOneWidget);
    expect(find.text('Read daily added to your habits.'), findsOneWidget);
  });

  group('Habit streaks', () {
    final referenceDate = DateTime(2026, 8, 8);

    test('counts the current consecutive run ending today', () {
      final habit = Habit(
        id: 'habit-001',
        name: 'Read',
        completedDates: [
          DateTime(2026, 8, 6),
          DateTime(2026, 8, 7),
          referenceDate,
        ],
      );

      expect(habit.currentStreak(asOf: referenceDate), 3);
      expect(habit.longestStreak(), 3);
    });

    test('uses yesterday when today is not completed', () {
      final habit = Habit(
        id: 'habit-002',
        name: 'Exercise',
        completedDates: [
          DateTime(2026, 8, 5),
          DateTime(2026, 8, 6),
          DateTime(2026, 8, 7),
        ],
      );

      expect(habit.currentStreak(asOf: referenceDate), 3);
    });

    test('longest streak remains separate after a missed day', () {
      final habit = Habit(
        id: 'habit-003',
        name: 'Plan',
        completedDates: [
          DateTime(2026, 8, 1),
          DateTime(2026, 8, 2),
          DateTime(2026, 8, 4),
          DateTime(2026, 8, 5),
          DateTime(2026, 8, 6),
        ],
      );

      expect(habit.longestStreak(), 3);
      expect(habit.currentStreak(asOf: referenceDate), 0);
    });
  });

  test('normalizes dates and preserves task IDs during serialization', () {
    final habit = Habit(
      id: 'habit-004',
      name: 'Journal',
      completedDates: [DateTime(2026, 8, 8, 18, 30)],
    );
    final restoredHabit = Habit.fromJson(habit.toJson());
    final task = Task(id: 'task-004', title: 'Calendar task');
    final restoredTask = Task.fromJson(task.toJson()..['id'] = task.id);

    expect(restoredHabit.completedDates.single, DateTime(2026, 8, 8));
    expect(restoredTask.id, 'task-004');
    expect(mondayOfWeek(DateTime(2026, 8, 8)), DateTime(2026, 8, 3));
    expect(isSameDay(DateTime(2026, 8, 8, 12), DateTime(2026, 8, 8)), isTrue);
  });
}
