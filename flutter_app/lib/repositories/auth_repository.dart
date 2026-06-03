// lib/repositories/auth_repository.dart
// Thin wrapper kept for backwards compatibility.
// New code should use AuthService directly.

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  static Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    return AuthService.login(email: email, password: password);
  }

  static Future<void> logout() async {
    return AuthService.logout();
  }

  static Future<UserModel?> getCurrentUser() async {
    return AuthService.getCurrentUser();
  }
}
