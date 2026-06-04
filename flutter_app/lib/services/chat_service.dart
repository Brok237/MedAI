// lib/services/chat_service.dart

import 'api_client.dart';

class ChatService {
  // ==========================
  // CASE CHATBOT
  // ==========================

  static Future<Map<String, dynamic>> sendCaseMessage({
    required String message,
    String? sessionId,
    String? caseId,
    String language = 'en',
  }) async {
    return ApiClient.post(
      '/chat/case/',
      {
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
        if (caseId != null) 'case_id': caseId,
        'language': language,
      },
    );
  }

  // ==========================
  // GENERAL MEDICAL CHATBOT
  // ==========================

  static Future<Map<String, dynamic>> sendGeneralMessage({
    required String message,
    String? sessionId,
    String language = 'en',
  }) async {
    return ApiClient.post(
      '/chat/general/',
      {
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
        'language': language,
      },
    );
  }

  // ==========================
  // SESSIONS
  // ==========================

  static Future<List<Map<String, dynamic>>> getSessions() async {
    final response = await ApiClient.get('/chat/sessions/');
    return List<Map<String, dynamic>>.from(
      response['results'] ?? [],
    );
  }

  static Future<Map<String, dynamic>> getSessionHistory(
    String sessionId,
  ) async {
    return ApiClient.get(
      '/chat/sessions/$sessionId/',
    );
  }
}
