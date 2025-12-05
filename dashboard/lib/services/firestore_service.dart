import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_data.dart';
import '../models/actuator_data.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send sensor data to Firestore
  Future<void> sendSensorData(SensorData data) async {
    try {
      await _firestore.collection('sensors').doc('current').set(data.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Send actuator data to Firestore
  Future<void> sendActuatorData(ActuatorData data) async {
    try {
      await _firestore
          .collection('actuators')
          .doc('current')
          .set(data.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Get current sensor data (one-time read)
  Future<SensorData?> getCurrentSensorData() async {
    try {
      final doc = await _firestore.collection('sensors').doc('current').get();
      if (doc.exists && doc.data() != null) {
        return SensorData.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get current actuator data (one-time read)
  Future<ActuatorData?> getCurrentActuatorData() async {
    try {
      final doc = await _firestore.collection('actuators').doc('current').get();
      if (doc.exists && doc.data() != null) {
        return ActuatorData.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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
}
