import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the central Admin Google Drive connection settings.
class DriveIntegration {
  const DriveIntegration({
    required this.connectedBy,
    required this.connectedAt,
    this.rootFolderId,
    this.refreshToken,
  });

  /// The Admin UID who connected the drive.
  final String connectedBy;

  /// When the drive was connected.
  final DateTime connectedAt;

  /// The ID of the root "Festival Posters" folder, if created.
  final String? rootFolderId;

  /// The OAuth refresh token (only accessible by Admin/Backend).
  final String? refreshToken;

  DriveIntegration copyWith({
    String? connectedBy,
    DateTime? connectedAt,
    String? rootFolderId,
    String? refreshToken,
  }) {
    return DriveIntegration(
      connectedBy: connectedBy ?? this.connectedBy,
      connectedAt: connectedAt ?? this.connectedAt,
      rootFolderId: rootFolderId ?? this.rootFolderId,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'connectedBy': connectedBy,
      'connectedAt': Timestamp.fromDate(connectedAt.toUtc()),
      if (rootFolderId != null) 'rootFolderId': rootFolderId,
      if (refreshToken != null) 'refreshToken': refreshToken,
    };
  }

  factory DriveIntegration.fromMap(Map<String, dynamic> map) {
    return DriveIntegration(
      connectedBy: map['connectedBy'] as String? ?? '',
      connectedAt: _parseDate(map['connectedAt']),
      rootFolderId: map['rootFolderId'] as String?,
      refreshToken: map['refreshToken'] as String?,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
