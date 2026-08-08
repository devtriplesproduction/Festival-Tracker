import 'assignment_status.dart';
import 'deadline_config.dart';

/// Client × festival pairing with auto-calculated pipeline deadlines.
class Assignment {
  const Assignment({
    required this.id,
    required this.clientId,
    required this.festivalId,
    required this.status,
    required this.designDueDate,
    required this.qcDueDate,
    required this.readyDueDate,
    required this.sendDueDate,
    this.posterUrl,
    this.posterFileName,
    this.posterMimeType,
    this.posterFileSize,
    this.posterFileHash,
    this.posterVersion,
    this.posterUploadedBy,
    this.posterUploadStatus,
    this.posterPreviewPath,
    this.posterUploadedAt,
    this.designerNotes,
    this.sentAt,
    this.sentByRole,
    this.createdAt,
  });

  final String id;
  final String clientId;
  final String festivalId;
  final AssignmentStatus status;
  final DateTime designDueDate;
  final DateTime qcDueDate;
  final DateTime readyDueDate;
  final DateTime sendDueDate;

  final String? posterUrl;
  final String? posterFileName;
  final String? posterMimeType;
  final int? posterFileSize;
  final String? posterFileHash;
  final int? posterVersion;
  final String? posterUploadedBy;
  final String? posterUploadStatus;

  /// Local file path or remote preview URL for the poster image.
  final String? posterPreviewPath;
  final DateTime? posterUploadedAt;
  final String? designerNotes;

  final DateTime? sentAt;
  final String? sentByRole;
  final DateTime? createdAt;

  bool get hasPoster =>
      (posterPreviewPath != null && posterPreviewPath!.isNotEmpty) ||
      (posterUrl != null && posterUrl!.isNotEmpty);

  /// Deadline for the stage the assignment is currently in.
  DateTime? get currentStageDeadline {
    switch (status) {
      case AssignmentStatus.notStarted:
      case AssignmentStatus.design:
        return designDueDate;
      case AssignmentStatus.qc:
        return qcDueDate;
      case AssignmentStatus.ready:
        return readyDueDate;
      case AssignmentStatus.sent:
        return null;
    }
  }

  /// Days past the current stage deadline (0 if on time / not overdue).
  int daysLate([DateTime? now]) {
    if (status.isTerminal) return 0;
    final deadline = currentStageDeadline;
    if (deadline == null) return 0;
    final today = _dateOnly(now ?? DateTime.now());
    final due = _dateOnly(deadline);
    if (!today.isAfter(due)) return 0;
    return today.difference(due).inDays;
  }

  /// True when today has passed the deadline for the current open stage.
  bool isOverdue([DateTime? now]) => daysLate(now) > 0;

  /// Nearest upcoming / relevant deadline for sorting.
  DateTime get sortDeadline {
    if (status.isTerminal) return sendDueDate;
    return currentStageDeadline ?? sendDueDate;
  }

  Assignment copyWith({
    String? id,
    String? clientId,
    String? festivalId,
    AssignmentStatus? status,
    DateTime? designDueDate,
    DateTime? qcDueDate,
    DateTime? readyDueDate,
    DateTime? sendDueDate,
    String? posterUrl,
    String? posterFileName,
    String? posterMimeType,
    int? posterFileSize,
    String? posterFileHash,
    int? posterVersion,
    String? posterUploadedBy,
    String? posterUploadStatus,
    String? posterPreviewPath,
    DateTime? posterUploadedAt,
    String? designerNotes,
    DateTime? sentAt,
    String? sentByRole,
    DateTime? createdAt,
    bool clearPoster = false,
    bool clearSent = false,
  }) {
    return Assignment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      festivalId: festivalId ?? this.festivalId,
      status: status ?? this.status,
      designDueDate: designDueDate ?? this.designDueDate,
      qcDueDate: qcDueDate ?? this.qcDueDate,
      readyDueDate: readyDueDate ?? this.readyDueDate,
      sendDueDate: sendDueDate ?? this.sendDueDate,
      posterUrl: clearPoster ? null : (posterUrl ?? this.posterUrl),
      posterFileName: clearPoster ? null : (posterFileName ?? this.posterFileName),
      posterMimeType: clearPoster ? null : (posterMimeType ?? this.posterMimeType),
      posterFileSize: clearPoster ? null : (posterFileSize ?? this.posterFileSize),
      posterFileHash: clearPoster ? null : (posterFileHash ?? this.posterFileHash),
      posterVersion: clearPoster ? null : (posterVersion ?? this.posterVersion),
      posterUploadedBy: clearPoster ? null : (posterUploadedBy ?? this.posterUploadedBy),
      posterUploadStatus: clearPoster ? null : (posterUploadStatus ?? this.posterUploadStatus),
      posterPreviewPath:
          clearPoster ? null : (posterPreviewPath ?? this.posterPreviewPath),
      posterUploadedAt:
          clearPoster ? null : (posterUploadedAt ?? this.posterUploadedAt),
      designerNotes: designerNotes ?? this.designerNotes,
      sentAt: clearSent ? null : (sentAt ?? this.sentAt),
      sentByRole: clearSent ? null : (sentByRole ?? this.sentByRole),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'festivalId': festivalId,
      'status': status.value,
      'designDueDate': designDueDate.toUtc(),
      'qcDueDate': qcDueDate.toUtc(),
      'readyDueDate': readyDueDate.toUtc(),
      'sendDueDate': sendDueDate.toUtc(),
      if (posterUrl != null) 'posterUrl': posterUrl,
      if (posterMimeType != null) 'posterMimeType': posterMimeType,
      if (posterFileSize != null) 'posterFileSize': posterFileSize,
      if (posterFileHash != null) 'posterFileHash': posterFileHash,
      if (posterVersion != null) 'posterVersion': posterVersion,
      if (posterUploadedBy != null) 'posterUploadedBy': posterUploadedBy,
      if (posterUploadStatus != null) 'posterUploadStatus': posterUploadStatus,
      if (posterPreviewPath != null) 'posterPreviewPath': posterPreviewPath,
      if (posterUploadedAt != null) 'posterUploadedAt': posterUploadedAt!.toUtc(),
      if (designerNotes != null) 'designerNotes': designerNotes,
      if (sentAt != null) 'sentAt': sentAt!.toUtc(),
      if (sentByRole != null) 'sentByRole': sentByRole,
      if (createdAt != null) 'createdAt': createdAt!.toUtc(),
    };
  }

  factory Assignment.fromMap(String id, Map<String, dynamic> map) {
    return Assignment(
      id: id,
      clientId: _idFrom(map['clientId']),
      festivalId: _idFrom(map['festivalId']),
      status: AssignmentStatus.fromValue(map['status'] as String?),
      designDueDate: _parseDate(map['designDueDate']),
      qcDueDate: _parseDate(map['qcDueDate']),
      readyDueDate: _parseDate(map['readyDueDate']),
      sendDueDate: _parseDate(map['sendDueDate']),
      posterUrl: map['posterUrl'] as String?,
      posterFileName: map['posterFileName'] as String?,
      posterMimeType: map['posterMimeType'] as String?,
      posterFileSize: map['posterFileSize'] as int?,
      posterFileHash: map['posterFileHash'] as String?,
      posterVersion: map['posterVersion'] as int?,
      posterUploadedBy: map['posterUploadedBy'] as String?,
      posterUploadStatus: map['posterUploadStatus'] as String?,
      posterPreviewPath: map['posterPreviewPath'] as String? ??
          map['posterPreviewUrl'] as String?,
      posterUploadedAt: map['posterUploadedAt'] != null
          ? _parseDate(map['posterUploadedAt'])
          : null,
      designerNotes: map['designerNotes'] as String?,
      sentAt: map['sentAt'] != null ? _parseDate(map['sentAt']) : null,
      sentByRole: map['sentByRole'] as String?,
      createdAt: map['createdAt'] != null ? _parseDate(map['createdAt']) : null,
    );
  }

  /// Working-backward deadlines from festival date using [offsets].
  static Assignment create({
    required String id,
    required String clientId,
    required String festivalId,
    required DateTime festivalDate,
    AssignmentStatus status = AssignmentStatus.notStarted,
    DeadlineOffsetConfig offsets = DeadlineOffsetConfig.defaults,
    DateTime? createdAt,
  }) {
    final day = _dateOnly(festivalDate);
    return Assignment(
      id: id,
      clientId: clientId,
      festivalId: festivalId,
      status: status,
      designDueDate: day.subtract(Duration(days: offsets.designDaysBefore)),
      qcDueDate: day.subtract(Duration(days: offsets.qcDaysBefore)),
      readyDueDate: day.subtract(Duration(days: offsets.readyDaysBefore)),
      sendDueDate: day.subtract(Duration(days: offsets.sendDaysBefore)),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Rebuild deadlines while preserving media / delivery metadata.
  Assignment withRecalculatedDeadlines(
    DateTime festivalDate, {
    DeadlineOffsetConfig offsets = DeadlineOffsetConfig.defaults,
  }) {
    final fresh = Assignment.create(
      id: id,
      clientId: clientId,
      festivalId: festivalId,
      festivalDate: festivalDate,
      status: status,
      offsets: offsets,
      createdAt: createdAt,
    );
    return fresh.copyWith(
      posterUrl: posterUrl,
      posterFileName: posterFileName,
      posterMimeType: posterMimeType,
      posterFileSize: posterFileSize,
      posterUploadedBy: posterUploadedBy,
      posterUploadStatus: posterUploadStatus,
      posterPreviewPath: posterPreviewPath,
      posterUploadedAt: posterUploadedAt,
      designerNotes: designerNotes,
      sentAt: sentAt,
      sentByRole: sentByRole,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _idFrom(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    try {
      final dynamic v = value;
      if (v.id is String) return v.id as String;
      if (v.path is String) {
        final path = v.path as String;
        return path.split('/').last;
      }
    } catch (_) {}
    return value.toString();
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    try {
      final dynamic v = value;
      if (v != null && v.toDate is Function) {
        return v.toDate() as DateTime;
      }
    } catch (_) {}
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Assignment && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
