class NotificationPreferences {
  final bool temperatureAlerts;
  final bool waterLevelAlerts;
  final bool phAlerts;
  final bool nutrientAlerts;
  final bool systemAlerts;
  final String severityFilter; // 'all', 'warnings', 'critical'
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool quietHoursEnabled;
  final int quietHoursStart; // 0-23 hours
  final int quietHoursEnd; // 0-23 hours
  final DateTime? lastUpdated;

  NotificationPreferences({
    this.temperatureAlerts = true,
    this.waterLevelAlerts = true,
    this.phAlerts = true,
    this.nutrientAlerts = true,
    this.systemAlerts = true,
    this.severityFilter = 'all',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22, // 10 PM
    this.quietHoursEnd = 7, // 7 AM
    this.lastUpdated,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      temperatureAlerts: json['temperatureAlerts'] ?? true,
      waterLevelAlerts: json['waterLevelAlerts'] ?? true,
      phAlerts: json['phAlerts'] ?? true,
      nutrientAlerts: json['nutrientAlerts'] ?? true,
      systemAlerts: json['systemAlerts'] ?? true,
      severityFilter: json['severityFilter'] ?? 'all',
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: json['quietHoursStart'] ?? 22,
      quietHoursEnd: json['quietHoursEnd'] ?? 7,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperatureAlerts': temperatureAlerts,
      'waterLevelAlerts': waterLevelAlerts,
      'phAlerts': phAlerts,
      'nutrientAlerts': nutrientAlerts,
      'systemAlerts': systemAlerts,
      'severityFilter': severityFilter,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  NotificationPreferences copyWith({
    bool? temperatureAlerts,
    bool? waterLevelAlerts,
    bool? phAlerts,
    bool? nutrientAlerts,
    bool? systemAlerts,
    String? severityFilter,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    DateTime? lastUpdated,
  }) {
    return NotificationPreferences(
      temperatureAlerts: temperatureAlerts ?? this.temperatureAlerts,
      waterLevelAlerts: waterLevelAlerts ?? this.waterLevelAlerts,
      phAlerts: phAlerts ?? this.phAlerts,
      nutrientAlerts: nutrientAlerts ?? this.nutrientAlerts,
      systemAlerts: systemAlerts ?? this.systemAlerts,
      severityFilter: severityFilter ?? this.severityFilter,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static NotificationPreferences defaultPreferences() {
    return NotificationPreferences();
  }
}

class NotificationHistoryItem {
  final String id;
  final String title;
  final String message;
  final String category;
  final String severity;
  final DateTime timestamp;
  final bool read;

  NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.severity,
    required this.timestamp,
    this.read = false,
  });

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      category: json['category'] ?? 'system',
      severity: json['severity'] ?? 'info',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
    };
  }
}
