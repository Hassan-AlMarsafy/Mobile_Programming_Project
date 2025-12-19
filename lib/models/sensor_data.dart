class SensorData {
  final double temperature;
  final double pH;
  final double waterLevel;
  final double tds;
  final double lightIntensity;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.pH,
    required this.waterLevel,
    required this.tds,
    required this.lightIntensity,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] as num).toDouble(),
      pH: (json['pH'] as num).toDouble(),
      waterLevel: (json['waterLevel'] as num).toDouble(),
      tds: (json['tds'] as num).toDouble(),
      lightIntensity: (json['lightIntensity'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'pH': pH,
      'waterLevel': waterLevel,
      'tds': tds,
      'lightIntensity': lightIntensity,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
