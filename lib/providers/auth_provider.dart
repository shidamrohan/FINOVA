import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _emailConfirmationRequired = false;

  UserModel? get user => _user;

  // ✅ ADDED: Get current Supabase user (for ProfileScreen)
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get emailConfirmationRequired => _emailConfirmationRequired;

  /// Strips "Exception: " prefix added by Dart when throwing Exception objects.
  String _cleanError(dynamic e) {
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    if (_authService.isLoggedIn) {
      _loadUser();
    }

    _authService.authStateChanges.listen((AuthState state) {
      if (state.event == AuthChangeEvent.signedIn) {
        _loadUser();
      } else if (state.event == AuthChangeEvent.signedOut) {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUser() async {
    try {
      _user = await _authService.getUserProfile();
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user: $e');
      _error = _cleanError(e);
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    _isLoading = true;
    _error = null;
    _emailConfirmationRequired = false;
    notifyListeners();

    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final msg = _cleanError(e);
      if (msg == 'EMAIL_CONFIRMATION_REQUIRED') {
        _emailConfirmationRequired = true;
        _error = null;
      } else {
        _error = msg;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    _emailConfirmationRequired = false;
    notifyListeners();

    try {
      _user = await _authService.signIn(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _cleanError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    _emailConfirmationRequired = false;
    notifyListeners();

    try {
      _user = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _cleanError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out from Google and Supabase
  /// ✅ ENHANCED: Proper Google sign-out
  Future<bool> signOutGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signOutGoogle();
      _user = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _cleanError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _cleanError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.updatePassword(newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _cleanError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.updateProfile(
        name: name,
        avatarUrl: avatarUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _cleanError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.deleteAccount();
      _user = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _cleanError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _error = null;
    } catch (e) {
      _error = _cleanError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _emailConfirmationRequired = false;
    notifyListeners();
  }
}
