import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/watering_schedule.dart';
import '../models/actuator_data.dart';
import 'firestore_service.dart';

/// Service to check and execute watering schedules
class ScheduleService {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  Timer? _scheduleCheckTimer;
  WateringSchedule? _currentSchedule;
  DateTime? _lastWateringTime;
  bool _isWatering = false;
  Timer? _wateringTimer;

  /// Start monitoring the schedule
  void startMonitoring() {
    // Check every minute
    _scheduleCheckTimer?.cancel();
    _scheduleCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkSchedule();
    });

    // Also check immediately
    _checkSchedule();
    print('Schedule monitoring started');
  }

  /// Stop monitoring the schedule
  void stopMonitoring() {
    _scheduleCheckTimer?.cancel();
    _wateringTimer?.cancel();
    print('Schedule monitoring stopped');
  }

  /// Check if it's time to water based on the schedule
  Future<void> _checkSchedule() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get the current schedule
      final schedule = await _firestoreService.getWateringSchedule(user.uid);
      if (schedule == null || !schedule.enabled) {
        return;
      }

      _currentSchedule = schedule;
      final now = DateTime.now();

      // Check if today is a scheduled day
      final dayOfWeek = now.weekday; // 1=Monday, 7=Sunday
      if (!schedule.daysOfWeek.contains(dayOfWeek)) {
        return;
      }

      // Check if we're already watering
      if (_isWatering) {
        return;
      }

      // Determine if it's time to water
      bool shouldWater = false;

      if (schedule.intervalHours == 0) {
        // Once per day - check if we match the start time
        if (now.hour == schedule.startHour && now.minute == schedule.startMinute) {
          // Check if we haven't watered in the last 23 hours (prevent multiple triggers)
          if (_lastWateringTime == null ||
              now.difference(_lastWateringTime!).inHours >= 23) {
            shouldWater = true;
          }
        }
      } else {
        // Interval watering
        // Calculate time since start of day
        final minutesSinceMidnight = now.hour * 60 + now.minute;
        final startMinutesSinceMidnight = schedule.startHour * 60 + schedule.startMinute;

        // Check if we're past the start time
        if (minutesSinceMidnight >= startMinutesSinceMidnight) {
          final minutesSinceStart = minutesSinceMidnight - startMinutesSinceMidnight;
          final intervalMinutes = schedule.intervalHours * 60;

          // Check if we're at an interval boundary
          if (minutesSinceStart % intervalMinutes == 0) {
            // Check if we haven't watered in the last interval (prevent multiple triggers)
            if (_lastWateringTime == null ||
                now.difference(_lastWateringTime!).inMinutes >= intervalMinutes - 1) {
              shouldWater = true;
            }
          }
        }
      }

      if (shouldWater) {
        await _startWatering(schedule.durationMinutes);
      }
    } catch (e) {
      print('Error checking schedule: $e');
    }
  }

  /// Start watering for the specified duration
  Future<void> _startWatering(int durationMinutes) async {
    try {
      _isWatering = true;
      _lastWateringTime = DateTime.now();

      print('🌊 Starting scheduled watering for $durationMinutes minutes');

      // Get current actuator state
      final currentState = await _firestoreService.getActuatorDataStream().first;

      // Turn on water pump
      final wateringState = ActuatorData(
        waterPump: true,
        nutrientPump: currentState?.nutrientPump ?? false,
        lights: currentState?.lights ?? false,
        fan: currentState?.fan ?? false,
        timestamp: DateTime.now(),
      );

      await _firestoreService.sendActuatorCommand(wateringState);

      // Log the activity
      await _firestoreService.logActivity(
        title: 'Scheduled Watering Started',
        description: 'Automatic watering started for $durationMinutes minutes',
        type: 'schedule',
      );

      // Set timer to stop watering after duration
      _wateringTimer?.cancel();
      _wateringTimer = Timer(Duration(minutes: durationMinutes), () {
        _stopWatering();
      });
    } catch (e) {
      print('Error starting watering: $e');
      _isWatering = false;
    }
  }

  /// Stop watering
  Future<void> _stopWatering() async {
    try {
      print('🌊 Stopping scheduled watering');

      // Get current actuator state
      final currentState = await _firestoreService.getActuatorDataStream().first;

      // Turn off water pump
      final stoppedState = ActuatorData(
        waterPump: false,
        nutrientPump: currentState?.nutrientPump ?? false,
        lights: currentState?.lights ?? false,
        fan: currentState?.fan ?? false,
        timestamp: DateTime.now(),
      );

      await _firestoreService.sendActuatorCommand(stoppedState);

      // Log the activity
      await _firestoreService.logActivity(
        title: 'Scheduled Watering Completed',
        description: 'Automatic watering cycle completed',
        type: 'schedule',
      );

      _isWatering = false;
    } catch (e) {
      print('Error stopping watering: $e');
      _isWatering = false;
    }
  }

  /// Manually stop any ongoing watering
  Future<void> stopCurrentWatering() async {
    _wateringTimer?.cancel();
    if (_isWatering) {
      await _stopWatering();
    }
  }

  /// Get current watering status
  bool get isCurrentlyWatering => _isWatering;

  /// Get last watering time
  DateTime? get lastWateringTime => _lastWateringTime;

  /// Dispose resources
  void dispose() {
    _scheduleCheckTimer?.cancel();
    _wateringTimer?.cancel();
  }
}

