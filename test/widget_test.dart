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
    await tester.pumpAndSettle();

    // Verify app title is visible
    expect(find.text('LifePilot'), findsOneWidget);
    
    // Verify greeting is visible
    expect(find.text('Good Morning 👋'), findsOneWidget);
  });
}
