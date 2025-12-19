import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/sensor_data.dart';
import '../models/actuator_data.dart';
import '../models/activity_log.dart';
import '../services/firestore_service.dart';
import '../services/database_service.dart';

class SensorViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseService _databaseService = DatabaseService();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<SensorData?>? _sensorSubscription;
  StreamSubscription<ActuatorData?>? _actuatorSubscription;
  StreamSubscription<bool>? _modeSubscription;
  StreamSubscription<List<ActivityLog>>? _activitySubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Sensor data
  SensorData? sensorData;

  // Actuator data
  ActuatorData? actuatorData;

  // Activity logs
  List<ActivityLog> activityLogs = [];

  // System mode
  bool isAutomaticMode = false;

  bool loading = true;

  // Offline mode
  bool isOffline = false;
  DateTime? lastSyncTime;

  SensorViewModel() {
    _initConnectivity();
    _listenToFirebaseData();
  }

  void _initConnectivity() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
          final wasOffline = isOffline;
          isOffline = results.contains(ConnectivityResult.none);

          if (wasOffline && !isOffline) {
            // Just came online - sync queued commands
            _syncQueuedCommands();
          }

          notifyListeners();
        });

    // Check initial connectivity
    _connectivity.checkConnectivity().then((results) {
      isOffline = results.contains(ConnectivityResult.none);
      if (isOffline) {
        _loadCachedData();
      }
      notifyListeners();
    });
  }

  Future<void> _loadCachedData() async {
    final cachedSensor = await _databaseService.getCachedSensorData();
    final cachedActuator = await _databaseService.getCachedActuatorData();

    if (cachedSensor != null) {
      sensorData = cachedSensor;
      lastSyncTime = cachedSensor.timestamp;
      loading = false;
      notifyListeners();
    }

    if (cachedActuator != null) {
      actuatorData = cachedActuator;
      notifyListeners();
    }
  }

  Future<void> _syncQueuedCommands() async {
    final commands = await _databaseService.getUnsynedCommands();

    for (final cmd in commands) {
      try {
        final payload = jsonDecode(cmd['payload'] as String);

        if (cmd['command_type'] == 'actuator') {
          final data = ActuatorData(
            waterPump: payload['waterPump'] as bool,
            nutrientPump: payload['nutrientPump'] as bool,
            lights: payload['lights'] as bool,
            fan: payload['fan'] as bool,
            timestamp: DateTime.now(),
          );
          await _firestoreService.sendActuatorCommand(data);
        }

        await _databaseService.markCommandSynced(cmd['id'] as int);
      } catch (e) {
        print('Error syncing command: $e');
      }
    }

    await _databaseService.clearSyncedCommands();
  }

  // Listen to Firebase changes and update local state
  void _listenToFirebaseData() {
    _sensorSubscription = _firestoreService.getSensorDataStream().listen((
        data,
        ) {
      if (data != null) {
        sensorData = data;
        loading = false;
        lastSyncTime = data.timestamp;
        notifyListeners();

        // Cache to SQLite for offline mode
        _databaseService.cacheSensorData(data);
        _databaseService.addSensorHistory(data);

        print(
            'Sensor data updated: Temp=${data.temperature}°C, pH=${data.pH}, Water=${data.waterLevel}%, Light=${data.lightIntensity} lux');

        // Run automatic control logic when sensor data updates
        if (isAutomaticMode) {
          print('Automatic mode is ON - checking if control is needed...');
          if (actuatorData != null) {
            _runAutomaticControl();
          } else {
            print(
                'Actuator data not available yet, skipping automatic control');
          }
        } else {
          print('Manual mode is ON - skipping automatic control');
        }
      }
    });

    _actuatorSubscription = _firestoreService.getActuatorDataStream().listen((
        data,
        ) {
      if (data != null) {
        actuatorData = data;
        // Cache to SQLite for offline mode
        _databaseService.cacheActuatorData(data);
        notifyListeners();
      }
    });

    _modeSubscription = _firestoreService.getSystemModeStream().listen((
        mode,
        ) {
      isAutomaticMode = mode;
      notifyListeners();

      // Run automatic control when mode switches to automatic
      if (mode && sensorData != null && actuatorData != null) {
        _runAutomaticControl();
      }
    });

    // Listen to activity logs
    _activitySubscription = _firestoreService.getActivityLogsStream().listen((
        logs,
        ) {
      activityLogs = logs;
      notifyListeners();
    });
  }

  // Automatic control logic based on sensor readings
  void _runAutomaticControl() async {
    print('_runAutomaticControl called');
    print('   - sensorData: ${sensorData != null ? "available" : "null"}');
    print('   - actuatorData: ${actuatorData != null ? "available" : "null"}');
    print('   - isAutomaticMode: $isAutomaticMode');

    if (sensorData == null || actuatorData == null || !isAutomaticMode) {
      print('Skipping automatic control - missing requirements');
      return;
    }

    print('Running automatic control checks...');

    bool needsUpdate = false;
    bool newWaterPump = actuatorData!.waterPump;
    bool newNutrientPump = actuatorData!.nutrientPump;
    bool newLights = actuatorData!.lights;
    bool newFan = actuatorData!.fan;

    print(
        '   Current states: Fan=${actuatorData!.fan}, Water=${actuatorData!.waterPump}, Nutrients=${actuatorData!.nutrientPump}, Lights=${actuatorData!.lights}');

    // Temperature Control: Turn on fan if temperature > 28°C
    if (sensorData!.temperature > 28 && !actuatorData!.fan) {
      newFan = true;
      needsUpdate = true;
      print(
          'Auto: Temperature high (${sensorData!.temperature}°C) - Turning ON fan');
    } else if (sensorData!.temperature <= 25 && actuatorData!.fan) {
      newFan = false;
      needsUpdate = true;
      print(
          'Auto: Temperature normal (${sensorData!.temperature}°C) - Turning OFF fan');
    } else {
      print(
          'Temperature (${sensorData!.temperature}°C) - No change needed (fan=${actuatorData!.fan})');
    }

    // pH Control: Turn on nutrient pump if pH is low
    if (sensorData!.pH < 6.0 && !actuatorData!.nutrientPump) {
      newNutrientPump = true;
      needsUpdate = true;
      print('Auto: pH low (${sensorData!.pH}) - Turning ON nutrient pump');
    } else if (sensorData!.pH >= 6.5 && actuatorData!.nutrientPump) {
      newNutrientPump = false;
      needsUpdate = true;
      print(
          'Auto: pH normalized (${sensorData!.pH}) - Turning OFF nutrient pump');
    } else {
      print(
          'pH (${sensorData!.pH}) - No change needed (pump=${actuatorData!.nutrientPump})');
    }

    // Water Level Control: Turn on water pump if level is low
    if (sensorData!.waterLevel < 40 && !actuatorData!.waterPump) {
      newWaterPump = true;
      needsUpdate = true;
      print(
          'Auto: Water level low (${sensorData!.waterLevel}%) - Turning ON water pump');
    } else if (sensorData!.waterLevel >= 80 && actuatorData!.waterPump) {
      newWaterPump = false;
      needsUpdate = true;
      print(
          'Auto: Water level sufficient (${sensorData!.waterLevel}%) - Turning OFF water pump');
    } else {
      print(
          'Water level (${sensorData!.waterLevel}%) - No change needed (pump=${actuatorData!.waterPump})');
    }

    // Light Intensity Control: Turn on grow lights if intensity is low
    if (sensorData!.lightIntensity < 300 && !actuatorData!.lights) {
      newLights = true;
      needsUpdate = true;
      print(
          'Auto: Light intensity low (${sensorData!.lightIntensity} lux) - Turning ON lights');
    } else if (sensorData!.lightIntensity >= 800 && actuatorData!.lights) {
      newLights = false;
      needsUpdate = true;
      print(
          'Auto: Light intensity sufficient (${sensorData!.lightIntensity} lux) - Turning OFF lights');
    } else {
      print(
          'Light (${sensorData!.lightIntensity} lux) - No change needed (lights=${actuatorData!.lights})');
    }

    // Send update to Firebase if any actuator state changed
    if (needsUpdate) {
      print('Sending actuator update to Firebase...');
      final updatedData = ActuatorData(
        waterPump: newWaterPump,
        nutrientPump: newNutrientPump,
        lights: newLights,
        fan: newFan,
        timestamp: DateTime.now(),
      );

      await sendActuatorCommand(updatedData);
      print('Auto: Actuator states updated in Firebase');
    } else {
      print('No actuator changes needed');
    }
  }

  // Send actuator command to Firebase (queue if offline)
  Future<void> sendActuatorCommand(ActuatorData data) async {
    if (isOffline) {
      // Queue command for later sync
      await _databaseService.queueCommand(
        commandType: 'actuator',
        payload: jsonEncode({
          'waterPump': data.waterPump,
          'nutrientPump': data.nutrientPump,
          'lights': data.lights,
          'fan': data.fan,
        }),
      );
      // Update local state
      actuatorData = data;
      _databaseService.cacheActuatorData(data);
      notifyListeners();
    } else {
      await _firestoreService.sendActuatorCommand(data);
    }
  }

  // Set system mode
  Future<void> setSystemMode(bool newMode) async {
    // Optimistically update local state for immediate UI feedback
    isAutomaticMode = newMode;
    notifyListeners();

    // Update Firebase (stream will confirm the change)
    await _firestoreService.setSystemMode(newMode);

    // Run automatic control if switching to automatic mode
    if (newMode && sensorData != null && actuatorData != null) {
      _runAutomaticControl();
    }
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _actuatorSubscription?.cancel();
    _modeSubscription?.cancel();
    _activitySubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
