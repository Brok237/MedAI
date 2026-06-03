// lib/services/chat_service.dart
// Connects to Django /api/v1/chat/ endpoints

import 'api_client.dart';

class ChatService {
  // ── Send a message ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> sendMessage({
    required String message,
    String? sessionId,
    String? caseId,
    String language = 'en',
  }) async {
    return ApiClient.post('/chat/', {
      'message': message,
      if (sessionId != null) 'session_id': sessionId,
      if (caseId != null) 'case_id': caseId,
      'language': language,
    });
  }

  // ── List sessions ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getSessions() async {
    final response = await ApiClient.get('/chat/sessions/');
    return List<Map<String, dynamic>>.from(response['results'] ?? []);
  }

  // ── Get session history ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getSessionHistory(String sessionId) async {
    return ApiClient.get('/chat/sessions/$sessionId/');
  }
}
