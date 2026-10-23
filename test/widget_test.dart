import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lifepilot/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app shows splash screen and then login screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'onboardingCompleted': true,
    });

    await tester.pumpWidget(const LifePilotApp());
    await tester.pump();

    expect(find.text('LifePilot'), findsOneWidget);
    expect(find.text('Your day, gently organized'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('app shows onboarding when onboarding is not completed', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'onboardingCompleted': false,
    });

    await tester.pumpWidget(const LifePilotApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Plan your whole life in one place'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
