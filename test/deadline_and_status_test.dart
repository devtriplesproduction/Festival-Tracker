import 'package:festival_tracker/models/assignment.dart';
import 'package:festival_tracker/models/assignment_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Assignment deadlines', () {
    test('calculates working-backward deadlines from festival date', () {
      final festival = DateTime(2026, 11, 8); // Diwali
      final a = Assignment.create(
        id: '1',
        clientId: 'c1',
        festivalId: 'f1',
        festivalDate: festival,
      );

      expect(a.designDueDate, DateTime(2026, 11, 1));
      expect(a.qcDueDate, DateTime(2026, 11, 3));
      expect(a.readyDueDate, DateTime(2026, 11, 5));
      expect(a.sendDueDate, DateTime(2026, 11, 7));
    });

    test('current stage deadline follows status', () {
      final festival = DateTime(2026, 12, 25);
      var a = Assignment.create(
        id: '1',
        clientId: 'c1',
        festivalId: 'f1',
        festivalDate: festival,
      );

      expect(a.currentStageDeadline, a.designDueDate);

      a = a.copyWith(status: AssignmentStatus.qc);
      expect(a.currentStageDeadline, a.qcDueDate);

      a = a.copyWith(status: AssignmentStatus.ready);
      expect(a.currentStageDeadline, a.readyDueDate);

      a = a.copyWith(status: AssignmentStatus.sent);
      expect(a.currentStageDeadline, isNull);
      expect(a.isOverdue(), isFalse);
    });

    test('overdue when today is after stage deadline', () {
      final festival = DateTime(2026, 8, 15);
      final a = Assignment.create(
        id: '1',
        clientId: 'c1',
        festivalId: 'f1',
        festivalDate: festival,
        status: AssignmentStatus.design,
      );
      // Design due = Aug 8; check on Aug 10
      expect(a.isOverdue(DateTime(2026, 8, 10)), isTrue);
      expect(a.isOverdue(DateTime(2026, 8, 8)), isFalse);
      expect(a.isOverdue(DateTime(2026, 8, 7)), isFalse);
    });
  });

  group('AssignmentStatus', () {
    test('filled stages map correctly', () {
      expect(AssignmentStatus.notStarted.filledStages, 0);
      expect(AssignmentStatus.design.filledStages, 1);
      expect(AssignmentStatus.qc.filledStages, 2);
      expect(AssignmentStatus.ready.filledStages, 3);
      expect(AssignmentStatus.sent.filledStages, 4);
    });

    test('advance next status', () {
      expect(AssignmentStatus.notStarted.next, AssignmentStatus.design);
      expect(AssignmentStatus.design.next, AssignmentStatus.qc);
      expect(AssignmentStatus.sent.next, AssignmentStatus.sent);
    });

    test('fromValue parses firestore strings', () {
      expect(AssignmentStatus.fromValue('not_started'), AssignmentStatus.notStarted);
      expect(AssignmentStatus.fromValue('qc'), AssignmentStatus.qc);
      expect(AssignmentStatus.fromValue('unknown'), AssignmentStatus.notStarted);
    });
  });
}
