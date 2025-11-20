// Sensor service (stub)
// File: lib/services/sensor_service.dart
// TODO: Replace with Firebase/SQLite implementation later.

import '../models/sensor.dart';

class SensorService {
  Future<List<Sensor>> fetchSensors() async {
    // Simulated delay
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Sensor(id: '1', name: 'Temperature', value: 25.5, lastUpdated: DateTime.now()),
      Sensor(id: '2', name: 'pH', value: 6.8, lastUpdated: DateTime.now()),
    ];
  }
}
