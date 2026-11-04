class AIService {
  Future<String> sendMessage(String message) => Future.error(
    const AIServiceUnavailableException(
      'AI is not connected in this build. Your message was not sent.',
    ),
  );
}

class AIServiceUnavailableException implements Exception {
  const AIServiceUnavailableException(this.message);

  final String message;
}
