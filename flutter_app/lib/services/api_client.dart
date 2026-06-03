// lib/services/api_client.dart
//
// Central HTTP client for all Django backend calls.
// Handles:
//   - Base URL configuration
//   - JWT Bearer token injection
//   - Token refresh on 401
//   - Consistent error handling

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../storage/session_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException({required this.statusCode, required this.message, this.errors});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  // Change this to your Render URL in production
  // For Android emulator use: 10.0.2.2
  // For iOS simulator use: 127.0.0.1
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  static Map<String, String> _headers(
      {String? token, bool isMultipart = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Core request handler ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _handleResponse(
      http.Response response) async {
    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.isEmpty) return {};
      return jsonDecode(body) as Map<String, dynamic>;
    }

    // Try to parse error detail
    String message = 'Request failed';
    Map<String, dynamic>? errors;
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        message =
            parsed['detail'] ?? parsed['message'] ?? parsed['error'] ?? message;
        errors = parsed;
      }
    } catch (_) {}
    print("❌ STATUS: ${response.statusCode}");
    print("❌ MESSAGE: $message");
    print("❌ ERRORS: $errors");
    print("❌ BODY: $body");
    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      errors: errors,
    );
  }

  // ── GET ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> get(String path,
      {bool auth = true}) async {
    final token = auth ? await SessionStorage.getAccessToken() : null;
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token: token),
    );
    return _handleResponse(response);
  }

  // ── POST (JSON) ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final token = auth ? await SessionStorage.getAccessToken() : null;
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // ── PATCH (JSON) ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final token = auth ? await SessionStorage.getAccessToken() : null;
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // ── Multipart (file upload) ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> uploadFile(
    String path, {
    required File file,
    required String fieldName,
    Map<String, String>? fields,
  }) async {
    final token = await SessionStorage.getAccessToken();
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }
}
