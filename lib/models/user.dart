class User {
  int? id;
  String name;
  String email;
  String password;
  DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

// User Profile model for Firebase
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? phoneNumber;
  final String? photoURL;
  final DateTime? createdAt;
  final DateTime? lastUpdated;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.phoneNumber,
    this.photoURL,
    this.createdAt,
    this.lastUpdated,
  });

  // From JSON (Firebase)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      photoURL: json['photoURL'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  // To JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'createdAt': createdAt?.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  // Create from Firebase Auth User
  factory UserProfile.fromFirebaseUser(dynamic firebaseUser) {
    return UserProfile(
      uid: firebaseUser.uid ?? '',
      displayName: firebaseUser.displayName ?? 'User',
      email: firebaseUser.email ?? '',
      phoneNumber: firebaseUser.phoneNumber,
      photoURL: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime,
      lastUpdated: DateTime.now(),
    );
  }

  // Copy with method
  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}