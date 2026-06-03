// lib/storage/session_storage.dart
// Upgraded to store both access + refresh tokens and full user JSON

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SessionStorage {
  static const _accessTokenKey  = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey         = 'user_data';

  // ── Save session after login ─────────────────────────────────────────────

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey,  accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // ── Get access token ─────────────────────────────────────────────────────

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // ── Get refresh token ────────────────────────────────────────────────────

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // ── Get cached user ──────────────────────────────────────────────────────

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data  = prefs.getString(_userKey);
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data));
  }

  // ── Update access token (after refresh) ─────────────────────────────────

  static Future<void> updateAccessToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, newToken);
  }

  // ── Clear on logout ──────────────────────────────────────────────────────

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Is logged in ─────────────────────────────────────────────────────────

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
