class WateringSchedule {
  final bool enabled;
  final List<int> daysOfWeek; // 1=Monday, 7=Sunday
  final int startHour; // 0-23
  final int startMinute; // 0-59
  final int durationMinutes;
  final int intervalHours; // How often to water (0 = once per day)
  final DateTime? lastUpdated;

  WateringSchedule({
    this.enabled = false,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    this.startHour = 7,
    this.startMinute = 0,
    this.durationMinutes = 5,
    this.intervalHours = 0,
    this.lastUpdated,
  });

  factory WateringSchedule.fromJson(Map<String, dynamic> json) {
    return WateringSchedule(
      enabled: json['enabled'] ?? false,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<int>.from(json['daysOfWeek'])
          : [1, 2, 3, 4, 5, 6, 7],
      startHour: json['startHour'] ?? 7,
      startMinute: json['startMinute'] ?? 0,
      durationMinutes: json['durationMinutes'] ?? 5,
      intervalHours: json['intervalHours'] ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'daysOfWeek': daysOfWeek,
      'startHour': startHour,
      'startMinute': startMinute,
      'durationMinutes': durationMinutes,
      'intervalHours': intervalHours,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  WateringSchedule copyWith({
    bool? enabled,
    List<int>? daysOfWeek,
    int? startHour,
    int? startMinute,
    int? durationMinutes,
    int? intervalHours,
    DateTime? lastUpdated,
  }) {
    return WateringSchedule(
      enabled: enabled ?? this.enabled,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      intervalHours: intervalHours ?? this.intervalHours,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static WateringSchedule defaultSchedule() {
    return WateringSchedule();
  }

  String getScheduleSummary() {
    if (!enabled) return 'Disabled';
    
    final time = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
    final duration = '$durationMinutes min';
    
    String frequency;
    if (intervalHours > 0) {
      frequency = 'Every $intervalHours hours';
    } else {
      frequency = 'Once daily';
    }
    
    String days;
    if (daysOfWeek.length == 7) {
      days = 'Every day';
    } else if (daysOfWeek.length == 5 && !daysOfWeek.contains(6) && !daysOfWeek.contains(7)) {
      days = 'Weekdays';
    } else if (daysOfWeek.length == 2 && daysOfWeek.contains(6) && daysOfWeek.contains(7)) {
      days = 'Weekends';
    } else {
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      days = daysOfWeek.map((d) => dayNames[d - 1]).join(', ');
    }
    
    return '$time • $duration • $frequency • $days';
  }
}
