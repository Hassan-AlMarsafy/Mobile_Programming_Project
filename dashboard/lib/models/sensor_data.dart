// Sensor Data Model
class SensorData {
  final double temperature;
  final double pH;
  final double waterLevel;
  final double tds; // Total Dissolved Solids / EC
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

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'pH': pH,
    'waterLevel': waterLevel,
    'tds': tds,
    'lightIntensity': lightIntensity,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory SensorData.fromJson(Map<String, dynamic> json) => SensorData(
    temperature: (json['temperature'] ?? 0).toDouble(),
    pH: (json['pH'] ?? 0).toDouble(),
    waterLevel: (json['waterLevel'] ?? 0).toDouble(),
    tds: (json['tds'] ?? 0).toDouble(),
    lightIntensity: (json['lightIntensity'] ?? 0).toDouble(),
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
  );
}
