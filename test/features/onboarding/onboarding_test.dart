import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/features/auth/screens/onboarding_screen.dart';

void main() {
  testWidgets(
    'onboarding shows first page',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      expect(
        find.text('Plan your whole life in one place'),
        findsOneWidget,
      );

      expect(
        find.text('Continue'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'onboarding moves to second page',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      await tester.tap(
        find.text('Continue'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Build habits that actually stick'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'onboarding moves to third page',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      await tester.tap(
        find.text('Continue'),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.text('Continue'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Meet your AI co-pilot'),
        findsOneWidget,
      );

      expect(
        find.text('Get started'),
        findsOneWidget,
      );
    },
  );
}