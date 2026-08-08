import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/festival_defaults.dart';
import '../../models/assignment.dart';
import '../../models/assignment_status.dart';
import '../../models/client.dart';
import '../../models/client_package.dart';
import '../../models/deadline_config.dart';
import '../../models/festival.dart';
import '../../models/notification_log.dart';
import '../../models/package_price_history.dart';
import 'app_repository.dart';

/// Firestore-backed repository matching the pipeline data model.
class FirestoreAppRepository implements AppRepository {
  FirestoreAppRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _festivals =>
      _db.collection('festivals');
  CollectionReference<Map<String, dynamic>> get _clients =>
      _db.collection('clients');
  CollectionReference<Map<String, dynamic>> get _assignments =>
      _db.collection('assignments');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _packages =>
      _db.collection('client_packages');
  CollectionReference<Map<String, dynamic>> get _priceHistory =>
      _db.collection('package_price_history');

  @override
  Stream<List<Festival>> watchFestivals() {
    return _festivals.orderBy('date').snapshots().map(
          (snap) => snap.docs
              .map((d) => Festival.fromMap(d.id, _normalize(d.data())))
              .toList(),
        );
  }

  @override
  Stream<List<Client>> watchClients() {
    return _clients.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((d) => Client.fromMap(d.id, _normalize(d.data())))
              .toList(),
        );
  }

  @override
  Stream<List<Assignment>> watchAssignments() {
    return _assignments.snapshots().map(
          (snap) => snap.docs
              .map((d) => Assignment.fromMap(d.id, _normalize(d.data())))
              .toList(),
        );
  }

  @override
  Stream<List<NotificationLog>> watchNotifications() {
    return _notifications
        .orderBy('sentAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => NotificationLog.fromMap(d.id, _normalize(d.data())))
              .toList(),
        );
  }

  @override
  Stream<List<ClientPackage>> watchClientPackages() {
    return _packages.snapshots().map(
          (snap) {
            final list = snap.docs
                .map((d) => ClientPackage.fromMap(d.id, _normalize(d.data())))
                .toList()
              ..sort((a, b) {
                final y = b.year.compareTo(a.year);
                if (y != 0) return y;
                return a.clientId.compareTo(b.clientId);
              });
            return list;
          },
        );
  }

  @override
  Stream<List<PackagePriceHistory>> watchPackagePriceHistory() {
    return _priceHistory
        .orderBy('changedAt', descending: true)
        .limit(500)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) =>
                    PackagePriceHistory.fromMap(d.id, _normalize(d.data())),
              )
              .toList(),
        );
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> data) {
    final out = Map<String, dynamic>.from(data);
    for (final key in out.keys.toList()) {
      final v = out[key];
      if (v is Timestamp) {
        out[key] = v.toDate();
      } else if (v is DocumentReference) {
        out[key] = v.id;
      }
    }
    return out;
  }

  Map<String, dynamic> _festivalWrite(Festival f) {
    final day = Festival.dateOnly(f.date);
    return {
      'name': f.name,
      // Local calendar day at noon reduces timezone day-shift when stored as Timestamp.
      'date': Timestamp.fromDate(DateTime(day.year, day.month, day.day, 12)),
      'category': f.category,
      if (f.description != null) 'description': f.description,
      'isCustom': f.isCustom,
    };
  }

  Map<String, dynamic> _clientWrite(Client c) => {
        'name': c.name,
        'whatsappNumber': c.whatsappNumber,
        if (c.companyName != null) 'companyName': c.companyName,
        if (c.notes != null) 'notes': c.notes,
        'festivalIds': c.festivalIds,
        if (c.packagePrice != null) 'packagePrice': c.packagePrice,
        if (c.createdAt != null) 'createdAt': Timestamp.fromDate(c.createdAt!),
      };

  Map<String, dynamic> _assignmentWrite(Assignment a) => {
        'clientId': _clients.doc(a.clientId),
        'festivalId': _festivals.doc(a.festivalId),
        'status': a.status.value,
        'designDueDate': Timestamp.fromDate(a.designDueDate),
        'qcDueDate': Timestamp.fromDate(a.qcDueDate),
        'readyDueDate': Timestamp.fromDate(a.readyDueDate),
        'sendDueDate': Timestamp.fromDate(a.sendDueDate),
        
        if (a.posterUrl != null) 'posterUrl': a.posterUrl,
        if (a.posterPreviewPath != null) 'posterPreviewPath': a.posterPreviewPath,
        if (a.posterUploadedAt != null)
          'posterUploadedAt': Timestamp.fromDate(a.posterUploadedAt!),
        if (a.designerNotes != null) 'designerNotes': a.designerNotes,
        if (a.sentAt != null) 'sentAt': Timestamp.fromDate(a.sentAt!),
        if (a.sentByRole != null) 'sentByRole': a.sentByRole,
        if (a.createdAt != null) 'createdAt': Timestamp.fromDate(a.createdAt!),
      };

  Map<String, dynamic> _notificationWrite(NotificationLog n) => {
        'assignmentId': n.assignmentId,
        'clientName': n.clientName,
        'festivalName': n.festivalName,
        'type': n.type.value,
        'message': n.message,
        'sentAt': Timestamp.fromDate(n.sentAt),
        'recipientRole': n.recipientRole,
        'read': n.read,
      };

  @override
  Future<DeadlineOffsetConfig> loadDeadlineConfig() async {
    final snap = await _db.collection('_meta').doc('deadline_config').get();
    if (!snap.exists) return DeadlineOffsetConfig.defaults;
    return DeadlineOffsetConfig.fromMap(snap.data());
  }

  @override
  Future<void> saveDeadlineConfig(DeadlineOffsetConfig config) async {
    await _db.collection('_meta').doc('deadline_config').set(config.toMap());
  }

  @override
  Future<void> upsertFestival(Festival festival) async {
    await _festivals
        .doc(festival.id)
        .set(_festivalWrite(festival), SetOptions(merge: true));

    final offsets = await loadDeadlineConfig();
    final snap = await _assignments
        .where('festivalId', isEqualTo: _festivals.doc(festival.id))
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      final existing = Assignment.fromMap(doc.id, _normalize(doc.data()));
      final updated = existing.withRecalculatedDeadlines(
        festival.date,
        offsets: offsets,
      );
      batch.set(doc.reference, _assignmentWrite(updated), SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<void> deleteFestival(String id) async {
    final batch = _db.batch();
    batch.delete(_festivals.doc(id));
    final assignSnap =
        await _assignments.where('festivalId', isEqualTo: _festivals.doc(id)).get();
    for (final d in assignSnap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> upsertClient(Client client) async {
    await _clients.doc(client.id).set(_clientWrite(client), SetOptions(merge: true));
  }

  @override
  Future<void> deleteClient(String id) async {
    final batch = _db.batch();
    batch.delete(_clients.doc(id));
    final assignSnap =
        await _assignments.where('clientId', isEqualTo: _clients.doc(id)).get();
    for (final d in assignSnap.docs) {
      batch.delete(d.reference);
    }
    final packageSnap =
        await _packages.where('clientId', isEqualTo: id).get();
    for (final d in packageSnap.docs) {
      batch.delete(d.reference);
      final hist =
          await _priceHistory.where('packageId', isEqualTo: d.id).get();
      for (final h in hist.docs) {
        batch.delete(h.reference);
      }
    }
    await batch.commit();
  }

  @override
  Future<void> upsertAssignment(Assignment assignment) async {
    await _assignments
        .doc(assignment.id)
        .set(_assignmentWrite(assignment), SetOptions(merge: true));
  }

  @override
  Future<void> deleteAssignment(String id) async {
    await _assignments.doc(id).delete();
  }

  @override
  Future<void> setAssignmentStatus(
    String id,
    AssignmentStatus status, {
    DateTime? sentAt,
    String? sentByRole,
  }) async {
    final data = <String, dynamic>{'status': status.value};
    if (status == AssignmentStatus.sent) {
      data['sentAt'] = Timestamp.fromDate(sentAt ?? DateTime.now());
      if (sentByRole != null) data['sentByRole'] = sentByRole;
    }
    await _assignments.doc(id).update(data);
  }

  @override
  Future<void> upsertNotification(NotificationLog log) async {
    await _notifications.doc(log.id).set(_notificationWrite(log), SetOptions(merge: true));
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await _notifications.doc(id).update({'read': true});
  }

  @override
  Future<void> clearNotifications() async {
    final snap = await _notifications.limit(200).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> seedDefaultFestivalsIfNeeded(int year) async {
    final meta = _db.collection('_meta').doc('seed');
    final metaSnap = await meta.get();
    final seededYear = metaSnap.data()?['year'] as int?;
    final existing = await _festivals.limit(1).get();
    if (seededYear == year && existing.docs.isNotEmpty) return;

    if (existing.docs.isEmpty) {
      final batch = _db.batch();
      for (final def in kDefaultFestivals) {
        final id = _uuid.v4();
        batch.set(
          _festivals.doc(id),
          {
            'name': def.name,
            'date': Timestamp.fromDate(def.dateForYear(year)),
            'category': def.category,
            'isCustom': false,
          },
        );
      }
      await batch.commit();
    }
    await meta.set({'year': year}, SetOptions(merge: true));
  }

  @override
  Future<void> syncClientAssignments({
    required String clientId,
    required List<String> festivalIds,
    required Map<String, Festival> festivalsById,
    DeadlineOffsetConfig offsets = DeadlineOffsetConfig.defaults,
  }) async {
    final desired = festivalIds.toSet();
    final snap =
        await _assignments.where('clientId', isEqualTo: _clients.doc(clientId)).get();
    final existing = snap.docs
        .map((d) => Assignment.fromMap(d.id, _normalize(d.data())))
        .toList();

    final batch = _db.batch();

    for (final a in existing) {
      if (!desired.contains(a.festivalId)) {
        batch.delete(_assignments.doc(a.id));
      }
    }

    final existingFestivalIds = existing.map((a) => a.festivalId).toSet();
    for (final fid in desired) {
      if (existingFestivalIds.contains(fid)) continue;
      final festival = festivalsById[fid];
      if (festival == null) continue;
      final id = _uuid.v4();
      final assignment = Assignment.create(
        id: id,
        clientId: clientId,
        festivalId: fid,
        festivalDate: festival.date,
        offsets: offsets,
      );
      batch.set(_assignments.doc(id), _assignmentWrite(assignment));
    }

    await batch.commit();
  }

  @override
  Future<void> recalculateAllDeadlines({
    required Map<String, Festival> festivalsById,
    required DeadlineOffsetConfig offsets,
  }) async {
    await saveDeadlineConfig(offsets);
    final snap = await _assignments.get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      final a = Assignment.fromMap(doc.id, _normalize(doc.data()));
      final fest = festivalsById[a.festivalId];
      if (fest == null) continue;
      final updated = a.withRecalculatedDeadlines(fest.date, offsets: offsets);
      batch.set(doc.reference, _assignmentWrite(updated), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Map<String, dynamic> _packageWrite(ClientPackage p) => {
        'clientId': p.clientId,
        'year': p.year,
        'price': p.price,
        'currency': p.currency,
        if (p.note != null) 'note': p.note,
        if (p.createdAt != null) 'createdAt': Timestamp.fromDate(p.createdAt!),
        if (p.updatedAt != null) 'updatedAt': Timestamp.fromDate(p.updatedAt!),
        if (p.createdByUid != null) 'createdByUid': p.createdByUid,
        if (p.startDate != null) 'startDate': Timestamp.fromDate(p.startDate!),
        if (p.endDate != null) 'endDate': Timestamp.fromDate(p.endDate!),
        'paymentStatus': p.paymentStatus.value,
        'packageStatus': p.packageStatus.value,
        if (p.paymentReceivedAt != null)
          'paymentReceivedAt': Timestamp.fromDate(p.paymentReceivedAt!),
        if (p.renewalNotifiedAt != null)
          'renewalNotifiedAt': Timestamp.fromDate(p.renewalNotifiedAt!),
      };

  Map<String, dynamic> _priceHistoryWrite(PackagePriceHistory h) => {
        'packageId': h.packageId,
        'clientId': h.clientId,
        'year': h.year,
        'price': h.price,
        if (h.previousPrice != null) 'previousPrice': h.previousPrice,
        if (h.note != null) 'note': h.note,
        'changedAt': Timestamp.fromDate(h.changedAt),
        if (h.changedByUid != null) 'changedByUid': h.changedByUid,
        if (h.changedByRole != null) 'changedByRole': h.changedByRole,
      };

  @override
  Future<void> upsertClientPackage(ClientPackage package) async {
    await _packages
        .doc(package.id)
        .set(_packageWrite(package), SetOptions(merge: true));
  }

  @override
  Future<void> deleteClientPackage(String id) async {
    final batch = _db.batch();
    batch.delete(_packages.doc(id));
    final hist =
        await _priceHistory.where('packageId', isEqualTo: id).get();
    for (final d in hist.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> addPackagePriceHistory(PackagePriceHistory entry) async {
    await _priceHistory.doc(entry.id).set(_priceHistoryWrite(entry));
  }

  @override
  Future<int> createYearPackagesForAllClients({
    required int year,
    required double price,
    String currency = 'INR',
    String? createdByUid,
    String? createdByRole,
  }) async {
    final clientsSnap = await _clients.get();
    final existingSnap =
        await _packages.where('year', isEqualTo: year).get();
    final existingClientIds = existingSnap.docs
        .map((d) => d.data()['clientId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final now = DateTime.now();
    var created = 0;
    // Firestore batches max 500 ops; each package = 2 writes.
    var batch = _db.batch();
    var ops = 0;

    Future<void> commitIfNeeded({bool force = false}) async {
      if (ops == 0) return;
      if (!force && ops < 400) return;
      await batch.commit();
      batch = _db.batch();
      ops = 0;
    }

    for (final doc in clientsSnap.docs) {
      if (existingClientIds.contains(doc.id)) continue;

      final data = _normalize(doc.data());
      final client = Client.fromMap(doc.id, data);
      final clientPrice = client.packagePrice ?? price;
      final start = client.createdAt != null
          ? DateTime(year, client.createdAt!.month, client.createdAt!.day)
          : DateTime(year, now.month, now.day);
      final end = DateTime(start.year + 1, start.month, start.day);

      final packageId = _uuid.v4();
      final historyId = _uuid.v4();
      final package = ClientPackage(
        id: packageId,
        clientId: doc.id,
        year: year,
        price: clientPrice,
        currency: currency,
        startDate: start,
        endDate: end,
        paymentStatus: PackagePaymentStatus.paid,
        packageStatus: PackageStatus.active,
        paymentReceivedAt: now,
        createdAt: now,
        updatedAt: now,
        createdByUid: createdByUid,
      );
      final history = PackagePriceHistory(
        id: historyId,
        packageId: packageId,
        clientId: doc.id,
        year: year,
        price: clientPrice,
        previousPrice: null,
        note: 'Initial package price',
        changedAt: now,
        changedByUid: createdByUid,
        changedByRole: createdByRole,
      );

      batch.set(_packages.doc(packageId), _packageWrite(package));
      batch.set(_priceHistory.doc(historyId), _priceHistoryWrite(history));
      ops += 2;
      created++;
      await commitIfNeeded();
    }

    await commitIfNeeded(force: true);
    return created;
  }

  @override
  void dispose() {}
}
