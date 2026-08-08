/// Payment state for the current package period / upcoming renewal.
enum PackagePaymentStatus {
  unpaid('unpaid', 'Payment due'),
  paid('paid', 'Payment received');

  const PackagePaymentStatus(this.value, this.label);
  final String value;
  final String label;

  static PackagePaymentStatus fromValue(String? v) {
    return PackagePaymentStatus.values.firstWhere(
      (e) => e.value == v,
      orElse: () => PackagePaymentStatus.unpaid,
    );
  }
}

/// Operational package state.
enum PackageStatus {
  active('active', 'Active'),
  stopped('stopped', 'Stopped');

  const PackageStatus(this.value, this.label);
  final String value;
  final String label;

  static PackageStatus fromValue(String? v) {
    return PackageStatus.values.firstWhere(
      (e) => e.value == v,
      orElse: () => PackageStatus.active,
    );
  }
}

/// Commercial 1-year package for a client (renewal from client creation date).
class ClientPackage {
  const ClientPackage({
    required this.id,
    required this.clientId,
    required this.year,
    required this.price,
    this.currency = 'INR',
    this.note,
    this.createdAt,
    this.updatedAt,
    this.createdByUid,
    this.startDate,
    this.endDate,
    this.paymentStatus = PackagePaymentStatus.unpaid,
    this.packageStatus = PackageStatus.active,
    this.paymentReceivedAt,
    this.renewalNotifiedAt,
  });

  final String id;
  final String clientId;

  /// Calendar year label (e.g. 2026) — usually startDate.year.
  final int year;

  /// Current package price for this client.
  final double price;
  final String currency;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdByUid;

  /// Package period (defaults derived from client creation when missing).
  final DateTime? startDate;
  final DateTime? endDate;

  final PackagePaymentStatus paymentStatus;
  final PackageStatus packageStatus;
  final DateTime? paymentReceivedAt;

  /// Last time a 15-day renewal reminder was created (avoid spam).
  final DateTime? renewalNotifiedAt;

  bool get isActive => packageStatus == PackageStatus.active;
  bool get isPaid => paymentStatus == PackagePaymentStatus.paid;
  bool get isStopped => packageStatus == PackageStatus.stopped;

  /// Days until [endDate] (negative if past). Null if no end date.
  int? daysUntilRenewal([DateTime? now]) {
    final end = endDate;
    if (end == null) return null;
    final today = DateTime(now?.year ?? DateTime.now().year,
        now?.month ?? DateTime.now().month, now?.day ?? DateTime.now().day);
    final day = DateTime(end.year, end.month, end.day);
    return day.difference(today).inDays;
  }

  /// True when renewal is due within [windowDays] (inclusive) and still active.
  bool isRenewalDueSoon({int windowDays = 15, DateTime? now}) {
    if (!isActive) return false;
    final days = daysUntilRenewal(now);
    if (days == null) return false;
    return days >= 0 && days <= windowDays;
  }

  /// Past end date without renewal.
  bool isExpired([DateTime? now]) {
    final days = daysUntilRenewal(now);
    return days != null && days < 0;
  }

  ClientPackage copyWith({
    String? id,
    String? clientId,
    int? year,
    double? price,
    String? currency,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByUid,
    DateTime? startDate,
    DateTime? endDate,
    PackagePaymentStatus? paymentStatus,
    PackageStatus? packageStatus,
    DateTime? paymentReceivedAt,
    DateTime? renewalNotifiedAt,
    bool clearNote = false,
    bool clearPaymentReceivedAt = false,
    bool clearRenewalNotifiedAt = false,
  }) {
    return ClientPackage(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      year: year ?? this.year,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUid: createdByUid ?? this.createdByUid,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      packageStatus: packageStatus ?? this.packageStatus,
      paymentReceivedAt: clearPaymentReceivedAt
          ? null
          : (paymentReceivedAt ?? this.paymentReceivedAt),
      renewalNotifiedAt: clearRenewalNotifiedAt
          ? null
          : (renewalNotifiedAt ?? this.renewalNotifiedAt),
    );
  }

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'year': year,
        'price': price,
        'currency': currency,
        if (note != null && note!.isNotEmpty) 'note': note,
        if (createdAt != null) 'createdAt': createdAt!.toUtc(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toUtc(),
        if (createdByUid != null) 'createdByUid': createdByUid,
        if (startDate != null) 'startDate': startDate!.toUtc(),
        if (endDate != null) 'endDate': endDate!.toUtc(),
        'paymentStatus': paymentStatus.value,
        'packageStatus': packageStatus.value,
        if (paymentReceivedAt != null)
          'paymentReceivedAt': paymentReceivedAt!.toUtc(),
        if (renewalNotifiedAt != null)
          'renewalNotifiedAt': renewalNotifiedAt!.toUtc(),
      };

  factory ClientPackage.fromMap(String id, Map<String, dynamic> map) {
    return ClientPackage(
      id: id,
      clientId: map['clientId']?.toString() ?? '',
      year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'INR',
      note: map['note'] as String?,
      createdAt: map['createdAt'] != null ? _parseDate(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? _parseDate(map['updatedAt']) : null,
      createdByUid: map['createdByUid'] as String?,
      startDate: map['startDate'] != null ? _parseDate(map['startDate']) : null,
      endDate: map['endDate'] != null ? _parseDate(map['endDate']) : null,
      paymentStatus:
          PackagePaymentStatus.fromValue(map['paymentStatus'] as String?),
      packageStatus: PackageStatus.fromValue(map['packageStatus'] as String?),
      paymentReceivedAt: map['paymentReceivedAt'] != null
          ? _parseDate(map['paymentReceivedAt'])
          : null,
      renewalNotifiedAt: map['renewalNotifiedAt'] != null
          ? _parseDate(map['renewalNotifiedAt'])
          : null,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value.toLocal();
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    try {
      final dynamic v = value;
      if (v != null && v.toDate is Function) {
        return (v.toDate() as DateTime).toLocal();
      }
    } catch (_) {}
    return DateTime.now();
  }

  /// Build a new 1-year package from client creation (or [from]).
  static ClientPackage initialForClient({
    required String id,
    required String clientId,
    required double price,
    DateTime? from,
    String? createdByUid,
    PackagePaymentStatus paymentStatus = PackagePaymentStatus.paid,
  }) {
    final start = _dateOnly(from ?? DateTime.now());
    final end = DateTime(start.year + 1, start.month, start.day);
    final now = DateTime.now();
    return ClientPackage(
      id: id,
      clientId: clientId,
      year: start.year,
      price: price,
      startDate: start,
      endDate: end,
      paymentStatus: paymentStatus,
      packageStatus: PackageStatus.active,
      paymentReceivedAt:
          paymentStatus == PackagePaymentStatus.paid ? now : null,
      createdAt: now,
      updatedAt: now,
      createdByUid: createdByUid,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ClientPackage && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
