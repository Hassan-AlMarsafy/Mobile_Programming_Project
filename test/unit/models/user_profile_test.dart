import 'package:flutter_test/flutter_test.dart';
import 'package:hydroponic_app/models/user.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('Constructor creates instance with all required values', () {
      final user = UserProfile(
        uid: '123',
        displayName: 'Test User',
        email: 'test@example.com',
        phoneNumber: '+1234567890',
        photoURL: 'https://example.com/photo.jpg',
        createdAt: DateTime(2024, 1, 15, 10, 30),
      );

      expect(user.uid, '123');
      expect(user.displayName, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.phoneNumber, '+1234567890');
      expect(user.photoURL, 'https://example.com/photo.jpg');
      expect(user.createdAt, DateTime(2024, 1, 15, 10, 30));
    });

    test('Constructor sets default values correctly', () {
      final user = UserProfile(
        uid: '123',
        displayName: 'Test User',
        email: 'test@example.com',
      );

      expect(user.notificationsEnabled, true);
      expect(user.autoWatering, true);
      expect(user.temperatureUnit, 'Celsius');
      expect(user.language, 'English');
      expect(user.biometricEnabled, false);
    });

    test('fromJson creates instance from JSON', () {
      final json = {
        'uid': '456',
        'displayName': 'John Doe',
        'email': 'john@example.com',
        'phoneNumber': '+9876543210',
        'photoURL': 'https://example.com/john.jpg',
        'createdAt': '2024-01-15T10:30:00.000',
        'lastUpdated': '2024-01-16T12:00:00.000',
        'notificationsEnabled': false,
        'autoWatering': false,
        'temperatureUnit': 'Fahrenheit',
        'language': 'Spanish',
        'biometricEnabled': true,
      };

      final user = UserProfile.fromJson(json);

      expect(user.uid, '456');
      expect(user.displayName, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.phoneNumber, '+9876543210');
      expect(user.photoURL, 'https://example.com/john.jpg');
      expect(user.notificationsEnabled, false);
      expect(user.autoWatering, false);
      expect(user.temperatureUnit, 'Fahrenheit');
      expect(user.language, 'Spanish');
      expect(user.biometricEnabled, true);
    });

    test('toJson converts instance to JSON', () {
      final user = UserProfile(
        uid: '789',
        displayName: 'Jane Smith',
        email: 'jane@example.com',
        phoneNumber: '+1122334455',
        notificationsEnabled: true,
        autoWatering: true,
        temperatureUnit: 'Celsius',
        language: 'French',
        biometricEnabled: true,
      );

      final json = user.toJson();

      expect(json['uid'], '789');
      expect(json['displayName'], 'Jane Smith');
      expect(json['email'], 'jane@example.com');
      expect(json['phoneNumber'], '+1122334455');
      expect(json['notificationsEnabled'], true);
      expect(json['autoWatering'], true);
      expect(json['temperatureUnit'], 'Celsius');
      expect(json['language'], 'French');
      expect(json['biometricEnabled'], true);
    });

    test('copyWith creates new instance with updated values', () {
      final user = UserProfile(
        uid: '123',
        displayName: 'Original User',
        email: 'original@example.com',
        notificationsEnabled: true,
        autoWatering: true,
        temperatureUnit: 'Celsius',
      );

      final updatedUser = user.copyWith(
        displayName: 'Updated User',
        autoWatering: false,
      );

      expect(updatedUser.uid, '123'); // Unchanged
      expect(updatedUser.displayName, 'Updated User'); // Changed
      expect(updatedUser.autoWatering, false); // Changed
      expect(updatedUser.temperatureUnit, 'Celsius'); // Unchanged
    });

    test('UserProfile handles null optional fields', () {
      final user = UserProfile(
        uid: '123',
        displayName: 'Test User',
        email: 'test@example.com',
      );

      expect(user.phoneNumber, null);
      expect(user.photoURL, null);
      expect(user.createdAt, null);
      expect(user.lastUpdated, null);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'uid': '999',
        'displayName': 'Minimal User',
        'email': 'minimal@example.com',
      };

      final user = UserProfile.fromJson(json);

      expect(user.uid, '999');
      expect(user.displayName, 'Minimal User');
      expect(user.email, 'minimal@example.com');
      expect(user.phoneNumber, null);
      expect(user.photoURL, null);
      // Should use default values
      expect(user.notificationsEnabled, true);
      expect(user.autoWatering, true);
    });
  });
}
