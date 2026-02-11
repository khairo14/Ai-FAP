import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fundvanceai/core/config/supabase_config.dart';
import 'package:fundvanceai/shared/models/user_profile.dart';

/// Authentication service for handling user authentication with Supabase
class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Get user ID
  String? get userId => currentUser?.id;

  /// Get user email
  String? get userEmail => currentUser?.email;

  /// Get user profile from database
  Future<UserProfile?> getUserProfile() async {
    try {
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId!)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  Future<UserProfile?> updateProfile({
    String? fullName,
    String? phone,
    String? currency,
    String? avatarUrl,
  }) async {
    try {
      if (userId == null) return null;

      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone'] = phone;
      if (currency != null) data['currency'] = currency;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      final response = await _supabase
          .from('profiles')
          .update(data)
          .eq('id', userId!)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
