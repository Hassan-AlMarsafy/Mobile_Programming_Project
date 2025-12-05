import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_data.dart';
import '../models/actuator_data.dart';

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
}
