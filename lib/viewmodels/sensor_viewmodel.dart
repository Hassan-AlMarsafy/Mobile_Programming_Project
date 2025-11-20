// Sensor ViewModel (ChangeNotifier)
// File: lib/viewmodels/sensor_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/sensor.dart';
import '../services/sensor_service.dart';

class SensorViewModel extends ChangeNotifier {
  final SensorService _service;
  List<Sensor> sensors = [];
  bool loading = false;

  SensorViewModel({SensorService? service}) : _service = service ?? SensorService();

  Future<void> loadSensors() async {
    loading = true;
    notifyListeners();
    sensors = await _service.fetchSensors();
    loading = false;
    notifyListeners();
  }
}
