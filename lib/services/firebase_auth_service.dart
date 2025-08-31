import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling Firebase Authentication
///
/// This service manages user authentication including sign-in, sign-up,
/// and sign-out operations using Firebase Auth.
///
/// Supported authentication methods:
/// - Email/Password
/// - Google Sign-In
/// - Anonymous authentication
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  static FirebaseAuthService get instance => _instance;

  FirebaseAuthService._internal() {
    // Listen to auth state changes to update token
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _saveAuthToken();
      } else {
        await _clearAuthToken();
      }
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _tokenKey = 'auth_token';
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> _saveAuthToken() async {
    try {
      final token = await _auth.currentUser?.getIdToken();
      if (token != null) {
        final prefs = await _preferences;
        await prefs.setString(_tokenKey, token);
      }
    } catch (e) {
      debugPrint('Error saving auth token: $e');
    }
  }

  Future<void> _clearAuthToken() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_tokenKey);
    } catch (e) {
      debugPrint('Error clearing auth token: $e');
    }
  }

  /// Check if user has a valid auth token
  Future<bool> hasValidToken() async {
    try {
      final prefs = await _preferences;
      return prefs.containsKey(_tokenKey);
    } catch (e) {
      debugPrint('Error checking auth token: $e');
      return false;
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // SignIn with google
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Sign in with email and password
  ///
  /// [email] - User's email address
  /// [password] - User's password
  ///
  /// Returns the signed-in user or throws an exception
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Create account with email and password
  ///
  /// [email] - User's email address
  /// [password] - User's password
  /// [displayName] - Optional display name
  ///
  /// Returns the created user or throws an exception
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name if provided
      if (displayName != null && result.user != null) {
        await result.user!.updateDisplayName(displayName);
        await result.user!.reload();
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Account creation failed: $e');
    }
  }

  /// Returns the anonymous user or throws an exception
  Future<User?> signInAnonymously() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Anonymous sign in failed: $e');
    }
  }

  /// Send password reset email
  ///
  /// [email] - User's email address
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Update user profile
  ///
  /// [displayName] - New display name
  /// [photoURL] - New photo URL
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      await user.reload();
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Account deletion failed: $e');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _clearAuthToken();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'invalid-credential':
        return 'The credential is malformed or has expired.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'requires-recent-login':
        return 'This operation is sensitive and requires recent authentication. Please log in again.';
      case 'provider-already-linked':
        return 'This provider is already linked to your account.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action.';
      default:
        debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
        return 'Authentication failed. Please try again.';
    }
  }
}
