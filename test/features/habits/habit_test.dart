import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/core/utils/date_utils.dart';
import 'package:lifepilot/features/habits/models/habit.dart';
import 'package:lifepilot/features/habits/screens/habit_screen.dart';
import 'package:lifepilot/features/habits/services/habit_service.dart';
import 'package:lifepilot/features/tasks/models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('habit creation validates and displays the new habit', (
    tester,
  ) async {
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

  testWidgets('habit completion persists for the current day', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HabitScreen(userId: 'test-user')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add habit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Walk');
    await tester.tap(find.text('Create habit'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mark complete'));
    await tester.pumpAndSettle();

    final habit = (await HabitService(userId: 'test-user').loadHabits()).single;
    final today = DateTime.now();
    expect(
      habit.completedDates,
      contains(DateTime(today.year, today.month, today.day)),
    );
    expect(find.byTooltip('Mark incomplete'), findsOneWidget);
  });

  testWidgets('habit form saves all details and custom weekdays', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HabitScreen(userId: 'details-user')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add habit'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('habit-name')),
      'Daily Exercise',
    );
    await tester.enterText(
      find.byKey(const Key('habit-description')),
      'Move for at least 30 minutes.',
    );
    await tester.enterText(find.byKey(const Key('habit-duration')), '30');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('habit-frequency')));
    await tester.tap(find.byKey(const Key('habit-frequency')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom days').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Monday'));
    await tester.tap(find.widgetWithText(FilterChip, 'Monday'));
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Wednesday'));
    await tester.tap(find.widgetWithText(FilterChip, 'Wednesday'));
    await tester.ensureVisible(find.byKey(const Key('habit-duration-unit')));
    await tester.tap(find.byKey(const Key('habit-duration-unit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hours').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('habit-category')));
    await tester.tap(find.byKey(const Key('habit-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fitness').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create habit'));
    await tester.pumpAndSettle();

    final habit = (await HabitService(
      userId: 'details-user',
    ).loadHabits()).single;
    final today = DateTime.now();
    expect(habit.name, 'Daily Exercise');
    expect(habit.description, 'Move for at least 30 minutes.');
    expect(habit.frequency, HabitFrequency.customDays);
    expect(habit.selectedWeekdays, [DateTime.monday, DateTime.wednesday]);
    expect(habit.targetDuration, 30);
    expect(habit.durationUnit, HabitDurationUnit.hours);
    expect(habit.category, HabitCategory.fitness);
    expect(habit.startDate, DateTime(today.year, today.month, today.day));
    expect(habit.isScheduledOn(DateTime(2026, 11, 2)), isTrue);
    expect(habit.isScheduledOn(DateTime(2026, 11, 3)), isFalse);
  });

  testWidgets('custom schedule and duration validation prevent invalid saves', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HabitScreen(userId: 'validation-user')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add habit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('habit-name')), 'Stretch');
    await tester.enterText(find.byKey(const Key('habit-duration')), '0');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('habit-save')));
    await tester.pumpAndSettle();
    expect(
      find.text('Target duration must be greater than zero.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('habit-duration')), '15');
    await tester.ensureVisible(find.byKey(const Key('habit-frequency')));
    await tester.tap(find.byKey(const Key('habit-frequency')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom days').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('habit-save')));
    await tester.pumpAndSettle();
    expect(find.text('Select at least one weekday.'), findsOneWidget);
    expect(await HabitService(userId: 'validation-user').loadHabits(), isEmpty);
  });

  testWidgets(
    'habit form scrolls and keeps actions available on a small screen',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(640, 1280);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: const HabitScreen(userId: 'small-habit-user'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add habit'));
      await tester.pumpAndSettle();

      expect(find.text('Add Habit'), findsOneWidget);
      expect(find.byKey(const Key('habit-save')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('habit-start-date')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.byKey(const Key('habit-save')), findsOneWidget);
    },
  );

  testWidgets('editing habit details preserves completion history', (
    tester,
  ) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final existing = Habit(
      id: 'edit-habit',
      name: 'Old name',
      description: 'Old description',
      startDate: DateTime(yesterday.year, yesterday.month, yesterday.day),
      completedDates: [yesterday],
    );
    await HabitService(userId: 'edit-user').saveHabits([existing]);
    await tester.pumpWidget(
      const MaterialApp(home: HabitScreen(userId: 'edit-user')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Habit actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('habit-name')), 'New name');
    await tester.enterText(
      find.byKey(const Key('habit-description')),
      'New details',
    );
    await tester.tap(find.byKey(const Key('habit-save')));
    await tester.pumpAndSettle();

    final saved = (await HabitService(userId: 'edit-user').loadHabits()).single;
    expect(saved.name, 'New name');
    expect(saved.description, 'New details');
    expect(saved.completedDates, [
      DateTime(yesterday.year, yesterday.month, yesterday.day),
    ]);
    expect(saved.id, existing.id);
  });

  testWidgets('start date cannot move past recorded completions', (
    tester,
  ) async {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final yesterday = normalizedToday.subtract(const Duration(days: 1));
    final existing = Habit(
      id: 'start-date-habit',
      name: 'Walk',
      startDate: yesterday,
      completedDates: [yesterday],
    );
    final service = HabitService(userId: 'start-date-user');
    await service.saveHabits([existing]);
    await tester.pumpWidget(
      const MaterialApp(home: HabitScreen(userId: 'start-date-user')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Habit actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('habit-start-date')),
      240,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('habit-start-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${normalizedToday.day}').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('habit-save')));
    await tester.pumpAndSettle();

    expect(
      find.text('Start date cannot be after a recorded completion.'),
      findsOneWidget,
    );
    final saved = (await service.loadHabits()).single;
    expect(saved.startDate, yesterday);
    expect(saved.completedDates, [yesterday]);
  });

  testWidgets('habit menu deletion confirms and removes only that habit', (
    tester,
  ) async {
    final service = HabitService(userId: 'delete-user');
    await service.saveHabits([
      Habit(id: 'delete-one', name: 'Remove this'),
      Habit(id: 'keep-one', name: 'Keep this'),
    ]);
    await tester.pumpWidget(
      const MaterialApp(home: HabitScreen(userId: 'delete-user')),
    );
    await tester.pumpAndSettle();

    final menu = find.byTooltip('Habit actions').first;
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await tester.pumpAndSettle();

    final remaining = await service.loadHabits();
    expect(remaining.map((habit) => habit.id), ['keep-one']);
  });

  test(
    'habit JSON restores all fields and legacy records keep their history',
    () async {
      final start = DateTime(2026, 10, 1);
      final habit = Habit(
        id: 'full',
        name: 'Study',
        description: 'Read one chapter',
        frequency: HabitFrequency.customDays,
        selectedWeekdays: [DateTime.monday, DateTime.friday],
        targetDuration: 1.5,
        durationUnit: HabitDurationUnit.hours,
        category: HabitCategory.learning,
        startDate: start,
        completedDates: [DateTime(2026, 10, 2)],
      );
      final restored = Habit.fromJson(habit.toJson());

      expect(restored.description, habit.description);
      expect(restored.frequency, HabitFrequency.customDays);
      expect(restored.selectedWeekdays, [DateTime.monday, DateTime.friday]);
      expect(restored.targetDuration, 1.5);
      expect(restored.durationUnit, HabitDurationUnit.hours);
      expect(restored.category, HabitCategory.learning);
      expect(restored.startDate, start);
      expect(restored.completedDates, habit.completedDates);

      final legacyDate = DateTime(2026, 9, 12);
      SharedPreferences.setMockInitialValues({
        'habits_legacy-user': [
          jsonEncode({
            'id': 'legacy',
            'name': 'Legacy habit',
            'completedDates': [legacyDate.toIso8601String()],
          }),
        ],
      });
      final legacy = (await HabitService(
        userId: 'legacy-user',
      ).loadHabits()).single;
      expect(legacy.name, 'Legacy habit');
      expect(legacy.description, isEmpty);
      expect(legacy.frequency, HabitFrequency.daily);
      expect(legacy.category, HabitCategory.personal);
      expect(legacy.targetDuration, isNull);
      expect(legacy.startDate, legacyDate);
      expect(legacy.completedDates, [legacyDate]);
    },
  );

  test(
    'habit service updates without losing history and deletes only one habit',
    () async {
      final service = HabitService(userId: 'crud-user');
      final start = DateTime(2026, 10, 1);
      await service.saveHabits([
        Habit(
          id: 'keep',
          name: 'Before edit',
          startDate: start,
          completedDates: [DateTime(2026, 10, 2)],
        ),
        Habit(id: 'delete', name: 'Remove me'),
      ]);

      await service.updateHabit(
        Habit(
          id: 'keep',
          name: 'After edit',
          description: 'Updated details',
          startDate: start,
        ),
      );
      await service.deleteHabit('delete');

      final remaining = await service.loadHabits();
      expect(remaining, hasLength(1));
      expect(remaining.single.id, 'keep');
      expect(remaining.single.name, 'After edit');
      expect(remaining.single.completedDates, [DateTime(2026, 10, 2)]);
    },
  );

  test(
    'completion rejects dates before start and prevents duplicates',
    () async {
      final habit = Habit(
        id: 'completion',
        name: 'Read',
        startDate: DateTime(2026, 11, 4),
      );
      expect(habit.markCompleted(DateTime(2026, 11, 3)), isFalse);
      expect(habit.markCompleted(DateTime(2026, 11, 4)), isTrue);
      expect(habit.markCompleted(DateTime(2026, 11, 4, 18)), isFalse);
      expect(habit.completedDates, [DateTime(2026, 11, 4)]);
      expect(habit.undoCompletion(DateTime(2026, 11, 4)), isTrue);
      expect(habit.completedDates, isEmpty);
    },
  );

  test('service persists and undoes completion dates', () async {
    final service = HabitService(userId: 'service-completion-user');
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    await service.addHabit(
      Habit(id: 'service-completion', name: 'Write', startDate: date),
    );

    expect(await service.markCompleted('service-completion', date), isTrue);
    expect(await service.markCompleted('service-completion', date), isFalse);
    expect((await service.loadHabits()).single.completedDates, [date]);
    expect(await service.undoCompletion('service-completion', date), isTrue);
    expect((await service.loadHabits()).single.completedDates, isEmpty);
  });

  test('service refuses blank names and empty custom schedules', () async {
    final service = HabitService(userId: 'invalid-service-user');
    await expectLater(
      service.addHabit(Habit(id: 'blank', name: '  ')),
      throwsArgumentError,
    );
    await expectLater(
      service.addHabit(
        Habit(
          id: 'no-days',
          name: 'Walk',
          frequency: HabitFrequency.customDays,
        ),
      ),
      throwsArgumentError,
    );
    expect(await service.loadHabits(), isEmpty);
  });

  test('habit start date cannot follow an existing completion', () {
    expect(
      () => Habit(
        id: 'invalid-start',
        name: 'Walk',
        startDate: DateTime(2026, 11, 4),
        completedDates: [DateTime(2026, 11, 3)],
      ),
      throwsArgumentError,
    );
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
