class ActivityLog {
  final String id;
  final String title;
  final String description;
  final String
      type; // 'water_pump', 'nutrient_pump', 'lights', 'fan', 'temperature', 'ph', 'system'
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
  });

  factory ActivityLog.fromMap(Map<String, dynamic> map, String docId) {
    return ActivityLog(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'system',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
