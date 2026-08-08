import 'package:festival_tracker/models/assignment.dart';
import 'package:festival_tracker/models/assignment_status.dart';
import 'package:festival_tracker/models/festival.dart';
import 'package:festival_tracker/models/package_delivery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildPackageProgress', () {
    final festivals = {
      'f1': Festival(
        id: 'f1',
        name: 'Diwali',
        date: DateTime(2026, 11, 8),
      ),
      'f2': Festival(
        id: 'f2',
        name: 'Holi',
        date: DateTime(2026, 3, 3),
      ),
      'f3': Festival(
        id: 'f3',
        name: 'New Year',
        date: DateTime(2025, 1, 1),
      ),
    };

    test('includes only client assignments in package year', () {
      final assignments = [
        Assignment.create(
          id: 'a1',
          clientId: 'c1',
          festivalId: 'f1',
          festivalDate: festivals['f1']!.date,
        ).copyWith(status: AssignmentStatus.sent, sentAt: DateTime(2026, 11, 7)),
        Assignment.create(
          id: 'a2',
          clientId: 'c1',
          festivalId: 'f2',
          festivalDate: festivals['f2']!.date,
        ),
        Assignment.create(
          id: 'a3',
          clientId: 'c1',
          festivalId: 'f3',
          festivalDate: festivals['f3']!.date,
        ),
        Assignment.create(
          id: 'a4',
          clientId: 'c2',
          festivalId: 'f1',
          festivalDate: festivals['f1']!.date,
        ),
      ];

      final progress = buildPackageProgress(
        clientId: 'c1',
        year: 2026,
        assignments: assignments,
        festivalsById: festivals,
      );

      expect(progress.total, 2);
      expect(progress.deliveredCount, 1);
      expect(progress.label, '1/2');
      expect(progress.items.first.festivalName, 'Holi'); // sorted by date
      expect(progress.items.last.delivered, isTrue);
    });

    test('auto-tick only when status is sent', () {
      final assignments = [
        Assignment.create(
          id: 'a1',
          clientId: 'c1',
          festivalId: 'f1',
          festivalDate: festivals['f1']!.date,
          status: AssignmentStatus.ready,
        ),
      ];

      final progress = buildPackageProgress(
        clientId: 'c1',
        year: 2026,
        assignments: assignments,
        festivalsById: festivals,
      );

      expect(progress.deliveredCount, 0);
      expect(progress.items.single.delivered, isFalse);
    });

    test('empty when no matching festivals', () {
      final progress = buildPackageProgress(
        clientId: 'c1',
        year: 2027,
        assignments: const [],
        festivalsById: festivals,
      );
      expect(progress.isEmpty, isTrue);
      expect(progress.ratio, 0);
    });
  });
}
