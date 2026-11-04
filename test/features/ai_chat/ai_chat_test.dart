import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/features/ai_chat/screens/ai_chat_screen.dart';
import '../../helpers/fake_api.dart';

void main() {
  setUp(() => installFakeApi());

  testWidgets('chat submits a message to the backend', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AiChatScreen()));

    expect(find.text('Saved context'), findsOneWidget);
    expect(find.textContaining('backend'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Plan my day');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();

    expect(find.text('Plan my day'), findsOneWidget);
    expect(find.text('Test response'), findsOneWidget);
    expect(
      find.text('Done - I can help turn that into a clear next step.'),
      findsNothing,
    );
  });
}
