import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/actuator_data.dart';
import '../services/firestore_service.dart';

class SensorViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<SensorData?>? _sensorSubscription;
  StreamSubscription<ActuatorData?>? _actuatorSubscription;

  // Sensor data
  SensorData? sensorData;

  // Actuator data
  ActuatorData? actuatorData;

  bool loading = true;

  SensorViewModel() {
    _listenToFirebaseData();
  }

  // Listen to Firebase changes and update local state
  void _listenToFirebaseData() {
    _sensorSubscription = _firestoreService.getSensorDataStream().listen((
      data,
    ) {
      if (data != null) {
        sensorData = data;
        loading = false;
        notifyListeners();
      }
    });

    _actuatorSubscription = _firestoreService.getActuatorDataStream().listen((
      data,
    ) {
      if (data != null) {
        actuatorData = data;
        notifyListeners();
      }
    });
  }

  // Send actuator command to Firebase (for future control features)
  Future<void> sendActuatorCommand(ActuatorData data) async {
    await _firestoreService.sendActuatorCommand(data);
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _actuatorSubscription?.cancel();
    super.dispose();
  }
}
