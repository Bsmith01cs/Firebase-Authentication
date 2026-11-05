import 'package:firebase_auth/firebase_auth.dart';

/// Centralizes every Firebase authentication operation used by the app.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// The signed-in user, or null when nobody is signed in.
  User? get currentUser => _auth.currentUser;

  /// Emits the current user on sign-in, sign-out, and token refresh.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Creates an account with [email] and [password] and returns the new user.
  Future<User?> register({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  /// Signs in with [email] and [password] and returns the signed-in user.
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Changes the signed-in user's password.
  ///
  /// Firebase rejects this call when the sign-in session is old, so
  /// [currentPassword] is used to reauthenticate and the update is retried.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is signed in.',
      );
    }

    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') {
        rethrow;
      }
      await _reauthenticate(user, currentPassword);
      await user.updatePassword(newPassword);
    }
  }

  /// Reconfirms the user's identity with their email and current password.
  Future<void> _reauthenticate(User user, String currentPassword) async {
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'This account has no email address to reauthenticate with.',
      );
    }

    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: currentPassword),
    );
  }
}
