import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hash password using SHA-256 (for consistency with old system)
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check if user already exists in Firestore
  Future<bool> _userExists(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Register new user with email/password
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Check if user already exists
      if (await _userExists(email)) {
        return {'success': false, 'message': 'Email already registered'};
      }

      // Create user with Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password, // Store plain password for Firebase Auth
      );

      final user = userCredential.user;

      if (user != null) {
        // Store additional user data in Firestore
        final hashedPassword = _hashPassword(password); // Hash for Firestore storage

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'password': hashedPassword, // Store hashed version in Firestore
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        // Update user display name
        await user.updateDisplayName(name);

        return {
          'success': true,
          'message': 'Registration successful',
          'userId': user.uid,
          'email': email,
        };
      } else {
        return {'success': false, 'message': 'Registration failed - no user created'};
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Login user with email/password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Authenticate with Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // Get user data from Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          return {
            'success': true,
            'message': 'Login successful',
            'userId': user.uid,
            'email': user.email,
            'name': userDoc.data()?['name'] ?? 'User',
          };
        } else {
          // User authenticated but no Firestore record (shouldn't happen)
          await logout(); // Logout to prevent inconsistent state
          return {'success': false, 'message': 'User data not found'};
        }
      } else {
        return {'success': false, 'message': 'Login failed'};
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Check if user is already logged in
  Future<Map<String, dynamic>> checkExistingSession() async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        // User is logged in, get their data
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          return {
            'success': true,
            'userId': user.uid,
            'email': user.email,
            'name': userDoc.data()?['name'] ?? 'User',
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
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Forgot password - send reset email
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      // Check if email exists in Firestore
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {'success': false, 'message': 'Email not found'};
      }

      // Send password reset email
      await _auth.sendPasswordResetEmail(email: email);

      return {
        'success': true,
        'message': 'Password reset email sent. Check your inbox.',
        'email': email,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Email not found';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        default:
          message = 'Failed to send reset email: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Change password (requires re-authentication)
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      if (user.email == null) {
        return {'success': false, 'message': 'User email not available'};
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      // Update hashed password in Firestore
      final hashedPassword = _hashPassword(newPassword);
      await _firestore.collection('users').doc(user.uid).update({
        'password': hashedPassword,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Password changed successfully',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Current password is incorrect';
          break;
        case 'weak-password':
          message = 'New password is too weak';
          break;
        case 'requires-recent-login':
          message = 'Please login again to change password';
          break;
        default:
          message = 'Failed to change password: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          return {
            'uid': user.uid,
            'email': user.email,
            'name': userDoc.data()?['name'] ?? 'User',
            ...userDoc.data()!,
          };
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // Update email in Firebase Auth if changed
      if (email != user.email) {
        await user.verifyBeforeUpdateEmail(email);
      }

      // Update display name
      await user.updateDisplayName(name);

      // Update user data in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'email': email,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Profile updated successfully',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already in use';
          break;
        case 'requires-recent-login':
          message = 'Please login again to update email';
          break;
        default:
          message = 'Failed to update profile: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}