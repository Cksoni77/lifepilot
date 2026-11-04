import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/features/auth/screens/sign_in_screen.dart';
import 'package:lifepilot/features/auth/services/auth_service.dart';
import 'package:lifepilot/features/profile/screens/profile_screen.dart';
import 'package:lifepilot/shared_controllers/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('confirmed logout clears session and opens sign in', (
    tester,
  ) async {
    await AuthService().register(
      name: 'Profile User',
      email: 'profile@example.com',
      password: 'password123',
    );
    final controller = AppController();
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(
      AppControllerScope(
        notifier: controller,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Log out'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    final confirmation = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Log out'),
    );
    await tester.tap(confirmation);
    await tester.pumpAndSettle();

    expect(controller.user, isNull);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
