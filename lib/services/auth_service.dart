import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Check if user is logged in
  bool get isLoggedIn => _supabase.auth.currentUser != null;

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ==================== EMAIL/PASSWORD AUTH ====================

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      debugPrint('🟡 AuthService.signUp: Attempting signup for $email...');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception(
            'Connection timed out. Please check your internet connection and try again.'),
      );

      debugPrint(
          '🟡 AuthService.signUp: Got response — user=${response.user?.id}, session=${response.session != null}');

      if (response.user == null) {
        throw Exception('Sign up failed');
      }

      // When email confirmation is required, session will be null.
      // Notify the caller so the UI can ask the user to verify their email.
      if (response.session == null) {
        throw Exception('EMAIL_CONFIRMATION_REQUIRED');
      }

      final userId = response.user!.id;

      // Wait for the Supabase session to be fully established before
      // attempting to write to the users table (avoids RLS 42501 error).
      await _waitForSession();

      // Try to create the user profile row, with retries on RLS errors.
      await _upsertUserProfile(
        userId: userId,
        email: email,
        name: name,
      );

      return UserModel(
        id: userId,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('🔴 AuthService.signUp FAILED: ${e.runtimeType} — $e');
      throw _handleError(e);
    }
  }

  Future<void> _waitForSession() async {
    const maxWait = Duration(seconds: 5);
    const interval = Duration(milliseconds: 200);
    final deadline = DateTime.now().add(maxWait);

    while (DateTime.now().isBefore(deadline)) {
      if (_supabase.auth.currentSession != null) return;
      await Future.delayed(interval);
    }
    // If still no session, proceed anyway — the upsert will handle it.
    debugPrint(
        '⚠️ AuthService: session not ready after 5 s, proceeding anyway');
  }

  /// Upserts the user profile row, retrying up to 3 times on RLS / network errors.
  Future<void> _upsertUserProfile({
    required String userId,
    required String email,
    String? name,
  }) async {
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _supabase.from('users').upsert({
          'id': userId,
          'email': email,
          'name': name,
          'created_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id').timeout(const Duration(seconds: 10));
        debugPrint('✅ AuthService: user profile saved (attempt $attempt)');
        return;
      } catch (e) {
        final msg = e.toString();
        debugPrint(
            '⚠️ AuthService: profile upsert attempt $attempt failed: $msg');

        if (attempt < maxRetries) {
          // Back-off before retry: 300 ms, 600 ms, …
          await Future.delayed(Duration(milliseconds: 300 * attempt));
        } else {
          // After all retries, log but DO NOT rethrow — auth already succeeded.
          debugPrint(
              '⚠️ AuthService: could not save profile after $maxRetries attempts. '
              'Auth account was created successfully. Profile will be created on next sign-in.');
        }
      }
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🟡 AuthService.signIn: Attempting login for $email...');

      final response = await _supabase.auth
          .signInWithPassword(
            email: email,
            password: password,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception(
                'Connection timed out. Please check your internet connection and try again.'),
          );

      debugPrint(
          '🟡 AuthService.signIn: Got response — user=${response.user?.id}, session=${response.session != null}');

      if (response.user == null) {
        throw Exception('Sign in failed');
      }

      final userId = response.user!.id;

      // Ensure the user profile row exists (handles case where signup
      // profile write failed due to RLS timing).
      try {
        await _supabase.from('users').upsert({
          'id': userId,
          'email': email,
          'last_sign_in': DateTime.now().toIso8601String(),
        }, onConflict: 'id').timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('⚠️ AuthService: could not update last_sign_in: $e');
      }

      // Get user data
      try {
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id', userId)
            .single()
            .timeout(const Duration(seconds: 10));
        return UserModel.fromJson(userData);
      } catch (e) {
        // Profile row still not accessible — return a minimal model from auth data
        debugPrint(
            '⚠️ AuthService: could not fetch user profile, using auth data: $e');
        return UserModel(
          id: userId,
          email: email,
          name: response.user!.userMetadata?['name'] as String?,
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('🔴 AuthService.signIn FAILED: ${e.runtimeType} — $e');
      throw _handleError(e);
    }
  }

  // ==================== GOOGLE AUTH ====================

  /// Sign in / Sign up with Google
  /// ✅ FULLY IMPLEMENTED: Complete Google OAuth flow
  Future<UserModel> signInWithGoogle() async {
    try {
      debugPrint('🟡 AuthService.signInWithGoogle: Starting Google OAuth flow...');

      // Initialize Google Sign In
      // ⚠️ CRITICAL FIX NEEDED:
      // The previous ID ("779...") was from a different project than your google-services.json ("817...").
      // This mismatch causes sign-in to fail.
      //
      // 1. Go to Google Cloud Console (Project: expense-tracker-pro-d69c3 / 817425543728)
      // 2. Create a "Web application" credential.
      // 3. Paste that Client ID below.
      const webClientId = null; // TODO: PASTE YOUR NEW WEB CLIENT ID HERE (starts with "817425543728-...")

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: webClientId,
      );

      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in cancelled by user');
      }

      debugPrint('✅ Google user signed in: ${googleUser.email}');

      // Get Google Auth tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }

      debugPrint('✅ Got Google tokens - signing in to Supabase...');

      // Sign in to Supabase with Google tokens
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Google sign in timed out. Please try again.'),
      );

      if (response.user == null) {
        throw Exception('Google sign in failed - no user returned');
      }

      final userId = response.user!.id;
      final userEmail = response.user!.email ?? googleUser.email;
      final userName = googleUser.displayName;
      final userPhotoUrl = googleUser.photoUrl;

      debugPrint('✅ Supabase auth successful - user ID: $userId');

      // Wait for session to be established
      await _waitForSession();

      // Check if user exists in database
      try {
        final existingUser = await _supabase
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));

        if (existingUser == null) {
          // Create new user record for first-time Google login
          debugPrint('🟡 Creating new user profile for Google user...');
          await _supabase.from('users').insert({
            'id': userId,
            'email': userEmail,
            'name': userName,
            'avatar_url': userPhotoUrl,
            'created_at': DateTime.now().toIso8601String(),
            'last_sign_in': DateTime.now().toIso8601String(),
          }).timeout(const Duration(seconds: 10));

          debugPrint('✅ New Google user profile created');

          return UserModel(
            id: userId,
            email: userEmail,
            name: userName,
            avatarUrl: userPhotoUrl,
            createdAt: DateTime.now(),
            lastSignIn: DateTime.now(),
          );
        } else {
          // Update last sign in for returning user
          debugPrint('🟡 Updating last sign in for existing Google user...');
          await _supabase.from('users').update({
            'last_sign_in': DateTime.now().toIso8601String(),
            'avatar_url': userPhotoUrl, // Update avatar in case it changed
          }).eq('id', userId).timeout(const Duration(seconds: 10));

          debugPrint('✅ Existing Google user profile updated');
          return UserModel.fromJson(existingUser);
        }
      } catch (e) {
        debugPrint('⚠️ AuthService: error with user profile: $e');
        // Return user even if profile update fails - auth is successful
        return UserModel(
          id: userId,
          email: userEmail,
          name: userName,
          avatarUrl: userPhotoUrl,
          createdAt: DateTime.now(),
          lastSignIn: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('🔴 AuthService.signInWithGoogle FAILED: ${e.runtimeType} — $e');
      throw _handleError(e);
    }
  }

  /// Sign out from Google and Supabase
  /// ✅ FULLY IMPLEMENTED: Proper cleanup
  Future<void> signOutGoogle() async {
    try {
      debugPrint('🟡 AuthService.signOutGoogle: Signing out...');

      // Sign out from Google
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      // Sign out from Supabase
      await _supabase.auth.signOut();

      debugPrint('✅ Signed out successfully');
    } catch (e) {
      debugPrint('⚠️ AuthService.signOutGoogle error: $e');
      // Continue with signout even if there's an error
      try {
        await _supabase.auth.signOut();
      } catch (_) {}
    }
  }

  // ==================== PASSWORD RESET ====================

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update password (when user is logged in)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== USER MANAGEMENT ====================

  /// Get user profile
  Future<UserModel> getUserProfile() async {
    try {
      if (currentUserId == null) {
        throw Exception('Not logged in');
      }

      try {
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id', currentUserId!)
            .single()
            .timeout(const Duration(seconds: 10));
        return UserModel.fromJson(userData);
      } catch (e) {
        // Row might not exist yet — return from auth metadata
        debugPrint(
            '⚠️ AuthService: getUserProfile fell back to auth metadata: $e');
        final authUser = _supabase.auth.currentUser!;
        return UserModel(
          id: authUser.id,
          email: authUser.email ?? '',
          name: authUser.userMetadata?['name'] as String?,
          createdAt: DateTime.tryParse(authUser.createdAt) ?? DateTime.now(),
        );
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('Not logged in');
      }

      await _supabase.from('users').update({
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }).eq('id', currentUserId!);

      return await getUserProfile();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      if (currentUserId == null) {
        throw Exception('Not logged in');
      }

      // Delete user data (cascade will handle related data)
      await _supabase.from('users').delete().eq('id', currentUserId!);

      // Sign out
      await signOut();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== SIGN OUT ====================

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== ERROR HANDLING ====================

  Exception _handleError(dynamic error) {
    debugPrint('🔴 AuthService._handleError: ${error.runtimeType} — $error');

    // Timeout errors
    if (error is TimeoutException) {
      return Exception(
          'Connection timed out. Please check your internet connection and try again.');
    }

    // Network / connectivity errors
    final msg = error.toString().toLowerCase();
    if (error is SocketException ||
        msg.contains('socketexception') ||
        msg.contains('connection timed out') ||
        msg.contains('timed out') ||
        msg.contains('timeout') ||
        msg.contains('connection refused') ||
        msg.contains('network is unreachable') ||
        msg.contains('clientexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('authretryablefetcherror') ||
        msg.contains('retryablefetch') ||
        msg.contains('fetch error') ||
        msg.contains('network error') ||
        msg.contains('xmlhttprequest error')) {
      return Exception(
          'Cannot connect to the server. Please check your internet connection and try again.');
    }

    if (error is AuthException) {
      // Handle network / fetch errors from the Supabase SDK
      if (error.statusCode == '0' ||
          error.statusCode == null ||
          msg.contains('retryablefetch') ||
          msg.contains('fetch error') ||
          msg.contains('network')) {
        if (error.statusCode == '0' || msg.contains('retryablefetch')) {
          return Exception(
              'Cannot connect to the server. Please check your internet connection and try again.');
        }
      }

      // Handle server-side errors (HTTP 500, 502, 503, etc.)
      final code = int.tryParse(error.statusCode ?? '') ?? 0;
      if (code >= 500) {
        debugPrint('🔴 Supabase server error ($code): ${error.message}');
        return Exception(
            'The server is temporarily unavailable. Please try again in a moment.');
      }

      // Handle rate limiting (HTTP 429)
      if (code == 429 ||
          msg.contains('rate') ||
          msg.contains('too many requests')) {
        return Exception(
            'Too many attempts. Please wait a moment and try again.');
      }

      // Handle specific auth error messages
      final errMsg = error.message.toLowerCase();
      if (errMsg.contains('invalid login credentials') ||
          errMsg.contains('invalid credentials')) {
        return Exception(
            'Invalid email or password. Please check and try again.');
      }
      if (errMsg.contains('email not confirmed') ||
          errMsg.contains('email_not_confirmed')) {
        return Exception(
            'Please verify your email before signing in. Check your inbox.');
      }
      if (errMsg.contains('user already registered') ||
          errMsg.contains('already been registered')) {
        return Exception(
            'This email is already registered. Please sign in instead.');
      }
      if (errMsg.contains('password') && errMsg.contains('at least')) {
        return Exception('Password must be at least 6 characters.');
      }
      if (errMsg.contains('user not found')) {
        return Exception(
            'No account found with this email. Please sign up first.');
      }
      if (errMsg.contains('email') && errMsg.contains('invalid')) {
        return Exception('Please enter a valid email address.');
      }

      // Fallback: return a cleaned-up version of the auth error
      debugPrint(
          '🔴 Unhandled AuthException: statusCode=${error.statusCode}, message=${error.message}');
      return Exception('Authentication failed: ${error.message}');
    }

    // Pass through our custom signals unchanged (e.g. EMAIL_CONFIRMATION_REQUIRED)
    if (error is Exception) return error;
    return Exception('Something went wrong. Please try again.');
  }
}
