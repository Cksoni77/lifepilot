import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lifepilot/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app loads successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LifePilotApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('LifePilot'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
