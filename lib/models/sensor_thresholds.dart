class SensorThresholds {
  final double temperatureMin;
  final double temperatureMax;
  final double waterLevelMin;
  final double waterLevelCritical;
  final double phMin;
  final double phMax;
  final double tdsMin;
  final double tdsMax;
  final double lightIntensityMin;
  final double lightIntensityMax;
  final DateTime? lastUpdated;

  SensorThresholds({
    required this.temperatureMin,
    required this.temperatureMax,
    required this.waterLevelMin,
    required this.waterLevelCritical,
    required this.phMin,
    required this.phMax,
    required this.tdsMin,
    required this.tdsMax,
    required this.lightIntensityMin,
    required this.lightIntensityMax,
    this.lastUpdated,
  });

  // Factory constructor for default values
  factory SensorThresholds.defaultThresholds() {
    return SensorThresholds(
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
      lastUpdated: DateTime.now(),
    );
  }

  // From JSON (Firebase)
  factory SensorThresholds.fromJson(Map<String, dynamic> json) {
    return SensorThresholds(
      temperatureMin: (json['temperatureMin'] ?? 18.0).toDouble(),
      temperatureMax: (json['temperatureMax'] ?? 28.0).toDouble(),
      waterLevelMin: (json['waterLevelMin'] ?? 30.0).toDouble(),
      waterLevelCritical: (json['waterLevelCritical'] ?? 10.0).toDouble(),
      phMin: (json['phMin'] ?? 5.5).toDouble(),
      phMax: (json['phMax'] ?? 6.5).toDouble(),
      tdsMin: (json['tdsMin'] ?? 800.0).toDouble(),
      tdsMax: (json['tdsMax'] ?? 1500.0).toDouble(),
      lightIntensityMin: (json['lightIntensityMin'] ?? 300.0).toDouble(),
      lightIntensityMax: (json['lightIntensityMax'] ?? 800.0).toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  // To JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'temperatureMin': temperatureMin,
      'temperatureMax': temperatureMax,
      'waterLevelMin': waterLevelMin,
      'waterLevelCritical': waterLevelCritical,
      'phMin': phMin,
      'phMax': phMax,
      'tdsMin': tdsMin,
      'tdsMax': tdsMax,
      'lightIntensityMin': lightIntensityMin,
      'lightIntensityMax': lightIntensityMax,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  // From Map (SQLite)
  factory SensorThresholds.fromMap(Map<String, dynamic> map) {
    return SensorThresholds(
      temperatureMin: (map['temperature_min'] ?? 18.0).toDouble(),
      temperatureMax: (map['temperature_max'] ?? 28.0).toDouble(),
      waterLevelMin: (map['water_level_min'] ?? 30.0).toDouble(),
      waterLevelCritical: (map['water_level_critical'] ?? 10.0).toDouble(),
      phMin: (map['ph_min'] ?? 5.5).toDouble(),
      phMax: (map['ph_max'] ?? 6.5).toDouble(),
      tdsMin: (map['tds_min'] ?? 800.0).toDouble(),
      tdsMax: (map['tds_max'] ?? 1500.0).toDouble(),
      lightIntensityMin: (map['light_intensity_min'] ?? 300.0).toDouble(),
      lightIntensityMax: (map['light_intensity_max'] ?? 800.0).toDouble(),
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'])
          : null,
    );
  }

  // To Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'temperature_min': temperatureMin,
      'temperature_max': temperatureMax,
      'water_level_min': waterLevelMin,
      'water_level_critical': waterLevelCritical,
      'ph_min': phMin,
      'ph_max': phMax,
      'tds_min': tdsMin,
      'tds_max': tdsMax,
      'light_intensity_min': lightIntensityMin,
      'light_intensity_max': lightIntensityMax,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  // Copy with method for easier updates
  SensorThresholds copyWith({
    double? temperatureMin,
    double? temperatureMax,
    double? waterLevelMin,
    double? waterLevelCritical,
    double? phMin,
    double? phMax,
    double? tdsMin,
    double? tdsMax,
    double? lightIntensityMin,
    double? lightIntensityMax,
    DateTime? lastUpdated,
  }) {
    return SensorThresholds(
      temperatureMin: temperatureMin ?? this.temperatureMin,
      temperatureMax: temperatureMax ?? this.temperatureMax,
      waterLevelMin: waterLevelMin ?? this.waterLevelMin,
      waterLevelCritical: waterLevelCritical ?? this.waterLevelCritical,
      phMin: phMin ?? this.phMin,
      phMax: phMax ?? this.phMax,
      tdsMin: tdsMin ?? this.tdsMin,
      tdsMax: tdsMax ?? this.tdsMax,
      lightIntensityMin: lightIntensityMin ?? this.lightIntensityMin,
      lightIntensityMax: lightIntensityMax ?? this.lightIntensityMax,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
