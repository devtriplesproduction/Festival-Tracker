import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
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

class PaginatedResult<T> {
  final List<T> items;
  final Object? lastCursor;

  const PaginatedResult({required this.items, this.lastCursor});
}

/// Abstract data layer so Firestore can replace local storage without UI rework.
abstract class AppRepository {
  Stream<List<Festival>> watchFestivals();
  Stream<List<Client>> watchClients();
  Stream<List<Assignment>> watchAssignments();
  Stream<List<NotificationLog>> watchNotifications();
  Stream<List<ClientPackage>> watchClientPackages();
  Stream<List<PackagePriceHistory>> watchPackagePriceHistory();

  Future<PaginatedResult<Festival>> fetchFestivalsPage({int limit = 20, Object? startAfter});
  Future<PaginatedResult<Client>> fetchClientsPage({int limit = 20, Object? startAfter});
  Future<PaginatedResult<Assignment>> fetchAssignmentsPage({int limit = 20, Object? startAfter, String? search, String? statusFilter, String? festivalFilter});
  Future<PaginatedResult<NotificationLog>> fetchNotificationsPage({int limit = 20, Object? startAfter});
  Future<PaginatedResult<ClientPackage>> fetchClientPackagesPage({int limit = 20, Object? startAfter});
  Future<PaginatedResult<PackagePriceHistory>> fetchPackagePriceHistoryPage({int limit = 20, Object? startAfter});

  Future<DeadlineOffsetConfig> loadDeadlineConfig();
  Future<void> saveDeadlineConfig(DeadlineOffsetConfig config);

  Future<void> upsertFestival(Festival festival);
  Future<void> deleteFestival(String id);

  Future<void> upsertClient(Client client);
  Future<void> deleteClient(String id);

  Future<void> upsertAssignment(Assignment assignment);
  Future<void> deleteAssignment(String id);
  Future<void> setAssignmentStatus(
    String id,
    AssignmentStatus status, {
    DateTime? sentAt,
    String? sentByRole,
  });

  Future<void> upsertNotification(NotificationLog log);
  Future<void> markNotificationRead(String id, String userId);
  Future<void> deleteNotification(String id);
  Future<void> deleteOldNotifications(DateTime beforeDate);
  Future<void> clearNotifications();

  Future<void> upsertClientPackage(ClientPackage package);
  Future<void> deleteClientPackage(String id);
  Future<void> addPackagePriceHistory(PackagePriceHistory entry);

  /// Create a year package for every client missing that year. Returns created count.
  Future<int> createYearPackagesForAllClients({
    required int year,
    required double price,
    String currency = 'INR',
    String? createdByUid,
    String? createdByRole,
  });

  /// Ensure default festivals exist for [year] (idempotent).
  Future<void> seedDefaultFestivalsIfNeeded(int year);

  /// Sync assignments when client festival membership changes.
  Future<List<Assignment>> syncClientAssignments({
    required String clientId,
    required List<String> festivalIds,
    required Map<String, Festival> festivalsById,
    DeadlineOffsetConfig offsets = DeadlineOffsetConfig.defaults,
  });

  /// Recalculate all assignment deadlines using [offsets].
  Future<void> recalculateAllDeadlines({
    required Map<String, Festival> festivalsById,
    required DeadlineOffsetConfig offsets,
  });

  void dispose();
}

/// Local SharedPreferences-backed store.
class LocalAppRepository implements AppRepository {
  LocalAppRepository(this._prefs);

  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  final _festivalsCtrl = StreamController<List<Festival>>.broadcast();
  final _clientsCtrl = StreamController<List<Client>>.broadcast();
  final _assignmentsCtrl = StreamController<List<Assignment>>.broadcast();
  final _notificationsCtrl = StreamController<List<NotificationLog>>.broadcast();
  final _packagesCtrl = StreamController<List<ClientPackage>>.broadcast();
  final _priceHistoryCtrl = StreamController<List<PackagePriceHistory>>.broadcast();

  static const _kFestivals = 'festivals_v2';
  static const _kClients = 'clients_v2';
  static const _kAssignments = 'assignments_v2';
  static const _kNotifications = 'notifications_v1';
  static const _kClientPackages = 'client_packages_v1';
  static const _kPackagePriceHistory = 'package_price_history_v1';
  static const _kDeadlineConfig = 'deadline_config_v1';
  static const _kSeededYear = 'seeded_year_v1';

  // Migrate from v1 keys if present
  static const _kFestivalsV1 = 'festivals_v1';
  static const _kClientsV1 = 'clients_v1';
  static const _kAssignmentsV1 = 'assignments_v1';

  List<Festival> _festivals = [];
  List<Client> _clients = [];
  List<Assignment> _assignments = [];
  List<NotificationLog> _notifications = [];
  List<ClientPackage> _packages = [];
  List<PackagePriceHistory> _priceHistory = [];
  DeadlineOffsetConfig _deadlineConfig = DeadlineOffsetConfig.defaults;

  Future<void> init() async {
    _festivals = _readList(_kFestivals, Festival.fromMap);
    if (_festivals.isEmpty) {
      _festivals = _readList(_kFestivalsV1, Festival.fromMap);
    }
    _clients = _readList(_kClients, Client.fromMap);
    if (_clients.isEmpty) {
      _clients = _readList(_kClientsV1, Client.fromMap);
    }
    _assignments = _readList(_kAssignments, Assignment.fromMap);
    if (_assignments.isEmpty) {
      _assignments = _readList(_kAssignmentsV1, Assignment.fromMap);
    }
    _notifications = _readList(_kNotifications, NotificationLog.fromMap);
    _packages = _readList(_kClientPackages, ClientPackage.fromMap);
    _priceHistory = _readList(_kPackagePriceHistory, PackagePriceHistory.fromMap);
    _deadlineConfig = await loadDeadlineConfig();
    _emitAll();
  }

  List<T> _readList<T>(
    String key,
    T Function(String id, Map<String, dynamic> map) fromMap,
  ) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final id = m.remove('id') as String? ?? const Uuid().v4();
      for (final k in m.keys.toList()) {
        final v = m[k];
        if (v is String && _looksLikeIsoDate(v)) {
          try {
            m[k] = DateTime.parse(v);
          } catch (_) {}
        }
      }
      return fromMap(id, m);
    }).toList();
  }

  bool _looksLikeIsoDate(String v) =>
      v.length >= 10 &&
      v.contains('-') &&
      (v.contains('T') || RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(v));

  String _encodeDate(DateTime d) => d.toIso8601String();

  Future<void> _persistFestivals() async {
    final encoded = jsonEncode(_festivals.map((f) {
      final day = Festival.dateOnly(f.date);
      return {
        'id': f.id,
        'name': f.name,
        // Date-only ISO (yyyy-MM-dd) avoids timezone day shifts on reload.
        'date':
            '${day.year.toString().padLeft(4, '0')}-'
            '${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}',
        'category': f.category,
        if (f.description != null) 'description': f.description,
        'isCustom': f.isCustom,
      };
    }).toList());
    await _prefs.setString(_kFestivals, encoded);
    _festivalsCtrl.add(List.unmodifiable(_festivals));
  }

  Future<void> _persistClients() async {
    final encoded = jsonEncode(_clients.map((c) {
      return {
        'id': c.id,
        'name': c.name,
        'whatsappNumber': c.whatsappNumber,
        if (c.companyName != null) 'companyName': c.companyName,
        if (c.notes != null) 'notes': c.notes,
        'festivalIds': c.festivalIds,
        if (c.packagePrice != null) 'packagePrice': c.packagePrice,
        if (c.createdAt != null) 'createdAt': _encodeDate(c.createdAt!),
      };
    }).toList());
    await _prefs.setString(_kClients, encoded);
    _clientsCtrl.add(List.unmodifiable(_clients));
  }

  Future<void> _persistAssignments() async {
    final encoded = jsonEncode(_assignments.map((a) {
      return {
        'id': a.id,
        'clientId': a.clientId,
        'festivalId': a.festivalId,
        'status': a.status.value,
        'designDueDate': _encodeDate(a.designDueDate),
        'qcDueDate': _encodeDate(a.qcDueDate),
        'readyDueDate': _encodeDate(a.readyDueDate),
        'sendDueDate': _encodeDate(a.sendDueDate),
        
        if (a.posterUrl != null) 'posterUrl': a.posterUrl,
        if (a.posterPreviewPath != null) 'posterPreviewPath': a.posterPreviewPath,
        if (a.posterUploadedAt != null)
          'posterUploadedAt': _encodeDate(a.posterUploadedAt!),
        if (a.designerNotes != null) 'designerNotes': a.designerNotes,
        if (a.sentAt != null) 'sentAt': _encodeDate(a.sentAt!),
        if (a.sentByRole != null) 'sentByRole': a.sentByRole,
        if (a.createdAt != null) 'createdAt': _encodeDate(a.createdAt!),
      };
    }).toList());
    await _prefs.setString(_kAssignments, encoded);
    _assignmentsCtrl.add(List.unmodifiable(_assignments));
  }

  Future<void> _persistNotifications() async {
    final encoded = jsonEncode(_notifications.map((n) {
      return {
        'id': n.id,
        'assignmentId': n.assignmentId,
        'clientName': n.clientName,
        'festivalName': n.festivalName,
        'type': n.type.value,
        'message': n.message,
        'sentAt': _encodeDate(n.sentAt),
        'recipientRole': n.recipientRole,
        'readBy': n.readBy,
      };
    }).toList());
    await _prefs.setString(_kNotifications, encoded);
    _notificationsCtrl.add(List.unmodifiable(_notifications));
  }

  Future<void> _persistPackages() async {
    final encoded = jsonEncode(_packages.map((p) {
      return {
        'id': p.id,
        'clientId': p.clientId,
        'year': p.year,
        'price': p.price,
        'currency': p.currency,
        if (p.note != null) 'note': p.note,
        if (p.createdAt != null) 'createdAt': _encodeDate(p.createdAt!),
        if (p.updatedAt != null) 'updatedAt': _encodeDate(p.updatedAt!),
        if (p.createdByUid != null) 'createdByUid': p.createdByUid,
        if (p.startDate != null) 'startDate': _encodeDate(p.startDate!),
        if (p.endDate != null) 'endDate': _encodeDate(p.endDate!),
        'paymentStatus': p.paymentStatus.value,
        'packageStatus': p.packageStatus.value,
        if (p.paymentReceivedAt != null)
          'paymentReceivedAt': _encodeDate(p.paymentReceivedAt!),
        if (p.renewalNotifiedAt != null)
          'renewalNotifiedAt': _encodeDate(p.renewalNotifiedAt!),
      };
    }).toList());
    await _prefs.setString(_kClientPackages, encoded);
    _packagesCtrl.add(List.unmodifiable(_packages));
  }

  Future<void> _persistPriceHistory() async {
    final encoded = jsonEncode(_priceHistory.map((h) {
      return {
        'id': h.id,
        'packageId': h.packageId,
        'clientId': h.clientId,
        'year': h.year,
        'price': h.price,
        if (h.previousPrice != null) 'previousPrice': h.previousPrice,
        if (h.note != null) 'note': h.note,
        'changedAt': _encodeDate(h.changedAt),
        if (h.changedByUid != null) 'changedByUid': h.changedByUid,
        if (h.changedByRole != null) 'changedByRole': h.changedByRole,
      };
    }).toList());
    await _prefs.setString(_kPackagePriceHistory, encoded);
    _priceHistoryCtrl.add(List.unmodifiable(_priceHistory));
  }

  void _emitAll() {
    _festivalsCtrl.add(List.unmodifiable(_festivals));
    _clientsCtrl.add(List.unmodifiable(_clients));
    _assignmentsCtrl.add(List.unmodifiable(_assignments));
    _notificationsCtrl.add(List.unmodifiable(_notifications));
    _packagesCtrl.add(List.unmodifiable(_packages));
    _priceHistoryCtrl.add(List.unmodifiable(_priceHistory));
  }

  @override
  Stream<List<Festival>> watchFestivals() async* {
    yield List.unmodifiable(_festivals);
    yield* _festivalsCtrl.stream;
  }

  @override
  Stream<List<Client>> watchClients() async* {
    yield List.unmodifiable(_clients);
    yield* _clientsCtrl.stream;
  }

  @override
  Stream<List<Assignment>> watchAssignments() async* {
    yield List.unmodifiable(_assignments);
    yield* _assignmentsCtrl.stream;
  }

  @override
  Stream<List<ClientPackage>> watchClientPackages() async* {
    yield List.unmodifiable(_packages);
    yield* _packagesCtrl.stream;
  }

  @override
  Stream<List<PackagePriceHistory>> watchPackagePriceHistory() async* {
    yield List.unmodifiable(_priceHistory);
    yield* _priceHistoryCtrl.stream;
  }

  @override
  Stream<List<NotificationLog>> watchNotifications() async* {
    yield List.unmodifiable(_notifications);
    yield* _notificationsCtrl.stream;
  }

  @override
  Future<PaginatedResult<Festival>> fetchFestivalsPage({int limit = 20, Object? startAfter}) async {
    final startIndex = startAfter == null ? 0 : (startAfter as int);
    final endIndex = (startIndex + limit).clamp(0, _festivals.length);
    final items = _festivals.sublist(startIndex, endIndex);
    return PaginatedResult(items: items, lastCursor: endIndex < _festivals.length ? endIndex : null);
  }

  @override
  Future<PaginatedResult<Client>> fetchClientsPage({int limit = 20, Object? startAfter}) async {
    final startIndex = startAfter == null ? 0 : (startAfter as int);
    final endIndex = (startIndex + limit).clamp(0, _clients.length);
    final items = _clients.sublist(startIndex, endIndex);
    return PaginatedResult(items: items, lastCursor: endIndex < _clients.length ? endIndex : null);
  }

  @override
  Future<PaginatedResult<Assignment>> fetchAssignmentsPage({int limit = 20, Object? startAfter, String? search, String? statusFilter, String? festivalFilter}) async {
    // Local filtering
    var filtered = _assignments;
    // Real implementation would filter here based on args
    final startIndex = startAfter == null ? 0 : (startAfter as int);
    final endIndex = (startIndex + limit).clamp(0, filtered.length);
    final items = filtered.sublist(startIndex, endIndex);
    return PaginatedResult(items: items, lastCursor: endIndex < filtered.length ? endIndex : null);
  }

  @override
  Future<PaginatedResult<ClientPackage>> fetchClientPackagesPage({int limit = 20, Object? startAfter}) async {
    final startIndex = startAfter == null ? 0 : (startAfter as int);
    final endIndex = (startIndex + limit).clamp(0, _packages.length);
    final items = _packages.sublist(startIndex, endIndex);
    return PaginatedResult(items: items, lastCursor: endIndex < _packages.length ? endIndex : null);
  }

  @override
  Future<PaginatedResult<NotificationLog>> fetchNotificationsPage({int limit = 20, Object? startAfter}) async {
    final startIndex = startAfter == null ? 0 : (startAfter as int);
    final endIndex = (startIndex + limit).clamp(0, _notifications.length);
    final items = _notifications.sublist(startIndex, endIndex);
    return PaginatedResult(items: items, lastCursor: endIndex < _notifications.length ? endIndex : null);
  }

  @override
  Future<PaginatedResult<PackagePriceHistory>> fetchPackagePriceHistoryPage({int limit = 20, Object? startAfter}) async {
    final startIndex = startAfter == null ? 0 : (startAfter as int);
    final endIndex = (startIndex + limit).clamp(0, _priceHistory.length);
    final items = _priceHistory.sublist(startIndex, endIndex);
    return PaginatedResult(items: items, lastCursor: endIndex < _priceHistory.length ? endIndex : null);
  }

  @override
  Future<DeadlineOffsetConfig> loadDeadlineConfig() async {
    final raw = _prefs.getString(_kDeadlineConfig);
    if (raw == null || raw.isEmpty) return DeadlineOffsetConfig.defaults;
    try {
      return DeadlineOffsetConfig.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return DeadlineOffsetConfig.defaults;
    }
  }

  @override
  Future<void> saveDeadlineConfig(DeadlineOffsetConfig config) async {
    _deadlineConfig = config;
    await _prefs.setString(_kDeadlineConfig, jsonEncode(config.toMap()));
  }

  @override
  Future<void> upsertFestival(Festival festival) async {
    final i = _festivals.indexWhere((f) => f.id == festival.id);
    if (i >= 0) {
      _festivals[i] = festival;
    } else {
      _festivals.add(festival);
    }
    _festivals.sort((a, b) => a.date.compareTo(b.date));
    await _persistFestivals();

    var changed = false;
    for (var j = 0; j < _assignments.length; j++) {
      final a = _assignments[j];
      if (a.festivalId != festival.id) continue;
      _assignments[j] = a.withRecalculatedDeadlines(
        festival.date,
        offsets: _deadlineConfig,
      );
      changed = true;
    }
    if (changed) await _persistAssignments();
  }

  @override
  Future<void> deleteFestival(String id) async {
    _festivals.removeWhere((f) => f.id == id);
    await _persistFestivals();
    _assignments.removeWhere((a) => a.festivalId == id);
    await _persistAssignments();
    var clientsChanged = false;
    for (var i = 0; i < _clients.length; i++) {
      final c = _clients[i];
      if (c.festivalIds.contains(id)) {
        _clients[i] = c.copyWith(
          festivalIds: c.festivalIds.where((f) => f != id).toList(),
        );
        clientsChanged = true;
      }
    }
    if (clientsChanged) await _persistClients();
  }

  @override
  Future<void> upsertClient(Client client) async {
    final i = _clients.indexWhere((c) => c.id == client.id);
    if (i >= 0) {
      _clients[i] = client;
    } else {
      _clients.add(client);
    }
    _clients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await _persistClients();
  }

  @override
  Future<void> deleteClient(String id) async {
    _clients.removeWhere((c) => c.id == id);
    await _persistClients();
    _assignments.removeWhere((a) => a.clientId == id);
    await _persistAssignments();
    final packageIds =
        _packages.where((p) => p.clientId == id).map((p) => p.id).toSet();
    _packages.removeWhere((p) => p.clientId == id);
    _priceHistory.removeWhere((h) => packageIds.contains(h.packageId));
    await _persistPackages();
    await _persistPriceHistory();
  }

  @override
  Future<void> upsertAssignment(Assignment assignment) async {
    final i = _assignments.indexWhere((a) => a.id == assignment.id);
    if (i >= 0) {
      _assignments[i] = assignment;
    } else {
      _assignments.add(assignment);
    }
    await _persistAssignments();
  }

  @override
  Future<void> deleteAssignment(String id) async {
    _assignments.removeWhere((a) => a.id == id);
    await _persistAssignments();
  }

  @override
  Future<void> setAssignmentStatus(
    String id,
    AssignmentStatus status, {
    DateTime? sentAt,
    String? sentByRole,
  }) async {
    final i = _assignments.indexWhere((a) => a.id == id);
    if (i < 0) return;
    var a = _assignments[i].copyWith(status: status);
    if (status == AssignmentStatus.sent) {
      a = a.copyWith(
        sentAt: sentAt ?? DateTime.now(),
        sentByRole: sentByRole,
      );
    }
    _assignments[i] = a;
    await _persistAssignments();
  }

  @override
  Future<void> upsertNotification(NotificationLog log) async {
    final i = _notifications.indexWhere((n) => n.id == log.id);
    if (i >= 0) {
      _notifications[i] = log;
    } else {
      _notifications.insert(0, log);
    }
    // Cap log size
    if (_notifications.length > 200) {
      _notifications = _notifications.take(200).toList();
    }
    await _persistNotifications();
  }

  @override
  Future<void> markNotificationRead(String id, String userId) async {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i < 0) return;
    if (!_notifications[i].readBy.contains(userId)) {
      final newReadBy = List<String>.from(_notifications[i].readBy)..add(userId);
      _notifications[i] = _notifications[i].copyWith(readBy: newReadBy);
    }
    await _persistNotifications();
  }

  @override
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _persistNotifications();
  }

  @override
  Future<void> deleteOldNotifications(DateTime beforeDate) async {
    _notifications.removeWhere((n) => n.sentAt.isBefore(beforeDate));
    await _persistNotifications();
  }

  @override
  Future<void> clearNotifications() async {
    _notifications = [];
    await _persistNotifications();
  }

  @override
  Future<void> seedDefaultFestivalsIfNeeded(int year) async {
    final seeded = _prefs.getInt(_kSeededYear);
    if (seeded == year && _festivals.isNotEmpty) return;

    if (_festivals.isEmpty) {
      for (final def in kDefaultFestivals) {
        _festivals.add(
          Festival(
            id: _uuid.v4(),
            name: def.name,
            date: def.dateForYear(year),
            category: def.category,
            isCustom: false,
          ),
        );
      }
      _festivals.sort((a, b) => a.date.compareTo(b.date));
      await _persistFestivals();
    }
    await _prefs.setInt(_kSeededYear, year);
  }

  @override
  Future<List<Assignment>> syncClientAssignments({
    required String clientId,
    required List<String> festivalIds,
    required Map<String, Festival> festivalsById,
    DeadlineOffsetConfig offsets = DeadlineOffsetConfig.defaults,
  }) async {
    final desired = festivalIds.toSet();
    final existing = _assignments.where((a) => a.clientId == clientId).toList();

    final toRemove = existing.where((a) => !desired.contains(a.festivalId)).toList();
    for (final a in toRemove) {
      _assignments.removeWhere((x) => x.id == a.id);
    }

    final newAssignments = <Assignment>[];
    final existingFestivalIds = existing.map((a) => a.festivalId).toSet();
    for (final fid in desired) {
      if (existingFestivalIds.contains(fid)) continue;
      final festival = festivalsById[fid];
      if (festival == null) continue;
      final assignment = Assignment.create(
        id: _uuid.v4(),
        clientId: clientId,
        festivalId: fid,
        festivalDate: festival.date,
        offsets: offsets,
      );
      _assignments.add(assignment);
      newAssignments.add(assignment);
    }

    await _persistAssignments();
    return newAssignments;
  }

  @override
  Future<void> recalculateAllDeadlines({
    required Map<String, Festival> festivalsById,
    required DeadlineOffsetConfig offsets,
  }) async {
    _deadlineConfig = offsets;
    for (var i = 0; i < _assignments.length; i++) {
      final a = _assignments[i];
      final fest = festivalsById[a.festivalId];
      if (fest == null) continue;
      _assignments[i] = a.withRecalculatedDeadlines(fest.date, offsets: offsets);
    }
    await _persistAssignments();
  }

  @override
  Future<void> upsertClientPackage(ClientPackage package) async {
    final i = _packages.indexWhere((p) => p.id == package.id);
    if (i >= 0) {
      _packages[i] = package;
    } else {
      _packages.add(package);
    }
    _packages.sort((a, b) {
      final y = b.year.compareTo(a.year);
      if (y != 0) return y;
      return a.clientId.compareTo(b.clientId);
    });
    await _persistPackages();
  }

  @override
  Future<void> deleteClientPackage(String id) async {
    _packages.removeWhere((p) => p.id == id);
    _priceHistory.removeWhere((h) => h.packageId == id);
    await _persistPackages();
    await _persistPriceHistory();
  }

  @override
  Future<void> addPackagePriceHistory(PackagePriceHistory entry) async {
    _priceHistory.insert(0, entry);
    await _persistPriceHistory();
  }

  @override
  Future<int> createYearPackagesForAllClients({
    required int year,
    required double price,
    String currency = 'INR',
    String? createdByUid,
    String? createdByRole,
  }) async {
    final now = DateTime.now();
    final existingKeys = {
      for (final p in _packages) '${p.clientId}_$year',
    };
    var created = 0;

    for (final client in _clients) {
      final key = '${client.id}_$year';
      if (existingKeys.contains(key)) continue;

      // Prefer client-specific package price when set.
      final clientPrice = client.packagePrice ?? price;
      final start = client.createdAt != null
          ? DateTime(year, client.createdAt!.month, client.createdAt!.day)
          : DateTime(year, now.month, now.day);
      final end = DateTime(start.year + 1, start.month, start.day);

      final packageId = _uuid.v4();
      final package = ClientPackage(
        id: packageId,
        clientId: client.id,
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
      _packages.add(package);
      _priceHistory.insert(
        0,
        PackagePriceHistory(
          id: _uuid.v4(),
          packageId: packageId,
          clientId: client.id,
          year: year,
          price: clientPrice,
          previousPrice: null,
          note: 'Initial package price',
          changedAt: now,
          changedByUid: createdByUid,
          changedByRole: createdByRole,
        ),
      );
      existingKeys.add(key);
      created++;
    }

    if (created > 0) {
      await _persistPackages();
      await _persistPriceHistory();
    }
    return created;
  }

  @override
  void dispose() {
    _festivalsCtrl.close();
    _clientsCtrl.close();
    _assignmentsCtrl.close();
    _notificationsCtrl.close();
    _packagesCtrl.close();
    _priceHistoryCtrl.close();
  }
}
