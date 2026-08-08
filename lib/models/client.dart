class Client {
  const Client({
    required this.id,
    required this.name,
    required this.whatsappNumber,
    this.companyName,
    this.notes,
    this.festivalIds = const [],
    this.packagePrice,
    this.createdAt,
  });

  final String id;
  final String name;

  /// Digits with country code preferred, e.g. 919876543210
  final String whatsappNumber;

  final String? companyName;
  final String? notes;

  /// Festivals this client is assigned to (local convenience; assignments are source of truth).
  final List<String> festivalIds;

  /// Client-specific yearly package price (₹). Differs per client.
  final double? packagePrice;

  /// Used for package period / renewal anniversary.
  final DateTime? createdAt;

  Client copyWith({
    String? id,
    String? name,
    String? whatsappNumber,
    String? companyName,
    String? notes,
    List<String>? festivalIds,
    double? packagePrice,
    DateTime? createdAt,
    bool clearCompanyName = false,
    bool clearNotes = false,
    bool clearPackagePrice = false,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      companyName: clearCompanyName ? null : (companyName ?? this.companyName),
      notes: clearNotes ? null : (notes ?? this.notes),
      festivalIds: festivalIds ?? this.festivalIds,
      packagePrice:
          clearPackagePrice ? null : (packagePrice ?? this.packagePrice),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'whatsappNumber': whatsappNumber,
      if (companyName != null && companyName!.isNotEmpty) 'companyName': companyName,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'festivalIds': festivalIds,
      if (packagePrice != null) 'packagePrice': packagePrice,
      if (createdAt != null) 'createdAt': createdAt!.toUtc(),
    };
  }

  factory Client.fromMap(String id, Map<String, dynamic> map) {
    final festivals = map['festivalIds'] ?? map['assignedFestivalIds'];
    return Client(
      id: id,
      name: map['name'] as String? ?? '',
      whatsappNumber: map['whatsappNumber'] as String? ?? '',
      companyName: map['companyName'] as String?,
      notes: map['notes'] as String?,
      festivalIds: festivals is List
          ? festivals.map((e) => e.toString()).toList()
          : const [],
      packagePrice: (map['packagePrice'] as num?)?.toDouble(),
      createdAt: map['createdAt'] != null ? _parseDate(map['createdAt']) : null,
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

  /// Digits only for wa.me deep links.
  String get whatsappDigits =>
      whatsappNumber.replaceAll(RegExp(r'[^\d]'), '');

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Client && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
