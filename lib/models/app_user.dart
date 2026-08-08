import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    required this.role,
    this.status,
    this.companyId,
    this.photoURL,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  final String id;
  final String username;
  final String displayName;
  final String email;
  final UserRole role;
  
  final String? status;
  final String? companyId;
  final String? photoURL;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  AppUser copyWith({
    String? id,
    String? username,
    String? displayName,
    String? email,
    UserRole? role,
    String? status,
    String? companyId,
    String? photoURL,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      photoURL: photoURL ?? this.photoURL,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'email': email,
        'role': role.value,
        if (status != null) 'status': status,
        if (companyId != null) 'companyId': companyId,
        if (photoURL != null) 'photoURL': photoURL,
        // ISO strings for SharedPreferences JSON; Firestore path uses Timestamps separately.
        if (lastLogin != null) 'lastLogin': lastLogin!.toUtc().toIso8601String(),
        if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
        'isActive': isActive,
      };

  factory AppUser.fromMap(Map<String, dynamic> map, {String? docId}) {
    return AppUser(
      id: docId ?? map['id'] as String? ?? '',
      username: map['username'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.fromValue(map['role'] as String?),
      status: map['status'] as String?,
      companyId: map['companyId'] as String?,
      photoURL: map['photoURL'] as String?,
      lastLogin: map['lastLogin'] != null ? _parseDate(map['lastLogin']) : null,
      createdAt: map['createdAt'] != null ? _parseDate(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? _parseDate(map['updatedAt']) : null,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.parse(value).toLocal();
    // Handles Firestore Timestamp but we can't import Timestamp here easily without coupling to Firebase.
    // Assuming standard String ISO format for cross-platform compatibility, or milliseconds.
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    try {
      // If it's a Timestamp, it has toDate()
      return value.toDate().toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Safe payload for UI
  Map<String, dynamic> toPublicMap() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'email': email,
        'role': role.value,
        'photoURL': photoURL,
        'isActive': isActive,
      };
}
