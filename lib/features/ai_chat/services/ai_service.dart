import '../../../core/network/api_client.dart';

class AIService {
  AIService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  final ApiClient _apiClient;

  Future<String> sendMessage(String message) async {
    try {
      final response =
          await _apiClient.post('/api/ai/chat', body: {'message': message})
              as Map<String, dynamic>;
      final content = response['message'];
      if (content is! String || content.trim().isEmpty) {
        throw const AIServiceUnavailableException(
          'The AI service returned an empty response.',
        );
      }
      return content;
    } on ApiException catch (error) {
      throw AIServiceUnavailableException(error.message);
    }
  }
}

class AIServiceUnavailableException implements Exception {
  const AIServiceUnavailableException(this.message);

  final String message;
}
