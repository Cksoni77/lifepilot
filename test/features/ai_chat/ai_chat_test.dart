import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifepilot/features/ai_chat/screens/ai_chat_screen.dart';

void main() {
  testWidgets('chat reports that no AI provider is configured', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AiChatScreen()));

    expect(find.text('Not connected'), findsOneWidget);
    expect(find.textContaining('Messages will not be sent'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Plan my day');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();

    expect(find.text('Plan my day'), findsOneWidget);
    expect(
      find.text(
        'AI is not connected in this build. Your message was not sent.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Done - I can help turn that into a clear next step.'),
      findsNothing,
    );
  });
}
