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

  factory ActuatorData.fromJson(Map<String, dynamic> json) {
    return ActuatorData(
      waterPump: json['waterPump'] as bool,
      nutrientPump: json['nutrientPump'] as bool,
      lights: json['lights'] as bool,
      fan: json['fan'] as bool,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'waterPump': waterPump,
      'nutrientPump': nutrientPump,
      'lights': lights,
      'fan': fan,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
