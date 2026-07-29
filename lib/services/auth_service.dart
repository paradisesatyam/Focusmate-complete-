import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUp({required String name, required String email, required String password}) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());
    await cred.user?.updateDisplayName(name.trim());
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
  }

  Future<void> signOut() async => await _auth.signOut();

  String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return 'An account with this email already exists.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password. Please try again.';
      case 'invalid-credential': return 'Incorrect email or password.';
      case 'too-many-requests': return 'Too many attempts. Please wait and try again.';
      default: return 'Something went wrong. Please try again.';
    }
  }
}
