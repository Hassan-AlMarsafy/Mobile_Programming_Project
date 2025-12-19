import 'package:flutter_test/flutter_test.dart';
import 'package:hydroponic_app/models/notification_preferences.dart';

void main() {
  group('NotificationPreferences Model Tests', () {
    test('Constructor creates instance with default values', () {
      final prefs = NotificationPreferences();

      expect(prefs.temperatureAlerts, true);
      expect(prefs.waterLevelAlerts, true);
      expect(prefs.phAlerts, true);
      expect(prefs.nutrientAlerts, true);
      expect(prefs.systemAlerts, true);
      expect(prefs.severityFilter, 'all');
      expect(prefs.soundEnabled, true);
      expect(prefs.vibrationEnabled, true);
      expect(prefs.quietHoursEnabled, false);
      expect(prefs.quietHoursStart, 22);
      expect(prefs.quietHoursEnd, 7);
    });

    test('Constructor creates instance with custom values', () {
      final prefs = NotificationPreferences(
        temperatureAlerts: false,
        waterLevelAlerts: true,
        phAlerts: false,
        nutrientAlerts: true,
        systemAlerts: false,
        severityFilter: 'critical',
        soundEnabled: false,
        vibrationEnabled: true,
        quietHoursEnabled: true,
        quietHoursStart: 23,
        quietHoursEnd: 8,
      );

      expect(prefs.temperatureAlerts, false);
      expect(prefs.waterLevelAlerts, true);
      expect(prefs.phAlerts, false);
      expect(prefs.nutrientAlerts, true);
      expect(prefs.systemAlerts, false);
      expect(prefs.severityFilter, 'critical');
      expect(prefs.soundEnabled, false);
      expect(prefs.vibrationEnabled, true);
      expect(prefs.quietHoursEnabled, true);
      expect(prefs.quietHoursStart, 23);
      expect(prefs.quietHoursEnd, 8);
    });

    test('fromJson creates instance from JSON', () {
      final json = {
        'temperatureAlerts': false,
        'waterLevelAlerts': true,
        'phAlerts': false,
        'nutrientAlerts': true,
        'systemAlerts': false,
        'severityFilter': 'warnings',
        'soundEnabled': false,
        'vibrationEnabled': true,
        'quietHoursEnabled': true,
        'quietHoursStart': 23,
        'quietHoursEnd': 8,
      };

      final prefs = NotificationPreferences.fromJson(json);

      expect(prefs.temperatureAlerts, false);
      expect(prefs.waterLevelAlerts, true);
      expect(prefs.phAlerts, false);
      expect(prefs.nutrientAlerts, true);
      expect(prefs.systemAlerts, false);
      expect(prefs.severityFilter, 'warnings');
      expect(prefs.soundEnabled, false);
      expect(prefs.vibrationEnabled, true);
      expect(prefs.quietHoursEnabled, true);
      expect(prefs.quietHoursStart, 23);
      expect(prefs.quietHoursEnd, 8);
    });

    test('toJson converts instance to JSON', () {
      final prefs = NotificationPreferences(
        temperatureAlerts: true,
        waterLevelAlerts: false,
        phAlerts: true,
        nutrientAlerts: false,
        systemAlerts: true,
        severityFilter: 'critical',
        soundEnabled: true,
        vibrationEnabled: false,
        quietHoursEnabled: true,
        quietHoursStart: 22,
        quietHoursEnd: 7,
      );

      final json = prefs.toJson();

      expect(json['temperatureAlerts'], true);
      expect(json['waterLevelAlerts'], false);
      expect(json['phAlerts'], true);
      expect(json['nutrientAlerts'], false);
      expect(json['systemAlerts'], true);
      expect(json['severityFilter'], 'critical');
      expect(json['soundEnabled'], true);
      expect(json['vibrationEnabled'], false);
      expect(json['quietHoursEnabled'], true);
      expect(json['quietHoursStart'], 22);
      expect(json['quietHoursEnd'], 7);
    });

    test('All alerts enabled configuration', () {
      final prefs = NotificationPreferences();

      expect(prefs.temperatureAlerts, true);
      expect(prefs.waterLevelAlerts, true);
      expect(prefs.phAlerts, true);
      expect(prefs.nutrientAlerts, true);
      expect(prefs.systemAlerts, true);
    });

    test('All alerts disabled configuration', () {
      final prefs = NotificationPreferences(
        temperatureAlerts: false,
        waterLevelAlerts: false,
        phAlerts: false,
        nutrientAlerts: false,
        systemAlerts: false,
      );

      expect(prefs.temperatureAlerts, false);
      expect(prefs.waterLevelAlerts, false);
      expect(prefs.phAlerts, false);
      expect(prefs.nutrientAlerts, false);
      expect(prefs.systemAlerts, false);
    });

    test('Severity filter options', () {
      final prefsAll = NotificationPreferences(severityFilter: 'all');
      final prefsWarnings = NotificationPreferences(severityFilter: 'warnings');
      final prefsCritical = NotificationPreferences(severityFilter: 'critical');

      expect(prefsAll.severityFilter, 'all');
      expect(prefsWarnings.severityFilter, 'warnings');
      expect(prefsCritical.severityFilter, 'critical');
    });

    test('Quiet hours configuration', () {
      final prefs = NotificationPreferences(
        quietHoursEnabled: true,
        quietHoursStart: 22,
        quietHoursEnd: 7,
      );

      expect(prefs.quietHoursEnabled, true);
      expect(prefs.quietHoursStart, 22); // 10 PM
      expect(prefs.quietHoursEnd, 7); // 7 AM
      
      // Check if current hour would be in quiet hours (example logic)
      // If current hour is >= 22 or < 7, it's quiet hours
      final testHourQuiet = 23;
      final testHourNormal = 12;
      
      expect(testHourQuiet >= prefs.quietHoursStart || testHourQuiet < prefs.quietHoursEnd, true);
      expect(testHourNormal >= prefs.quietHoursStart && testHourNormal < prefs.quietHoursEnd, false);
    });
  });
}
