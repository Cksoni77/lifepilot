class AIService {
  Future<String> sendMessage(String message) async {
    // Temporary implementation.
    // Real AI API integration will be added later.

    await Future.delayed(
      const Duration(seconds: 1),
    );

    return _generateDemoResponse(message);
  }

  String _generateDemoResponse(String message) {
    final text = message.toLowerCase();

    if (text.contains('plan my day')) {
      return '''
Sure! I can help you plan your day.

For the next version, I will use your tasks, calendar, habits and preferences to create a personalized plan.
''';
    }

    if (text.contains('task')) {
      return '''
I can help you organize your tasks.

In the next AI phase, I will be able to understand your existing LifePilot tasks and suggest priorities.
''';
    }

    if (text.contains('habit')) {
      return '''
I can help you build better habits.

Later, I will use your habit history and streaks to provide personalized suggestions.
''';
    }

    return '''
I'm your LifePilot AI assistant.

You can ask me things like:

• Plan my day
• Help me prioritize my tasks
• How can I build a better habit?
• Help me organize my day
''';
  }
}