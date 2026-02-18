/// Authentication Service
///
/// Provides Firebase Authentication methods for user management.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  ///
  /// Takes [email] and [password] as parameters.
  /// Returns [User] object on success, or null on failure.
  /// Handles exceptions and returns null instead of throwing.
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle authentication errors
      print('Sign in error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      // Handle any other errors
      print('Unexpected error during sign in: $e');
      return null;
    }
  }

  /// Register a new user with email and password
  ///
  /// Takes [email] and [password] as parameters.
  /// Returns [User] object on success, or null on failure.
  /// Creates a new Firebase Authentication account.
  Future<User?> register(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle authentication errors
      print('Registration error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      // Handle any other errors
      print('Unexpected error during registration: $e');
      return null;
    }
  }

  /// Sign out the current user
  ///
  /// Logs out the currently authenticated user.
  /// Does not return any value.
  /// Handles exceptions internally.
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      // Handle sign out errors
      print('Sign out error: $e');
    }
  }

  /// Get the currently authenticated user
  ///
  /// Returns the current [User] object if signed in, or null if not.
  /// This is a synchronous operation that returns immediately.
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Additional methods for compatibility with existing code

  /// Sign in with email and password (throws exceptions)
  Future<User> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (userCredential.user == null) {
        throw Exception('Sign in failed: No user returned');
      }
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Register with email and password (throws exceptions)
  Future<User> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (userCredential.user == null) {
        throw Exception('Registration failed: No user returned');
      }
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  Future<User> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw Exception('Google sign in failed: No user returned');
      }

      return userCredential.user!;
    } catch (e) {
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  /// Update user's display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Failed to update display name: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'requires-recent-login':
        return 'Please log in again to perform this action.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
