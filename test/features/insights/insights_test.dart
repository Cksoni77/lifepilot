import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/features/habits/models/habit.dart';
import 'package:lifepilot/features/insights/screens/insights_screen.dart';
import 'package:lifepilot/features/tasks/models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/fake_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installFakeApi();
  });

  testWidgets(
    'insights use saved activity and remain usable on a small screen',
    (tester) async {
      final now = DateTime.now();
      final tasks = [
        Task(
          id: 'done',
          title: 'Completed task',
          completed: true,
          createdAt: now,
          completedAt: now,
        ),
        Task(id: 'pending', title: 'Pending task', createdAt: now),
      ];
      final habit = Habit(
        id: 'habit',
        name: 'Walk',
        completedDates: [now.subtract(const Duration(days: 1)), now],
      );
      installFakeApi(
        tasks: tasks.map((task) => task.toJson()).toList(),
        habits: [habit.toJson()],
      );
      tester.view.physicalSize = const Size(640, 1280);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: InsightsScreen(userId: 'insights-user')),
      );
      await tester.pumpAndSettle();

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('2 days'), findsOneWidget);
      await tester.tap(find.text('Year'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
