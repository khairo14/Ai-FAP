import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fundvanceai/shared/services/auth_service.dart';
import 'package:fundvanceai/shared/models/user_profile.dart';

/// Authentication state provider
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _init();
  }

  // Getters
  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Initialize and listen to auth state changes
  void _init() {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _loadUserProfile();
    }
    _authService.authStateChanges.listen((AuthState data) {
      _currentUser = data.session?.user;
      if (_currentUser != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  /// Sign up new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        _currentUser = response.user;
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred during sign up');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in existing user
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred during sign in');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _currentUser = null;
      _userProfile = null;
    } catch (e) {
      _setError('Failed to sign out');
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.resetPassword(email);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to send reset password email');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message manually
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Load user profile from database
  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await _authService.getUserProfile();
      notifyListeners();
    } catch (e) {
      // Silent fail - profile might not exist yet
    }
  }

  /// Update user currency
  Future<bool> updateCurrency(String currency) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedProfile = await _authService.updateProfile(
        currency: currency,
      );

      if (updatedProfile != null) {
        _userProfile = updatedProfile;
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update currency');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get current user's currency
  String get userCurrency => _userProfile?.currency ?? 'USD';
}
