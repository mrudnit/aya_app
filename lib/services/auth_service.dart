import 'package:firebase_auth/firebase_auth.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Login
  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Register
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Logout
  Future<void> logout() async {
    await Future.wait([_auth.signOut()]);
  }
  // Error
  static String errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-not-found':
        return 'No account with that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }
}
