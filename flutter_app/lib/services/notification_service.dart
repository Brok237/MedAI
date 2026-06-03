// lib/services/notification_service.dart
// Connects to Django /api/v1/notifications/ endpoints

import '../models/case_model.dart';
import 'api_client.dart';

class NotificationService {
  static Future<Map<String, dynamic>> getNotifications() async {
    return ApiClient.get('/notifications/');
  }

  static Future<void> markAllRead() async {
    await ApiClient.post('/notifications/read-all/', {});
  }

  static Future<void> markOneRead(String notifId) async {
    await ApiClient.post('/notifications/$notifId/read/', {});
  }

  static Future<List<NotificationModel>> fetchAll() async {
    final response = await getNotifications();
    final results = response['results'] as List<dynamic>? ?? [];
    return results
        .map((j) => NotificationModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
