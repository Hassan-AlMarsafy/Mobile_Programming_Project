import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_data.dart';
import '../models/actuator_data.dart';
import '../models/sensor_calibration.dart';
import '../models/user.dart';
import '../models/notification_preferences.dart';
import '../models/watering_schedule.dart';
import '../models/activity_log.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Listen to sensor data changes (real-time stream)
  Stream<SensorData?> getSensorDataStream() {
    return _firestore.collection('sensors').doc('current').snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return SensorData.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  // Listen to actuator data changes (real-time stream)
  Stream<ActuatorData?> getActuatorDataStream() {
    return _firestore.collection('actuators').doc('current').snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return ActuatorData.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  // Get current sensor data (one-time fetch)
  Future<SensorData?> getCurrentSensorData() async {
    try {
      final snapshot =
          await _firestore.collection('sensors').doc('current').get();
      if (snapshot.exists && snapshot.data() != null) {
        return SensorData.fromJson(snapshot.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get current actuator data (one-time fetch)
  Future<ActuatorData?> getCurrentActuatorData() async {
    try {
      final snapshot =
          await _firestore.collection('actuators').doc('current').get();
      if (snapshot.exists && snapshot.data() != null) {
        return ActuatorData.fromJson(snapshot.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Send actuator control command (for future use)
  Future<void> sendActuatorCommand(ActuatorData data) async {
    try {
      await _firestore
          .collection('actuators')
          .doc('current')
          .set(data.toJson());
    } catch (e) {
      // Handle error
    }
  }

  // ============ SYSTEM MODE METHODS ============

  // Listen to system mode changes (real-time stream)
  Stream<bool> getSystemModeStream() {
    return _firestore
        .collection('system')
        .doc('settings')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data()!['isAutomaticMode'] as bool? ?? false;
      }
      return false;
    });
  }

  // Get current system mode (one-time fetch)
  Future<bool> getSystemMode() async {
    try {
      final snapshot =
          await _firestore.collection('system').doc('settings').get();
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data()!['isAutomaticMode'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Set system mode
  Future<void> setSystemMode(bool isAutomaticMode) async {
    try {
      print('Setting system mode to: $isAutomaticMode');
      await _firestore.collection('system').doc('settings').set({
        'isAutomaticMode': isAutomaticMode,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      print('System mode successfully updated in Firebase');
    } catch (e) {
      print('Error setting system mode: $e');
    }
  }

  // ============ SENSOR CALIBRATION METHODS ============

  // Get system calibration data for a specific user
  Future<SystemCalibration?> getSystemCalibration(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('calibration')
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        return SystemCalibration.fromJson(snapshot.data()!);
      }
      // Return default calibration if none exist
      return SystemCalibration.defaultCalibration();
    } catch (e) {
      return SystemCalibration.defaultCalibration();
    }
  }

  // Save system calibration data for a specific user
  Future<Map<String, dynamic>> saveSystemCalibration(
      String userId, SystemCalibration calibration) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('calibration')
          .set(calibration.toJson());

      return {'success': true, 'message': 'Calibration saved successfully'};
    } on FirebaseException catch (e) {
      String errorMessage = 'Firebase error: ';
      switch (e.code) {
        case 'permission-denied':
          errorMessage += 'Permission denied. Check Firestore rules.';
          break;
        case 'unavailable':
          errorMessage += 'Network unavailable. Check internet connection.';
          break;
        case 'unauthenticated':
          errorMessage += 'User not authenticated. Please sign in again.';
          break;
        default:
          errorMessage += '${e.message}';
      }
      return {'success': false, 'message': errorMessage, 'error': e.toString()};
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
        'error': e.toString()
      };
    }
  }

  // Listen to system calibration changes (real-time stream)
  Stream<SystemCalibration?> getSystemCalibrationStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('calibration')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return SystemCalibration.fromJson(snapshot.data()!);
      }
      return SystemCalibration.defaultCalibration();
    });
  }

  // ============ USER PROFILE METHODS ============

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(userId).get();

      if (snapshot.exists && snapshot.data() != null) {
        return UserProfile.fromJson(snapshot.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save or update user profile
  Future<Map<String, dynamic>> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toJson(), SetOptions(merge: true));

      return {'success': true, 'message': 'Profile updated successfully'};
    } on FirebaseException catch (e) {
      String errorMessage = 'Firebase error: ';
      switch (e.code) {
        case 'permission-denied':
          errorMessage += 'Permission denied. Check Firestore rules.';
          break;
        case 'unavailable':
          errorMessage += 'Network unavailable. Check internet connection.';
          break;
        case 'unauthenticated':
          errorMessage += 'User not authenticated. Please sign in again.';
          break;
        default:
          errorMessage += '${e.message}';
      }
      return {'success': false, 'message': errorMessage, 'error': e.toString()};
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
        'error': e.toString()
      };
    }
  }

  // Listen to user profile changes (real-time stream)
  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfile.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  // Create user profile on first login
  Future<Map<String, dynamic>> createUserProfile(UserProfile profile) async {
    try {
      // Check if profile already exists
      final existingProfile = await getUserProfile(profile.uid);

      if (existingProfile != null) {
        return {'success': true, 'message': 'Profile already exists'};
      }

      // Create new profile
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toJson());

      return {'success': true, 'message': 'Profile created successfully'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create profile: ${e.toString()}',
        'error': e.toString()
      };
    }
  }

  // ============ NOTIFICATION PREFERENCES METHODS ============

  Future<NotificationPreferences?> getNotificationPreferences(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        return NotificationPreferences.fromJson(snapshot.data()!);
      }
      return NotificationPreferences.defaultPreferences();
    } catch (e) {
      return NotificationPreferences.defaultPreferences();
    }
  }

  Future<Map<String, dynamic>> saveNotificationPreferences(
      String userId, NotificationPreferences preferences) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .set(preferences.toJson(), SetOptions(merge: true));

      return {'success': true, 'message': 'Notification preferences saved'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to save preferences: ${e.toString()}',
      };
    }
  }

  Future<List<NotificationHistoryItem>> getNotificationHistory(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => NotificationHistoryItem.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ============ WATERING SCHEDULE METHODS ============

  Future<WateringSchedule?> getWateringSchedule(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('watering_schedule')
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        return WateringSchedule.fromJson(snapshot.data()!);
      }
      return WateringSchedule.defaultSchedule();
    } catch (e) {
      return WateringSchedule.defaultSchedule();
    }
  }

  Future<Map<String, dynamic>> saveWateringSchedule(
      String userId, WateringSchedule schedule) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('watering_schedule')
          .set(schedule.toJson(), SetOptions(merge: true));

      return {'success': true, 'message': 'Watering schedule saved'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to save schedule: ${e.toString()}',
      };
    }
  }

  // ============ ACTIVITY LOG METHODS ============

  // Get activity logs stream (real-time, last 20 activities)
  Stream<List<ActivityLog>> getActivityLogsStream() {
    return _firestore
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Log a new activity
  Future<void> logActivity({
    required String title,
    required String description,
    required String type,
  }) async {
    try {
      await _firestore.collection('activity_logs').add({
        'title': title,
        'description': description,
        'type': type,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  // Save alert to Firestore
  Future<void> saveAlert({
    required String userId,
    required String title,
    required String message,
    required String category,
    required String severity,
  }) async {
    try {
      await _firestore.collection('alerts').add({
        'userId': userId,
        'title': title,
        'message': message,
        'category': category,
        'severity': severity,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });
    } catch (e) {
      print('Error saving alert: $e');
    }
  }
}
