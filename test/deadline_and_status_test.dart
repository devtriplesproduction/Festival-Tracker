import 'package:festival_tracker/models/assignment.dart';
import 'package:festival_tracker/models/assignment_status.dart';
import 'package:festival_tracker/services/whatsapp_service.dart';
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

      expect(a.designDueDate, DateTime(2026, 11, 5));
      expect(a.qcDueDate, DateTime(2026, 11, 6));
      expect(a.readyDueDate, DateTime(2026, 11, 7));
      expect(a.sendDueDate, DateTime(2026, 11, 8));
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
      // Design due = Aug 12; check on Aug 13
      expect(a.isOverdue(DateTime(2026, 8, 13)), isTrue);
      expect(a.isOverdue(DateTime(2026, 8, 12)), isFalse);
      expect(a.isOverdue(DateTime(2026, 8, 11)), isFalse);
    });
  });

  group('WhatsAppService', () {
    test('generateLink attaches design URL in message', () {
      final link = WhatsAppService.generateLink(
        phoneNumber: '+91 98765 43210',
        clientName: 'ABC Jewels',
        festivalName: 'Diwali',
        posterUrl: 'https://res.cloudinary.com/demo/image/upload/poster123.jpg',
        designerNotes: 'Special gold foil finish applied',
      );

      expect(link, contains('wa.me/919876543210'));
      final decoded = Uri.decodeComponent(link);
      expect(decoded, contains('ABC Jewels'));
      expect(decoded, contains('*Diwali*'));
      expect(decoded, contains('Attached Design'));
      expect(decoded, contains('https://res.cloudinary.com/demo/image/upload/poster123.jpg'));
      expect(decoded, contains('Special gold foil finish applied'));
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
