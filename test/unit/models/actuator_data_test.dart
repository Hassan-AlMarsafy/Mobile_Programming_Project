import 'package:flutter_test/flutter_test.dart';
import 'package:hydroponic_app/models/actuator_data.dart';

void main() {
  group('ActuatorData Model Tests', () {
    test('Constructor creates instance with all values', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      
      final actuator = ActuatorData(
        waterPump: true,
        nutrientPump: false,
        lights: true,
        fan: false,
        timestamp: timestamp,
      );

      expect(actuator.waterPump, true);
      expect(actuator.nutrientPump, false);
      expect(actuator.lights, true);
      expect(actuator.fan, false);
      expect(actuator.timestamp, timestamp);
    });

    test('fromJson creates instance from JSON', () {
      final json = {
        'waterPump': true,
        'nutrientPump': true,
        'lights': false,
        'fan': true,
        'timestamp': 1705319400000, // 2024-01-15 10:30:00 in milliseconds
      };

      final actuator = ActuatorData.fromJson(json);

      expect(actuator.waterPump, true);
      expect(actuator.nutrientPump, true);
      expect(actuator.lights, false);
      expect(actuator.fan, true);
      expect(actuator.timestamp, DateTime.fromMillisecondsSinceEpoch(1705319400000));
    });

    test('toJson converts instance to JSON', () {
      final timestamp = DateTime(2024, 1, 15, 16, 45);
      final actuator = ActuatorData(
        waterPump: false,
        nutrientPump: true,
        lights: true,
        fan: false,
        timestamp: timestamp,
      );

      final json = actuator.toJson();

      expect(json['waterPump'], false);
      expect(json['nutrientPump'], true);
      expect(json['lights'], true);
      expect(json['fan'], false);
      expect(json['timestamp'], timestamp.millisecondsSinceEpoch);
    });

    test('All actuators on', () {
      final actuator = ActuatorData(
        waterPump: true,
        nutrientPump: true,
        lights: true,
        fan: true,
        timestamp: DateTime.now(),
      );

      expect(actuator.waterPump, true);
      expect(actuator.nutrientPump, true);
      expect(actuator.lights, true);
      expect(actuator.fan, true);
    });

    test('All actuators off', () {
      final actuator = ActuatorData(
        waterPump: false,
        nutrientPump: false,
        lights: false,
        fan: false,
        timestamp: DateTime.now(),
      );

      expect(actuator.waterPump, false);
      expect(actuator.nutrientPump, false);
      expect(actuator.lights, false);
      expect(actuator.fan, false);
    });
  });
}
