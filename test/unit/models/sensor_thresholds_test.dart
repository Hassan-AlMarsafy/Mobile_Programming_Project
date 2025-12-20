import 'package:flutter_test/flutter_test.dart';
import 'package:hydroponic_app/models/sensor_thresholds.dart';

void main() {
  group('SensorThresholds Model Tests', () {
    test('Constructor creates instance with all values', () {
      final thresholds = SensorThresholds(
        temperatureMin: 18.0,
        temperatureMax: 28.0,
        waterLevelMin: 30.0,
        waterLevelCritical: 10.0,
        phMin: 5.5,
        phMax: 6.5,
        tdsMin: 800.0,
        tdsMax: 1500.0,
        lightIntensityMin: 300.0,
        lightIntensityMax: 800.0,
      );

      expect(thresholds.temperatureMin, 18.0);
      expect(thresholds.temperatureMax, 28.0);
      expect(thresholds.waterLevelMin, 30.0);
      expect(thresholds.waterLevelCritical, 10.0);
      expect(thresholds.phMin, 5.5);
      expect(thresholds.phMax, 6.5);
      expect(thresholds.tdsMin, 800.0);
      expect(thresholds.tdsMax, 1500.0);
      expect(thresholds.lightIntensityMin, 300.0);
      expect(thresholds.lightIntensityMax, 800.0);
    });

    test('Default thresholds factory creates valid instance', () {
      final thresholds = SensorThresholds.defaultThresholds();

      expect(thresholds.temperatureMin, 18.0);
      expect(thresholds.temperatureMax, 28.0);
      expect(thresholds.waterLevelMin, 30.0);
      expect(thresholds.waterLevelCritical, 10.0);
      expect(thresholds.phMin, 5.5);
      expect(thresholds.phMax, 6.5);
      expect(thresholds.tdsMin, 800.0);
      expect(thresholds.tdsMax, 1500.0);
      expect(thresholds.lightIntensityMin, 300.0);
      expect(thresholds.lightIntensityMax, 800.0);
      expect(thresholds.lastUpdated, isNotNull);
    });

    test('fromJson creates instance from JSON', () {
      final json = {
        'temperatureMin': 20.0,
        'temperatureMax': 26.0,
        'waterLevelMin': 35.0,
        'waterLevelCritical': 15.0,
        'phMin': 6.0,
        'phMax': 7.0,
        'tdsMin': 900.0,
        'tdsMax': 1400.0,
        'lightIntensityMin': 400.0,
        'lightIntensityMax': 700.0,
      };

      final thresholds = SensorThresholds.fromJson(json);

      expect(thresholds.temperatureMin, 20.0);
      expect(thresholds.temperatureMax, 26.0);
      expect(thresholds.waterLevelMin, 35.0);
      expect(thresholds.waterLevelCritical, 15.0);
      expect(thresholds.phMin, 6.0);
      expect(thresholds.phMax, 7.0);
    });

    test('toJson converts instance to JSON', () {
      final thresholds = SensorThresholds(
        temperatureMin: 18.0,
        temperatureMax: 28.0,
        waterLevelMin: 30.0,
        waterLevelCritical: 10.0,
        phMin: 5.5,
        phMax: 6.5,
        tdsMin: 800.0,
        tdsMax: 1500.0,
        lightIntensityMin: 300.0,
        lightIntensityMax: 800.0,
      );

      final json = thresholds.toJson();

      expect(json['temperatureMin'], 18.0);
      expect(json['temperatureMax'], 28.0);
      expect(json['waterLevelMin'], 30.0);
      expect(json['waterLevelCritical'], 10.0);
      expect(json['phMin'], 5.5);
      expect(json['phMax'], 6.5);
      expect(json['tdsMin'], 800.0);
      expect(json['tdsMax'], 1500.0);
      expect(json['lightIntensityMin'], 300.0);
      expect(json['lightIntensityMax'], 800.0);
    });

    test('Temperature threshold validation', () {
      final thresholds = SensorThresholds.defaultThresholds();
      
      // Value within range
      expect(22.0 > thresholds.temperatureMin && 22.0 < thresholds.temperatureMax, true);
      
      // Value below range
      expect(15.0 < thresholds.temperatureMin, true);
      
      // Value above range
      expect(30.0 > thresholds.temperatureMax, true);
    });

    test('pH threshold validation', () {
      final thresholds = SensorThresholds.defaultThresholds();
      
      // Value within range
      expect(6.0 > thresholds.phMin && 6.0 < thresholds.phMax, true);
      
      // Value below range
      expect(5.0 < thresholds.phMin, true);
      
      // Value above range
      expect(7.0 > thresholds.phMax, true);
    });
  });
}
