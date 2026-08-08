import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/models/user_preferences.dart';
import 'package:lifepilot/services/auth_service.dart';
import 'package:lifepilot/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('register, login, session, and logout use local storage', () async {
    final auth = AuthService();
    final user = await auth.register(
      name: 'Chhotu Soni',
      email: 'user@email.com',
      password: 'password123',
    );

    expect(user.email, 'user@email.com');
    expect(await auth.isLoggedIn(), isTrue);
    expect((await auth.currentUser())?.name, 'Chhotu Soni');
    expect(await auth.login(email: 'user@email.com', password: 'wrong'), isNull);
    expect(await auth.login(email: 'user@email.com', password: 'password123'), isNotNull);

    await auth.logout();
    expect(await auth.isLoggedIn(), isFalse);
    expect(await auth.currentUser(), isNull);
  });

  test('preferences round-trip with theme and notification settings', () async {
    final service = UserService();
    const preferences = UserPreferences(
      theme: 'dark',
      notificationsEnabled: false,
      reminderEnabled: true,
    );

    await service.savePreferences(preferences);
    final restored = await service.loadPreferences();

    expect(restored.theme, 'dark');
    expect(restored.notificationsEnabled, isFalse);
    expect(restored.reminderEnabled, isTrue);
  });
}