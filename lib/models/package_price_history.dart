/// Append-only price change for a [ClientPackage].
class PackagePriceHistory {
  const PackagePriceHistory({
    required this.id,
    required this.packageId,
    required this.clientId,
    required this.year,
    required this.price,
    this.previousPrice,
    this.note,
    required this.changedAt,
    this.changedByUid,
    this.changedByRole,
  });

  final String id;
  final String packageId;
  final String clientId;
  final int year;

  /// New price after the change.
  final double price;

  /// Price before this change (null for initial set).
  final double? previousPrice;
  final String? note;
  final DateTime changedAt;
  final String? changedByUid;
  final String? changedByRole;

  Map<String, dynamic> toMap() => {
        'packageId': packageId,
        'clientId': clientId,
        'year': year,
        'price': price,
        if (previousPrice != null) 'previousPrice': previousPrice,
        if (note != null && note!.isNotEmpty) 'note': note,
        'changedAt': changedAt.toUtc(),
        if (changedByUid != null) 'changedByUid': changedByUid,
        if (changedByRole != null) 'changedByRole': changedByRole,
      };

  factory PackagePriceHistory.fromMap(String id, Map<String, dynamic> map) {
    return PackagePriceHistory(
      id: id,
      packageId: map['packageId']?.toString() ?? '',
      clientId: map['clientId']?.toString() ?? '',
      year: (map['year'] as num?)?.toInt() ?? DateTime.now().year,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      previousPrice: (map['previousPrice'] as num?)?.toDouble(),
      note: map['note'] as String?,
      changedAt: _parseDate(map['changedAt']),
      changedByUid: map['changedByUid'] as String?,
      changedByRole: map['changedByRole'] as String?,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PackagePriceHistory && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
