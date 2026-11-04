import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/features/goals/screens/goals_screen.dart';
import 'package:lifepilot/features/goals/services/goal_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('goal creation validates and persists user-scoped goal data', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GoalsScreen(userId: 'goal-user')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a goal'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Finish dissertation');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Finish dissertation'), findsOneWidget);
    final stored = await GoalService(userId: 'goal-user').loadGoals();
    expect(stored.single.title, 'Finish dissertation');
  });
}
