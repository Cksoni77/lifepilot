import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/features/tasks/models/task.dart';
import 'package:lifepilot/features/tasks/screens/task_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/fake_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installFakeApi();
  });

  testWidgets('task actions open the prefilled edit sheet', (tester) async {
    final task = Task(id: 'task-1', title: 'Review dissertation');
    installFakeApi(tasks: [task.toJson()]);

    await tester.pumpWidget(
      const MaterialApp(home: TaskListScreen(userId: 'user-1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Task actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit task'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Task title' &&
            widget.controller?.text == 'Review dissertation',
      ),
      findsOneWidget,
    );
  });

  testWidgets('task sheet fits a compact phone viewport', (tester) async {
    installFakeApi();
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: TaskListScreen(userId: 'small-screen-user')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('New task'), findsOneWidget);
    await tester.ensureVisible(find.text('Add task'));
    expect(tester.takeException(), isNull);
  });
}
