import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService;

  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService();

  // ============================================================
  // LOGIN
  // ============================================================

  Future<firebase_auth.User?> login({
    required String email,
    required String password,
  }) async {
    return await _authService.login(email: email, password: password);
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<firebase_auth.User?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _authService.register(
      email: email,
      password: password,
      name: name,
    );
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _authService.logout();
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  firebase_auth.User? get currentUser => _authService.currentUser;
}
