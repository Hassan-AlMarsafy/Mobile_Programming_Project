import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../models/actuator_data.dart';
import '../services/firestore_service.dart';

class SimulatorViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  Timer? _timer;
  StreamSubscription<SensorData?>? _sensorSubscription;
  StreamSubscription<ActuatorData?>? _actuatorSubscription;

  // Current sensor values
  double temperature = 25.0;
  double pH = 6.5;
  double waterLevel = 75.0;
  double tds = 800.0;
  double lightIntensity = 500.0;

  // Actuator states
  bool waterPump = false;
  bool nutrientPump = false;
  bool lights = true;
  bool fan = false;

  // Simulation settings
  bool isAutoMode = true;
  int updateInterval = 5; // seconds

  final Random _random = Random();

  SimulatorViewModel() {
    _listenToFirebaseChanges();
  }

  // Listen to Firebase changes and update local state
  void _listenToFirebaseChanges() {
    _sensorSubscription = _firestoreService.getSensorDataStream().listen((
      data,
    ) {
      if (data != null) {
        temperature = data.temperature;
        pH = data.pH;
        waterLevel = data.waterLevel;
        tds = data.tds;
        lightIntensity = data.lightIntensity;
        notifyListeners();
      }
    });

    _actuatorSubscription = _firestoreService.getActuatorDataStream().listen((
      data,
    ) {
      if (data != null) {
        waterPump = data.waterPump;
        nutrientPump = data.nutrientPump;
        lights = data.lights;
        fan = data.fan;
        notifyListeners();
      }
    });
  }

  // Start sending data automatically
  void startSimulation() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: updateInterval), (_) {
      if (isAutoMode) {
        _generateRandomData();
      }
      _sendData();
    });
    notifyListeners();
  }

  // Stop sending data
  void stopSimulation() {
    _timer?.cancel();
    notifyListeners();
  }

  // Generate realistic random sensor data
  void _generateRandomData() {
    temperature = (temperature + _random.nextDouble() * 2 - 1).clamp(
      20.0,
      30.0,
    );
    pH = (pH + _random.nextDouble() * 0.2 - 0.1).clamp(5.5, 7.5);
    waterLevel = (waterLevel + _random.nextDouble() * 5 - 2.5).clamp(
      0.0,
      100.0,
    );
    tds = (tds + _random.nextDouble() * 50 - 25).clamp(500.0, 1500.0);
    lightIntensity = (lightIntensity + _random.nextDouble() * 100 - 50).clamp(
      0.0,
      1000.0,
    );
    notifyListeners();
  }

  // Send data to Firebase
  Future<void> _sendData() async {
    final sensorData = SensorData(
      temperature: temperature,
      pH: pH,
      waterLevel: waterLevel,
      tds: tds,
      lightIntensity: lightIntensity,
      timestamp: DateTime.now(),
    );

    final actuatorData = ActuatorData(
      waterPump: waterPump,
      nutrientPump: nutrientPump,
      lights: lights,
      fan: fan,
      timestamp: DateTime.now(),
    );

    try {
      await _firestoreService.sendSensorData(sensorData);
      await _firestoreService.sendActuatorData(actuatorData);
    } catch (e) {
      // Silently handle error
    }
  }

  // Manual control methods
  void setTemperature(double value) {
    temperature = value;
    _sendData();
    notifyListeners();
  }

  void setPH(double value) {
    pH = value;
    _sendData();
    notifyListeners();
  }

  void setWaterLevel(double value) {
    waterLevel = value;
    _sendData();
    notifyListeners();
  }

  void setTDS(double value) {
    tds = value;
    _sendData();
    notifyListeners();
  }

  void setLightIntensity(double value) {
    lightIntensity = value;
    _sendData();
    notifyListeners();
  }

  void toggleWaterPump() {
    waterPump = !waterPump;
    _sendData();
    notifyListeners();
  }

  void toggleNutrientPump() {
    nutrientPump = !nutrientPump;
    _sendData();
    notifyListeners();
  }

  void toggleLights() {
    lights = !lights;
    _sendData();
    notifyListeners();
  }

  void toggleFan() {
    fan = !fan;
    _sendData();
    notifyListeners();
  }

  void toggleAutoMode() {
    isAutoMode = !isAutoMode;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sensorSubscription?.cancel();
    _actuatorSubscription?.cancel();
    super.dispose();
  }
}
