// lib/services/auth_service.dart
import '../models/user_model.dart';
import '../storage/session_storage.dart';
import 'api_client.dart';

class AuthService {
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return ApiClient.post(
      '/auth/change-password/',
      {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }

  static Future<Map<String, dynamic>> registerPatient({
    required String name,
    required String email,
    required String password,
    int? age,
    String? gender,
  }) async {
    return ApiClient.post(
        '/auth/register/patient/',
        {
          'name': name,
          'email': email,
          'password': password,
          'confirm_password': password,
          if (age != null) 'age': age,
          if (gender != null) 'gender': gender,
        },
        auth: false);
  }

  static Future<Map<String, dynamic>> registerDoctor({
    required String name,
    required String email,
    required String password,
    required String specialization,
    required String licenseNumber,
    String? hospital,
    int yearsExperience = 0,
  }) async {
    return ApiClient.post(
        '/auth/register/doctor/',
        {
          'name': name,
          'email': email,
          'password': password,
          'confirm_password': password,
          'specialization': specialization,
          'license_number': licenseNumber,
          if (hospital != null) 'hospital': hospital,
          'years_experience': yearsExperience,
        },
        auth: false);
  }

  static Future<UserModel?> login(
      {required String email, required String password}) async {
    final response = await ApiClient.post(
        '/auth/login/', {'email': email, 'password': password},
        auth: false);
    final tokens = response['tokens'] as Map<String, dynamic>;
    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    await SessionStorage.saveSession(
        accessToken: tokens['access'],
        refreshToken: tokens['refresh'],
        user: user);
    return user;
  }

  static Future<void> logout() async {
    try {
      final refresh = await SessionStorage.getRefreshToken();
      if (refresh != null)
        await ApiClient.post('/auth/logout/', {'refresh': refresh});
    } catch (_) {}
    await SessionStorage.clear();
  }

  static Future<UserModel?> getCurrentUser() async {
    try {
      return UserModel.fromJson(await ApiClient.get('/auth/me/'));
    } catch (_) {
      return null;
    }
  }

  static Future<UserModel?> googleSignIn(String idToken,
      {String role = 'patient'}) async {
    final response = await ApiClient.post(
        '/auth/google/', {'id_token': idToken, 'role': role},
        auth: false);
    final tokens = response['tokens'] as Map<String, dynamic>;
    final user = UserModel.fromJson(response['user']);
    await SessionStorage.saveSession(
        accessToken: tokens['access'],
        refreshToken: tokens['refresh'],
        user: user);
    return user;
  }
}
