import 'package:intl/intl.dart';

final _full = DateFormat('d MMM yyyy');
final _short = DateFormat('d MMM');
final _weekday = DateFormat('EEE, d MMM yyyy');
final _inr = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);
final _inrPrecise = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);
final _dateTimeShort = DateFormat('d MMM yyyy · h:mm a');

String formatDate(DateTime d) => _full.format(d);
String formatDateShort(DateTime d) => _short.format(d);
String formatDateWeekday(DateTime d) => _weekday.format(d);

/// Indian Rupee display for package prices.
String formatInr(num amount) {
  if (amount % 1 == 0) return _inr.format(amount);
  return _inrPrecise.format(amount);
}

String formatDateTimeShort(DateTime d) => _dateTimeShort.format(d);

String relativeDeadlineLabel(DateTime deadline, {DateTime? now}) {
  final today = DateTime(now?.year ?? DateTime.now().year,
      now?.month ?? DateTime.now().month, now?.day ?? DateTime.now().day);
  final day = DateTime(deadline.year, deadline.month, deadline.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Due today';
  if (diff == 1) return 'Due tomorrow';
  if (diff == -1) return '1 day overdue';
  if (diff < 0) return '${-diff} days overdue';
  return 'Due in $diff days';
}
