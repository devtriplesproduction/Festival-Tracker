/// Configurable stage offsets: days before the festival event date.
class DeadlineOffsetConfig {
  const DeadlineOffsetConfig({
    this.designDaysBefore = 3,
    this.qcDaysBefore = 2,
    this.readyDaysBefore = 1,
    this.sendDaysBefore = 0,
  });

  final int designDaysBefore;
  final int qcDaysBefore;
  final int readyDaysBefore;

  /// Spec: always 0 days before the event (Event Day) (still stored for clarity).
  final int sendDaysBefore;

  static const defaults = DeadlineOffsetConfig();

  DeadlineOffsetConfig copyWith({
    int? designDaysBefore,
    int? qcDaysBefore,
    int? readyDaysBefore,
    int? sendDaysBefore,
  }) {
    return DeadlineOffsetConfig(
      designDaysBefore: designDaysBefore ?? this.designDaysBefore,
      qcDaysBefore: qcDaysBefore ?? this.qcDaysBefore,
      readyDaysBefore: readyDaysBefore ?? this.readyDaysBefore,
      sendDaysBefore: sendDaysBefore ?? this.sendDaysBefore,
    );
  }

  Map<String, dynamic> toMap() => {
        'designDaysBefore': designDaysBefore,
        'qcDaysBefore': qcDaysBefore,
        'readyDaysBefore': readyDaysBefore,
        'sendDaysBefore': sendDaysBefore,
      };

  factory DeadlineOffsetConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return defaults;
    return DeadlineOffsetConfig(
      designDaysBefore: (map['designDaysBefore'] as num?)?.toInt() ?? 3,
      qcDaysBefore: (map['qcDaysBefore'] as num?)?.toInt() ?? 2,
      readyDaysBefore: (map['readyDaysBefore'] as num?)?.toInt() ?? 1,
      sendDaysBefore: (map['sendDaysBefore'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeadlineOffsetConfig &&
          designDaysBefore == other.designDaysBefore &&
          qcDaysBefore == other.qcDaysBefore &&
          readyDaysBefore == other.readyDaysBefore &&
          sendDaysBefore == other.sendDaysBefore;

  @override
  int get hashCode => Object.hash(
        designDaysBefore,
        qcDaysBefore,
        readyDaysBefore,
        sendDaysBefore,
      );
}
