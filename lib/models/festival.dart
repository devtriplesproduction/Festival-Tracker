class Festival {
  Festival({
    required this.id,
    required this.name,
    required DateTime date,
    this.category = 'Major Festival',
    this.description,
    this.isCustom = false,
  }) : date = dateOnly(date);

  final String id;
  final String name;

  /// Calendar day of the festival (local date-only, no time component).
  final DateTime date;
  final String category;
  final String? description;
  final bool isCustom;

  /// Normalize any DateTime to local midnight so day does not shift across timezones.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Festival copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? category,
    String? description,
    bool? isCustom,
    bool clearDescription = false,
  }) {
    return Festival(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      category: category ?? this.category,
      description: clearDescription ? null : (description ?? this.description),
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      // Store as local calendar day at noon UTC-safe local representation.
      'date': dateOnly(date),
      'category': category,
      if (description != null && description!.isNotEmpty) 'description': description,
      'isCustom': isCustom,
    };
  }

  factory Festival.fromMap(String id, Map<String, dynamic> map) {
    return Festival(
      id: id,
      name: map['name'] as String? ?? '',
      date: _parseDate(map['date']),
      category: map['category'] as String? ?? 'Major Festival',
      description: map['description'] as String?,
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return dateOnly(value.toLocal());
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return dateOnly(parsed.toLocal());
    }
    try {
      final dynamic v = value;
      if (v != null && v.toDate is Function) {
        return dateOnly((v.toDate() as DateTime).toLocal());
      }
    } catch (_) {}
    return dateOnly(DateTime.now());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Festival && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
