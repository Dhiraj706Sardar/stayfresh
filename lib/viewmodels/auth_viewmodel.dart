import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  // Private fields
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Services
  final FirebaseAuthService _authService = FirebaseAuthService.instance;

  // Constructor
  AuthViewModel() {
    _initializeAuthState();
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _currentUser?.uid;
  String? get userEmail => _currentUser?.email;
  String? get userName => _currentUser?.displayName;
  String? get userPhotoUrl => _currentUser?.photoURL;

  /// Initialize authentication state and listen to auth changes
  void _initializeAuthState() {
    _currentUser = _authService.currentUser;
    
    // Listen to authentication state changes
    _authService.authStateChanges.listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signInWithEmailAndPassword(email, password);
      _currentUser = user;
      notifyListeners();
      return user != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmail(String email, String password, {String? displayName}) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.createUserWithEmailAndPassword(
        email, 
        password, 
        displayName: displayName,
      );
      _currentUser = user;
      notifyListeners();
      return user != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signInAnonymously();
      _currentUser = user;
      notifyListeners();
      return user != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email
  /// 
  /// [email] - User's email address
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  /// 
  /// [displayName] - New display name
  /// [photoURL] - New photo URL
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      // Refresh current user data
      _currentUser = _authService.currentUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete current user account
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.deleteAccount();
      _currentUser = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error state
  void clearError() {
    _clearError();
  }

  // Private helper methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}