import 'package:flutter/material.dart';

import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/habits/screens/habit_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/goals/screens/goals_screen.dart';
import '../features/insights/screens/insights_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/screens/profile_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const calendar = '/calendar';
  static const habits = '/habits';
  static const profile = '/profile';
  static const goals = '/goals';
  static const insights = '/insights';
  static const notifications = '/notifications';

  static final onboardingRoute = MaterialPageRoute<void>(
    settings: const RouteSettings(name: onboarding),
    builder: (_) => const OnboardingScreen(),
  );

  static Route<void> homeRoute(String userId) => MaterialPageRoute<void>(
    settings: const RouteSettings(name: home),
    builder: (_) => HomeScreen(userId: userId),
  );

  static Route<void> calendarRoute(String userId) => MaterialPageRoute<void>(
    settings: const RouteSettings(name: calendar),
    builder: (_) => CalendarScreen(userId: userId),
  );

  static Route<void> habitsRoute(String userId) => MaterialPageRoute<void>(
    settings: const RouteSettings(name: habits),
    builder: (_) => HabitScreen(userId: userId),
  );

  static final profileRoute = MaterialPageRoute<void>(
    settings: RouteSettings(name: profile),
    builder: _profileBuilder,
  );

  static final goalsRoute = MaterialPageRoute<void>(
    settings: const RouteSettings(name: goals),
    builder: (_) => const GoalsScreen(),
  );

  static final insightsRoute = MaterialPageRoute<void>(
    settings: const RouteSettings(name: insights),
    builder: (_) => const InsightsScreen(),
  );

  static final notificationsRoute = MaterialPageRoute<void>(
    settings: const RouteSettings(name: notifications),
    builder: (_) => const NotificationsScreen(),
  );

  static Widget _profileBuilder(BuildContext context) => const ProfileScreen();

  static final signInRoute = MaterialPageRoute<void>(
    settings: RouteSettings(name: signIn),
    builder: _signInBuilder,
  );

  static Widget _signInBuilder(BuildContext context) => const LoginScreen();

  static final signUpRoute = MaterialPageRoute<void>(
    settings: RouteSettings(name: signUp),
    builder: _signUpBuilder,
  );

  static Widget _signUpBuilder(BuildContext context) => const RegisterScreen();

  static final forgotPasswordRoute = MaterialPageRoute<void>(
    settings: RouteSettings(name: forgotPassword),
    builder: _forgotPasswordBuilder,
  );

  static Widget _forgotPasswordBuilder(BuildContext context) =>
      const ForgotPasswordScreen();
}
