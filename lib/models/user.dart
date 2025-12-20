
// User Profile model for Firebase
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final DateTime? createdAt;
  final DateTime? lastUpdated;
  final bool notificationsEnabled;
  final bool autoWatering;
  final bool biometricEnabled;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.createdAt,
    this.lastUpdated,
    this.notificationsEnabled = true,
    this.autoWatering = true,
    this.biometricEnabled = false,
  });

  // From JSON (Firebase)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      autoWatering: json['autoWatering'] ?? true,
      biometricEnabled: json['biometricEnabled'] ?? false,
    );
  }

  // To JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
      'autoWatering': autoWatering,
      'biometricEnabled': biometricEnabled,
    };
  }

  // Create from Firebase Auth User
  factory UserProfile.fromFirebaseUser(dynamic firebaseUser) {
    return UserProfile(
      uid: firebaseUser.uid ?? '',
      displayName: firebaseUser.displayName ?? 'User',
      email: firebaseUser.email ?? '',
      createdAt: firebaseUser.metadata.creationTime,
      lastUpdated: DateTime.now(),
    );
  }

  // Copy with method
  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? notificationsEnabled,
    bool? autoWatering,
    bool? biometricEnabled,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoWatering: autoWatering ?? this.autoWatering,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}