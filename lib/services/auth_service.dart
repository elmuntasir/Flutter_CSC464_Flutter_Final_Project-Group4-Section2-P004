import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Authentication.
/// Passwords are NEVER stored in plaintext — Firebase Auth hashes them
/// server-side using bcrypt before persisting to Google's secure backend.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream that emits the current [User] or null on auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  /// Creates a new account. Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Persist display name on the Firebase user profile.
    await credential.user?.updateDisplayName(displayName.trim());
    return credential;
  }

  /// Signs in an existing user. Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
