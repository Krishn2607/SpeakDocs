import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth =
      firebase_auth.FirebaseAuth.instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  // =========================
  // ENSURE SUPABASE ROLE
  // =========================
  Future<void> _ensureSupabaseRole(
      firebase_auth.User user,
      ) async {
    try {
      // Get the current Firebase ID token.
      final String? idToken = await user.getIdToken();

      if (idToken == null) {
        throw Exception(
          'Unable to get Firebase authentication token.',
        );
      }

      // Call the Supabase Edge Function.
      //
      // The Edge Function verifies the Firebase ID token
      // and sets the Firebase custom claim:
      //
      // role: authenticated
      //
      await _supabase.functions.invoke(
        'set-firebase-role',
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      // Firebase custom claims are included in newly issued
      // ID tokens, so force Firebase to refresh the token.
      await user.getIdToken(true);
    } catch (e) {
      print('🔥 Supabase Role Setup Error: $e');

      throw Exception(
        'Unable to configure your account. Please try again.',
      );
    }
  }

  // =========================
  // REGISTER
  // =========================
  Future<firebase_auth.User?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final firebase_auth.UserCredential credential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebase_auth.User? user = credential.user;

      if (user != null) {
        await user.updateDisplayName(name.trim());
        await user.reload();

        final firebase_auth.User? updatedUser =
            _auth.currentUser;

        if (updatedUser != null) {
          await _ensureSupabaseRole(updatedUser);
        }
      }

      return _auth.currentUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Print the REAL Firebase error in Android Studio terminal.
      print('🔥 Firebase Auth Error');
      print('Code: ${e.code}');
      print('Message: ${e.message}');

      throw Exception(_getErrorMessage(e.code));
    } on Exception {
      rethrow;
    } catch (e) {
      print('🔥 Unexpected Registration Error: $e');
      throw Exception(
        'Something went wrong. Please try again.',
      );
    }
  }

  // =========================
  // LOGIN
  // =========================
  Future<firebase_auth.User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final firebase_auth.UserCredential credential =
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebase_auth.User? user = credential.user;

      if (user != null) {
        // Make sure the Firebase user has the role
        // required by Supabase.
        await _ensureSupabaseRole(user);
      }

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('🔥 Firebase Login Error');
      print('Code: ${e.code}');
      print('Message: ${e.message}');

      throw Exception(_getErrorMessage(e.code));
    } on Exception {
      rethrow;
    } catch (e) {
      print('🔥 Unexpected Login Error: $e');
      throw Exception(
        'Something went wrong. Please try again.',
      );
    }
  }

  // =========================
  // RESET PASSWORD
  // =========================
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('🔥 Firebase Password Reset Error');
      print('Code: ${e.code}');
      print('Message: ${e.message}');

      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      print('🔥 Unexpected Password Reset Error: $e');
      throw Exception(
        'Something went wrong. Please try again.',
      );
    }
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('🔥 Logout Error: $e');
      throw Exception(
        'Unable to logout. Please try again.',
      );
    }
  }

  // =========================
  // CURRENT USER
  // =========================
  firebase_auth.User? get currentUser => _auth.currentUser;

  // =========================
  // FIREBASE ERROR MESSAGES
  // =========================
  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'weak-password':
        return 'Password must be at least 6 characters.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled in Firebase.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'requires-recent-login':
        return 'Please log in again and try this operation.';

      default:
        return 'Authentication failed. Please try again.';
    }
  }
}