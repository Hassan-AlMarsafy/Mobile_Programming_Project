import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Hash password using SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Check if email already exists
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        return {'success': false, 'message': 'Email already registered'};
      }

      // Create new user
      final user = User(
        name: name,
        email: email,
        password: _hashPassword(password),
        createdAt: DateTime.now(),
      );

      final userId = await _dbHelper.insertUser(user.toMap());

      if (userId > 0) {
        // Generate session token
        final token = _generateSessionToken(userId, email);
        await _dbHelper.saveSession(userId, token);

        return {
          'success': true,
          'message': 'Registration successful',
          'userId': userId,
          'token': token,
        };
      } else {
        return {'success': false, 'message': 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userData = await _dbHelper.getUserByEmail(email);

      if (userData == null) {
        return {'success': false, 'message': 'User not found'};
      }

      if (userData['password'] != _hashPassword(password)) {
        return {'success': false, 'message': 'Incorrect password'};
      }

      final user = User.fromMap(userData);

      // Generate session token
      final token = _generateSessionToken(user.id!, email);
      await _dbHelper.saveSession(user.id!, token);

      return {
        'success': true,
        'message': 'Login successful',
        'userId': user.id,
        'token': token,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Check if user is already logged in
  Future<Map<String, dynamic>> checkExistingSession() async {
    try {
      final session = await _dbHelper.getActiveSession();

      if (session != null) {
        final userData = await _dbHelper.getUserById(session['user_id']);

        if (userData != null) {
          final user = User.fromMap(userData);
          return {
            'success': true,
            'user': user,
            'token': session['token'],
          };
        }
      }

      return {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Logout user
  Future<void> logout() async {
    await _dbHelper.clearSession();
  }

  // Forgot password - generate reset token
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final userData = await _dbHelper.getUserByEmail(email);

      if (userData == null) {
        return {'success': false, 'message': 'Email not found'};
      }

      final user = User.fromMap(userData);
      final token = await _dbHelper.createResetToken(user.id!);

      // In a real app, you would send an email here
      // For now, we'll just return the token for demo purposes

      return {
        'success': true,
        'message': 'Reset link has been sent to your email',
        'token': token,
        'email': email,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Reset password with token
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      // Validate token
      final isValid = await _dbHelper.validateResetToken(token);

      if (!isValid) {
        return {'success': false, 'message': 'Invalid or expired token'};
      }

      // Get user ID from token
      final userId = await _dbHelper.getUserIdByToken(token);

      if (userId == null) {
        return {'success': false, 'message': 'User not found'};
      }

      // Update password
      final hashedPassword = _hashPassword(newPassword);
      final result = await _dbHelper.updateUserPassword(userId, hashedPassword);

      if (result > 0) {
        await _dbHelper.markTokenUsed(token);
        return {'success': true, 'message': 'Password reset successful'};
      } else {
        return {'success': false, 'message': 'Failed to reset password'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Generate session token
  String _generateSessionToken(int userId, String email) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$userId-$email-$timestamp';
    var bytes = utf8.encode(data);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}