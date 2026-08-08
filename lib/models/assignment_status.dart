/// Pipeline status for a client × festival assignment.
enum AssignmentStatus {
  notStarted('not_started', 'Not started', 0),
  design('design', 'Design', 1),
  qc('qc', 'QC', 2),
  ready('ready', 'Ready', 3),
  sent('sent', 'Sent', 4);

  const AssignmentStatus(this.value, this.label, this.stepIndex);

  final String value;
  final String label;

  /// 0–4 stage index used by the step indicator.
  final int stepIndex;

  /// How many of the 4 visual stages are filled (Sent fills all 4).
  int get filledStages {
    switch (this) {
      case AssignmentStatus.notStarted:
        return 0;
      case AssignmentStatus.design:
        return 1;
      case AssignmentStatus.qc:
        return 2;
      case AssignmentStatus.ready:
        return 3;
      case AssignmentStatus.sent:
        return 4;
    }
  }

  static AssignmentStatus fromValue(String? value) {
    return AssignmentStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => AssignmentStatus.notStarted,
    );
  }

  AssignmentStatus get next {
    final i = index + 1;
    if (i >= AssignmentStatus.values.length) return this;
    return AssignmentStatus.values[i];
  }

  bool get isTerminal => this == AssignmentStatus.sent;
}
