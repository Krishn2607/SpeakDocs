import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // REGISTER
  // =========================
  Future<User?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential credential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = credential.user;

      if (user != null) {
        await user.updateDisplayName(name.trim());
        await user.reload();
      }

      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      // Print the REAL Firebase error in Android Studio terminal.
      print('🔥 Firebase Auth Error');
      print('Code: ${e.code}');
      print('Message: ${e.message}');

      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      print('🔥 Unexpected Registration Error: $e');
      throw Exception('Something went wrong. Please try again.');
    }
  }

  // =========================
  // LOGIN
  // =========================
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('🔥 Firebase Login Error');
      print('Code: ${e.code}');
      print('Message: ${e.message}');

      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      print('🔥 Unexpected Login Error: $e');
      throw Exception('Something went wrong. Please try again.');
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
    } on FirebaseAuthException catch (e) {
      print('🔥 Firebase Password Reset Error');
      print('Code: ${e.code}');
      print('Message: ${e.message}');

      throw Exception(_getErrorMessage(e.code));
    } catch (e) {
      print('🔥 Unexpected Password Reset Error: $e');
      throw Exception('Something went wrong. Please try again.');
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
      throw Exception('Unable to logout. Please try again.');
    }
  }

  // =========================
  // CURRENT USER
  // =========================
  User? get currentUser => _auth.currentUser;

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