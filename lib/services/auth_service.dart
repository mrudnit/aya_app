import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;

    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'phone': phone.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  // Login with Google
  Future<void> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) return; // user cancelled

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);
    if (userCred.additionalUserInfo?.isNewUser == true) {
      final uid = userCred.user!.uid;
      final displayName = googleUser.displayName ?? '';
      final parts = displayName.split(' ');
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': googleUser.email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    await _google.signOut();
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
