import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/features/calendar/screens/calendar_screen.dart';
import 'package:lifepilot/features/tasks/models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/fake_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installFakeApi();
  });

  testWidgets('calendar shows persisted tasks and supports month navigation', (
    tester,
  ) async {
    final now = DateTime.now();
    final task = Task(
      id: 'calendar-task',
      title: 'Review dissertation',
      dueDate: DateTime(now.year, now.month, now.day, 15),
    );
    installFakeApi(tasks: [task.toJson()]);
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: CalendarScreen(userId: 'user-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review dissertation'), findsOneWidget);
    expect(find.text('Team sync call'), findsNothing);

    final month = const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][now.month - 1];
    expect(find.text('$month ${now.year}'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Next month'));
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();

    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    expect(
      find.text(
        '${['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][nextMonth - 1]} $nextYear',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
