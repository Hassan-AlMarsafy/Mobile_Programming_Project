import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';

class AuthViewModel with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;

  // Initialize auth state
  Future<void> initialize() async {
    setLoading(true);
    try {
      final result = await _authService.checkExistingSession();

      if (result['success']) {
        _currentUser = {
          'userId': result['userId'],
          'email': result['email'],
          'name': result['name'],
        };
        _isLoggedIn = true;
      } else {
        _isLoggedIn = false;
      }
    } catch (e) {
      _error = 'Error initializing auth: $e';
      _isLoggedIn = false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    setLoading(true);
    clearError();

    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
      );

      if (result['success']) {
        _currentUser = {
          'userId': result['userId'],
          'email': result['email'],
          'name': name,
        };
        _isLoggedIn = true;
        notifyListeners();
        return result;
      } else {
        _error = result['message'];
        notifyListeners();
        return result;
      }
    } catch (e) {
      _error = 'Registration error: $e';
      notifyListeners();
      return {'success': false, 'message': 'Registration error: $e'};
    } finally {
      setLoading(false);
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    setLoading(true);
    clearError();

    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result['success']) {
        _currentUser = {
          'userId': result['userId'],
          'email': result['email'],
          'name': result['name'],
        };
        _isLoggedIn = true;
        notifyListeners();
        return result;
      } else {
        _error = result['message'];
        notifyListeners();
        return result;
      }
    } catch (e) {
      _error = 'Login error: $e';
      notifyListeners();
      return {'success': false, 'message': 'Login error: $e'};
    } finally {
      setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    setLoading(true);
    try {
      await _authService.logout();
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      _error = 'Logout error: $e';
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  // Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    setLoading(true);
    clearError();

    try {
      final result = await _authService.forgotPassword(email);

      if (result['success']) {
        return {
          'success': true,
          'message': result['message'],
          'email': email,
        };
      } else {
        _error = result['message'];
        notifyListeners();
        return {'success': false, 'message': result['message']};
      }
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      setLoading(false);
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    setLoading(true);
    clearError();

    try {
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (result['success']) {
        return result;
      } else {
        _error = result['message'];
        notifyListeners();
        return result;
      }
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      setLoading(false);
    }
  }

  // Update profile
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    setLoading(true);
    clearError();

    try {
      final result = await _authService.updateProfile(
        name: name,
        email: email,
      );

      if (result['success']) {
        // Update local user data
        if (_currentUser != null) {
          _currentUser!['name'] = name;
          _currentUser!['email'] = email;
          notifyListeners();
        }
        return result;
      } else {
        _error = result['message'];
        notifyListeners();
        return result;
      }
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      setLoading(false);
    }
  }

  // Get current user data
  Future<Map<String, dynamic>?> getUserData() async {
    return await _authService.getCurrentUserData();
  }

  // Helper methods
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }
}