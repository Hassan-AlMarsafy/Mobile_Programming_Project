// Sensor model
// File: lib/models/sensor.dart

class Sensor {
  final String id;
  final String name;
  final double value;
  final DateTime lastUpdated;

  Sensor({required this.id, required this.name, required this.value, required this.lastUpdated});
}
