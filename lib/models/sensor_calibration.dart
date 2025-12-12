class SensorCalibration {
  final String sensorType; // 'temperature', 'waterLevel', 'ph', 'tds', 'light'
  final double offset;
  final DateTime? lastCalibrated;
  final DateTime? nextCalibrationDue;
  final int calibrationIntervalDays; // How often to calibrate

  SensorCalibration({
    required this.sensorType,
    required this.offset,
    this.lastCalibrated,
    this.nextCalibrationDue,
    this.calibrationIntervalDays = 30, // Default: 30 days
  });

  // Factory constructor for default values
  factory SensorCalibration.defaultCalibration(String sensorType) {
    return SensorCalibration(
      sensorType: sensorType,
      offset: 0.0,
      lastCalibrated: null,
      nextCalibrationDue: null,
      calibrationIntervalDays: 30,
    );
  }

  // From JSON (Firebase)
  factory SensorCalibration.fromJson(Map<String, dynamic> json) {
    return SensorCalibration(
      sensorType: json['sensorType'] ?? '',
      offset: (json['offset'] ?? 0.0).toDouble(),
      lastCalibrated: json['lastCalibrated'] != null
          ? DateTime.parse(json['lastCalibrated'])
          : null,
      nextCalibrationDue: json['nextCalibrationDue'] != null
          ? DateTime.parse(json['nextCalibrationDue'])
          : null,
      calibrationIntervalDays: json['calibrationIntervalDays'] ?? 30,
    );
  }

  // To JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'sensorType': sensorType,
      'offset': offset,
      'lastCalibrated': lastCalibrated?.toIso8601String(),
      'nextCalibrationDue': nextCalibrationDue?.toIso8601String(),
      'calibrationIntervalDays': calibrationIntervalDays,
    };
  }

  // Copy with method for easier updates
  SensorCalibration copyWith({
    String? sensorType,
    double? offset,
    DateTime? lastCalibrated,
    DateTime? nextCalibrationDue,
    int? calibrationIntervalDays,
  }) {
    return SensorCalibration(
      sensorType: sensorType ?? this.sensorType,
      offset: offset ?? this.offset,
      lastCalibrated: lastCalibrated ?? this.lastCalibrated,
      nextCalibrationDue: nextCalibrationDue ?? this.nextCalibrationDue,
      calibrationIntervalDays:
          calibrationIntervalDays ?? this.calibrationIntervalDays,
    );
  }

  // Check if calibration is due
  bool get isCalibrationDue {
    if (nextCalibrationDue == null) return true;
    return DateTime.now().isAfter(nextCalibrationDue!);
  }

  // Check if calibration is approaching (within 7 days)
  bool get isCalibrationApproaching {
    if (nextCalibrationDue == null) return false;
    final daysUntilDue = nextCalibrationDue!.difference(DateTime.now()).inDays;
    return daysUntilDue <= 7 && daysUntilDue > 0;
  }

  // Get days until next calibration
  int get daysUntilCalibration {
    if (nextCalibrationDue == null) return 0;
    return nextCalibrationDue!.difference(DateTime.now()).inDays;
  }

  // Get formatted status
  String get calibrationStatus {
    if (lastCalibrated == null) return 'Never calibrated';
    if (isCalibrationDue) return 'Calibration overdue';
    if (isCalibrationApproaching) {
      return 'Due in $daysUntilCalibration days';
    }
    return 'Good';
  }
}

// Container for all sensor calibrations
class SystemCalibration {
  final Map<String, SensorCalibration> sensors;
  final DateTime? lastUpdated;

  SystemCalibration({
    required this.sensors,
    this.lastUpdated,
  });

  // Factory constructor for default values
  factory SystemCalibration.defaultCalibration() {
    return SystemCalibration(
      sensors: {
        'temperature': SensorCalibration.defaultCalibration('temperature'),
        'waterLevel': SensorCalibration.defaultCalibration('waterLevel'),
        'ph': SensorCalibration.defaultCalibration('ph'),
        'tds': SensorCalibration.defaultCalibration('tds'),
        'light': SensorCalibration.defaultCalibration('light'),
      },
      lastUpdated: DateTime.now(),
    );
  }

  // From JSON (Firebase)
  factory SystemCalibration.fromJson(Map<String, dynamic> json) {
    final Map<String, SensorCalibration> sensors = {};
    
    if (json['sensors'] != null) {
      (json['sensors'] as Map<String, dynamic>).forEach((key, value) {
        sensors[key] = SensorCalibration.fromJson(value);
      });
    }

    return SystemCalibration(
      sensors: sensors.isNotEmpty
          ? sensors
          : SystemCalibration.defaultCalibration().sensors,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  // To JSON (Firebase)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> sensorsJson = {};
    sensors.forEach((key, value) {
      sensorsJson[key] = value.toJson();
    });

    return {
      'sensors': sensorsJson,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  // Get sensor calibration by type
  SensorCalibration? getSensor(String sensorType) {
    return sensors[sensorType];
  }

  // Update a specific sensor calibration
  SystemCalibration updateSensor(String sensorType, SensorCalibration calibration) {
    final updatedSensors = Map<String, SensorCalibration>.from(sensors);
    updatedSensors[sensorType] = calibration;
    
    return SystemCalibration(
      sensors: updatedSensors,
      lastUpdated: DateTime.now(),
    );
  }

  // Check if any sensor needs calibration
  bool get hasCalibrationDue {
    return sensors.values.any((sensor) => sensor.isCalibrationDue);
  }

  // Get count of sensors needing calibration
  int get calibrationDueCount {
    return sensors.values.where((sensor) => sensor.isCalibrationDue).length;
  }
}
