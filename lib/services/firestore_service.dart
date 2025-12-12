import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_data.dart';
import '../models/actuator_data.dart';
import '../models/sensor_thresholds.dart';

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
      final snapshot = await _firestore
          .collection('sensors')
          .doc('current')
          .get();
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
      final snapshot = await _firestore
          .collection('actuators')
          .doc('current')
          .get();
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

  // ============ SENSOR THRESHOLDS METHODS ============

  // Get sensor thresholds for a specific user
  Future<SensorThresholds?> getSensorThresholds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('thresholds')
          .get();
      
      if (snapshot.exists && snapshot.data() != null) {
        return SensorThresholds.fromJson(snapshot.data()!);
      }
      // Return default thresholds if none exist
      return SensorThresholds.defaultThresholds();
    } catch (e) {
      return SensorThresholds.defaultThresholds();
    }
  }

  // Save sensor thresholds for a specific user
  Future<Map<String, dynamic>> saveSensorThresholds(
      String userId, SensorThresholds thresholds) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('thresholds')
          .set(thresholds.toJson());
      
      return {
        'success': true,
        'message': 'Thresholds updated successfully'
      };
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
      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString()
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
        'error': e.toString()
      };
    }
  }

  // Listen to sensor thresholds changes (real-time stream)
  Stream<SensorThresholds?> getSensorThresholdsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('thresholds')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return SensorThresholds.fromJson(snapshot.data()!);
      }
      return SensorThresholds.defaultThresholds();
    });
  }
}
