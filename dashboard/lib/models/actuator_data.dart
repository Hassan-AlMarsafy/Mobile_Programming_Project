// Actuator Data Model
class ActuatorData {
  final bool waterPump;
  final bool nutrientPump;
  final bool lights;
  final bool fan;
  final DateTime timestamp;

  ActuatorData({
    required this.waterPump,
    required this.nutrientPump,
    required this.lights,
    required this.fan,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'waterPump': waterPump,
    'nutrientPump': nutrientPump,
    'lights': lights,
    'fan': fan,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory ActuatorData.fromJson(Map<String, dynamic> json) => ActuatorData(
    waterPump: json['waterPump'] ?? false,
    nutrientPump: json['nutrientPump'] ?? false,
    lights: json['lights'] ?? false,
    fan: json['fan'] ?? false,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
  );
}
