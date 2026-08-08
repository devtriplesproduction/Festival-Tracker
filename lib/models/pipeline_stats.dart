class PipelineStats {
  const PipelineStats({
    required this.total,
    required this.notStarted,
    required this.inDesign,
    required this.inQc,
    required this.readyToSend,
    required this.sent,
    required this.overdueCount,
    this.monthPosters = 0,
    this.monthOverdue = 0,
    this.monthSent = 0,
  });

  final int total;
  final int notStarted;
  final int inDesign;
  final int inQc;
  final int readyToSend;
  final int sent;
  final int overdueCount;

  /// Current calendar-month KPIs (festival date in this month).
  final int monthPosters;
  final int monthOverdue;
  final int monthSent;
}
