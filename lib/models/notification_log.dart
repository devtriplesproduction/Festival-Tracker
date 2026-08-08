/// In-app alert log (upload / send / overdue / package renewal). FCM can attach later.
enum NotificationType {
  uploadReminder('upload_reminder'),
  sendReminder('send_reminder'),
  overdueAlert('overdue_alert'),
  packageRenewal('package_renewal');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromValue(String? v) {
    return NotificationType.values.firstWhere(
      (t) => t.value == v,
      orElse: () => NotificationType.overdueAlert,
    );
  }

  String get label {
    switch (this) {
      case NotificationType.uploadReminder:
        return 'Upload reminder';
      case NotificationType.sendReminder:
        return 'Send reminder';
      case NotificationType.overdueAlert:
        return 'Overdue alert';
      case NotificationType.packageRenewal:
        return 'Package renewal';
    }
  }
}

class NotificationLog {
  const NotificationLog({
    required this.id,
    required this.assignmentId,
    required this.clientName,
    required this.festivalName,
    required this.type,
    required this.message,
    required this.sentAt,
    required this.recipientRole,
    this.read = false,
  });

  final String id;
  final String assignmentId;
  final String clientName;
  final String festivalName;
  final NotificationType type;
  final String message;
  final DateTime sentAt;

  /// Role string: admin | designer | manager | qc | all
  final String recipientRole;
  final bool read;

  NotificationLog copyWith({
    String? id,
    String? assignmentId,
    String? clientName,
    String? festivalName,
    NotificationType? type,
    String? message,
    DateTime? sentAt,
    String? recipientRole,
    bool? read,
  }) {
    return NotificationLog(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      clientName: clientName ?? this.clientName,
      festivalName: festivalName ?? this.festivalName,
      type: type ?? this.type,
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
      recipientRole: recipientRole ?? this.recipientRole,
      read: read ?? this.read,
    );
  }

  Map<String, dynamic> toMap() => {
        'assignmentId': assignmentId,
        'clientName': clientName,
        'festivalName': festivalName,
        'type': type.value,
        'message': message,
        'sentAt': sentAt.toUtc(),
        'recipientRole': recipientRole,
        'read': read,
      };

  factory NotificationLog.fromMap(String id, Map<String, dynamic> map) {
    return NotificationLog(
      id: id,
      assignmentId: map['assignmentId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      festivalName: map['festivalName'] as String? ?? '',
      type: NotificationType.fromValue(map['type'] as String?),
      message: map['message'] as String? ?? '',
      sentAt: _parseDate(map['sentAt']),
      recipientRole: map['recipientRole'] as String? ?? 'all',
      read: map['read'] as bool? ?? false,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    try {
      final dynamic v = value;
      if (v != null && v.toDate is Function) {
        return v.toDate() as DateTime;
      }
    } catch (_) {}
    return DateTime.now();
  }
}
