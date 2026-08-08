import 'assignment.dart';
import 'assignment_status.dart';
import 'festival.dart';

/// One row on a year-package delivery checklist (derived from assignments).
class PackageDeliveryItem {
  const PackageDeliveryItem({
    required this.assignmentId,
    required this.festivalId,
    required this.festivalName,
    required this.festivalDate,
    required this.status,
    this.sentAt,
  });

  final String assignmentId;
  final String festivalId;
  final String festivalName;
  final DateTime festivalDate;
  final AssignmentStatus status;
  final DateTime? sentAt;

  /// Auto-tick when poster pipeline reaches Sent.
  bool get delivered => status == AssignmentStatus.sent;
}

/// Progress for a client year package.
class PackageProgress {
  const PackageProgress(this.items);

  final List<PackageDeliveryItem> items;

  int get total => items.length;
  int get deliveredCount => items.where((i) => i.delivered).length;
  bool get isEmpty => items.isEmpty;
  bool get isComplete => total > 0 && deliveredCount == total;

  double get ratio => total == 0 ? 0 : deliveredCount / total;

  String get label => '$deliveredCount/$total';
}

/// Build checklist from live assignments + festivals (no stored ticks).
PackageProgress buildPackageProgress({
  required String clientId,
  required int year,
  required List<Assignment> assignments,
  required Map<String, Festival> festivalsById,
}) {
  final items = <PackageDeliveryItem>[];

  for (final a in assignments) {
    if (a.clientId != clientId) continue;
    final festival = festivalsById[a.festivalId];
    if (festival == null) continue;
    if (festival.date.year != year) continue;

    items.add(
      PackageDeliveryItem(
        assignmentId: a.id,
        festivalId: a.festivalId,
        festivalName: festival.name,
        festivalDate: festival.date,
        status: a.status,
        sentAt: a.sentAt,
      ),
    );
  }

  items.sort((a, b) => a.festivalDate.compareTo(b.festivalDate));
  return PackageProgress(items);
}
