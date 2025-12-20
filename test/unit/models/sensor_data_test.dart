import 'package:flutter_test/flutter_test.dart';
import 'package:hydroponic_app/models/sensor_data.dart';

void main() {
  group('SensorData Model Tests', () {
    test('Constructor creates instance with all values', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      
      final sensorData = SensorData(
        temperature: 25.5,
        pH: 6.2,
        waterLevel: 75.0,
        tds: 1200.0,
        lightIntensity: 500.0,
        timestamp: timestamp,
      );

      expect(sensorData.temperature, 25.5);
      expect(sensorData.pH, 6.2);
      expect(sensorData.waterLevel, 75.0);
      expect(sensorData.tds, 1200.0);
      expect(sensorData.lightIntensity, 500.0);
      expect(sensorData.timestamp, timestamp);
    });

    test('fromJson creates instance from JSON', () {
      final json = {
        'temperature': 22.3,
        'pH': 6.5,
        'waterLevel': 80.0,
        'tds': 1100.0,
        'lightIntensity': 450.0,
        'timestamp': 1705319400000,
      };

      final sensorData = SensorData.fromJson(json);

      expect(sensorData.temperature, 22.3);
      expect(sensorData.pH, 6.5);
      expect(sensorData.waterLevel, 80.0);
      expect(sensorData.tds, 1100.0);
      expect(sensorData.lightIntensity, 450.0);
      expect(sensorData.timestamp, DateTime.fromMillisecondsSinceEpoch(1705319400000));
    });

    test('toJson converts instance to JSON', () {
      final timestamp = DateTime(2024, 1, 15, 14, 30);
      final sensorData = SensorData(
        temperature: 24.0,
        pH: 6.0,
        waterLevel: 70.0,
        tds: 1300.0,
        lightIntensity: 550.0,
        timestamp: timestamp,
      );

      final json = sensorData.toJson();

      expect(json['temperature'], 24.0);
      expect(json['pH'], 6.0);
      expect(json['waterLevel'], 70.0);
      expect(json['tds'], 1300.0);
      expect(json['lightIntensity'], 550.0);
      expect(json['timestamp'], timestamp.millisecondsSinceEpoch);
    });

    test('Handles numeric type conversion', () {
      final json = {
        'temperature': 25,  // int instead of double
        'pH': 6,            // int instead of double
        'waterLevel': 75,   // int instead of double
        'tds': 1200,        // int instead of double
        'lightIntensity': 500, // int instead of double
        'timestamp': 1705319400000,
      };

      final sensorData = SensorData.fromJson(json);

      expect(sensorData.temperature, 25.0);
      expect(sensorData.pH, 6.0);
      expect(sensorData.waterLevel, 75.0);
      expect(sensorData.tds, 1200.0);
      expect(sensorData.lightIntensity, 500.0);
    });

    test('Sensor data with boundary values', () {
      final sensorData = SensorData(
        temperature: 0.0,
        pH: 0.0,
        waterLevel: 0.0,
        tds: 0.0,
        lightIntensity: 0.0,
        timestamp: DateTime.now(),
      );

      expect(sensorData.temperature, 0.0);
      expect(sensorData.pH, 0.0);
      expect(sensorData.waterLevel, 0.0);
      expect(sensorData.tds, 0.0);
      expect(sensorData.lightIntensity, 0.0);
    });
  });
}
