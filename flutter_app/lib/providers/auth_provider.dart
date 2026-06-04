// lib/providers/auth_provider.dart
// Central auth state using Provider package

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../storage/session_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  // ── Boot: restore session from storage ───────────────────────────────────

  Future<void> init() async {
    final loggedIn = await SessionStorage.isLoggedIn();
    if (loggedIn) {
      _user = await SessionStorage.getUser();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _error = null;
    try {
      _user = await AuthService.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> googleLogin(String idToken) async {
    _error = null;

    try {
      _user = await AuthService.googleSignIn(idToken, role: 'patient');

      if (_user == null) {
        _error = 'Google login failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Patient registration ──────────────────────────────────────────────────

  Future<bool> registerPatient({
    required String name,
    required String email,
    required String password,
    int? age,
    String? gender,
    double? weightKg,
    double? heightCm,
    String? bloodType,
    String? phone,
    String? address,
    String? chronicDiseases,
    String? allergies,
    String? currentMeds,
  }) async {
    _error = null;

    try {
      final response = await AuthService.registerPatient(
        name: name,
        email: email,
        password: password,
        age: age,
        gender: gender,
        weightKg: weightKg,
        heightCm: heightCm,
        bloodType: bloodType,
        phone: phone,
        address: address,
        chronicDiseases: chronicDiseases,
        allergies: allergies,
        currentMeds: currentMeds,
      );

      if (response['tokens'] != null) {
        _user = UserModel.fromJson(response['user']);
        _status = AuthStatus.authenticated;

        final tokens = response['tokens'];

        await SessionStorage.saveSession(
          accessToken: tokens['access'],
          refreshToken: tokens['refresh'],
          user: _user!,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }
  // ── Doctor registration ───────────────────────────────────────────────────

  Future<bool> registerDoctor({
    required String name,
    required String email,
    required String password,
    required String specialization,
    required String licenseNumber,
    String? hospital,
    int yearsExperience = 0,
  }) async {
    _error = null;
    try {
      await AuthService.registerDoctor(
        name: name,
        email: email,
        password: password,
        specialization: specialization,
        licenseNumber: licenseNumber,
        hospital: hospital,
        yearsExperience: yearsExperience,
      );
      notifyListeners();
      return true; // Doctor must wait for admin approval, not auto-login
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Refresh user from server ──────────────────────────────────────────────

  Future<void> refreshUser() async {
    try {
      _user = await AuthService.getCurrentUser();
      notifyListeners();
    } catch (_) {}
  }

  // ── Error parser ──────────────────────────────────────────────────────────

  String _parseError(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('ApiException')) {
        final match = RegExp(r'ApiException\(\d+\): (.+)').firstMatch(msg);
        return match?.group(1) ?? msg;
      }
      return msg.replaceAll('Exception: ', '');
    }
    return e.toString();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> updatePatientProfile({
    int? age,
    String? gender,
    double? weightKg,
    double? heightCm,
    String? bloodType,
    String? phone,
    String? address,
    String? chronicDiseases,
    String? allergies,
    String? currentMeds,
  }) async {
    _error = null;

    try {
      _user = await AuthService.updatePatientProfile(
        age: age,
        gender: gender,
        weightKg: weightKg,
        heightCm: heightCm,
        bloodType: bloodType,
        phone: phone,
        address: address,
        chronicDiseases: chronicDiseases,
        allergies: allergies,
        currentMeds: currentMeds,
      );

      await SessionStorage.saveUser(_user!);

      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }
}
