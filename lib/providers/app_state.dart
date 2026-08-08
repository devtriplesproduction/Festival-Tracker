import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/repositories/app_repository.dart';
import '../models/assignment.dart';
import '../models/assignment_status.dart';
import '../models/client.dart';
import '../models/client_package.dart';
import '../models/deadline_config.dart';
import '../models/festival.dart';
import '../models/notification_log.dart';
import '../models/package_delivery.dart';
import '../models/package_price_history.dart';
import '../models/pipeline_stats.dart';
import '../models/user_role.dart';

import '../services/whatsapp_service.dart';
import '../core/services/notification_api_client.dart';

/// App-wide state for festivals, clients, pipeline, alerts, and settings.
class AppState extends ChangeNotifier {
  AppState(this._repo, {this.notificationApiClient});

  final AppRepository _repo;
  final NotificationApiClient? notificationApiClient;
  final _uuid = const Uuid();

  List<Festival> festivals = [];
  List<Client> clients = [];
  List<Assignment> assignments = [];
  List<NotificationLog> notifications = [];
  List<ClientPackage> clientPackages = [];
  List<PackagePriceHistory> packagePriceHistory = [];
  DeadlineOffsetConfig deadlineConfig = DeadlineOffsetConfig.defaults;

  bool loading = true;
  String? error;
  bool usingLocalStore = true;

  StreamSubscription<List<Festival>>? _festSub;
  StreamSubscription<List<Client>>? _clientSub;
  StreamSubscription<List<Assignment>>? _assignSub;
  StreamSubscription<List<NotificationLog>>? _notifSub;
  StreamSubscription<List<ClientPackage>>? _packageSub;
  StreamSubscription<List<PackagePriceHistory>>? _priceHistorySub;

  Future<void> init({required bool localStore}) async {
    usingLocalStore = localStore;
    loading = true;
    error = null;
    notifyListeners();

    try {
      deadlineConfig = await _repo.loadDeadlineConfig();
      await _repo.seedDefaultFestivalsIfNeeded(DateTime.now().year);

      _festSub = _repo.watchFestivals().listen((list) {
        festivals = list;
        loading = false;
        notifyListeners();
      }, onError: (e) {
        error = e.toString();
        loading = false;
        notifyListeners();
      });

      _clientSub = _repo.watchClients().listen((list) {
        clients = list;
        notifyListeners();
      });

      _assignSub = _repo.watchAssignments().listen((list) {
        assignments = list;
        notifyListeners();
      });

      _notifSub = _repo.watchNotifications().listen((list) {
        notifications = list;
        notifyListeners();
      });

      _packageSub = _repo.watchClientPackages().listen((list) {
        clientPackages = list;
        notifyListeners();
      });

      _priceHistorySub = _repo.watchPackagePriceHistory().listen((list) {
        packagePriceHistory = list;
        notifyListeners();
      });
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  Festival? festivalById(String id) {
    try {
      return festivals.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Client? clientById(String id) {
    try {
      return clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, Festival> get festivalsById => {
        for (final f in festivals) f.id: f,
      };

  List<Assignment> get activeAssignments {
    return assignments.where((a) {
      final f = festivalById(a.festivalId);
      final year = f?.date.year ?? a.sendDueDate.year;
      final pkg = packageForClientYear(a.clientId, year);
      return pkg == null || !pkg.isStopped;
    }).toList();
  }

  List<Assignment> get pipelineSorted {
    final list = List<Assignment>.from(activeAssignments);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    list.sort((a, b) {
      if (a.status.isTerminal != b.status.isTerminal) {
        return a.status.isTerminal ? 1 : -1;
      }
      
      final aPast = a.sortDeadline.isBefore(today);
      final bPast = b.sortDeadline.isBefore(today);
      
      if (aPast && !bPast) return 1;
      if (!aPast && bPast) return -1;
      
      return a.sortDeadline.compareTo(b.sortDeadline);
    });
    return list;
  }

  int get overdueCount => activeAssignments.where((a) => a.isOverdue()).length;

  int get unreadNotificationsCount =>
      notifications.where((n) => !n.read).length;

  /// Job belongs to [month] if its festival date falls in that calendar month.
  bool isCurrentMonthJob(Assignment a, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final festival = festivalById(a.festivalId);
    final day = festival?.date ?? a.sendDueDate;
    return day.year == ref.year && day.month == ref.month;
  }

  PipelineStats get stats {
    var notStarted = 0, design = 0, qc = 0, ready = 0, sent = 0, overdue = 0;
    var monthPosters = 0, monthOverdue = 0, monthSent = 0;
    final active = activeAssignments;
    for (final a in active) {
      switch (a.status) {
        case AssignmentStatus.notStarted:
          notStarted++;
        case AssignmentStatus.design:
          design++;
        case AssignmentStatus.qc:
          qc++;
        case AssignmentStatus.ready:
          ready++;
        case AssignmentStatus.sent:
          sent++;
      }
      if (a.isOverdue()) overdue++;

      if (isCurrentMonthJob(a)) {
        monthPosters++;
        if (a.isOverdue()) monthOverdue++;
        if (a.status == AssignmentStatus.sent) monthSent++;
      }
    }
    return PipelineStats(
      total: active.length,
      notStarted: notStarted,
      inDesign: design,
      inQc: qc,
      readyToSend: ready,
      sent: sent,
      overdueCount: overdue,
      monthPosters: monthPosters,
      monthOverdue: monthOverdue,
      monthSent: monthSent,
    );
  }

  /// Filter pipeline for search / status / festival chips.
  List<Assignment> filteredPipeline({
    String search = '',
    String statusFilter = 'all',
    String festivalFilter = 'all',
  }) {
    final q = search.trim().toLowerCase();
    return pipelineSorted.where((a) {
      final client = clientById(a.clientId);
      final festival = festivalById(a.festivalId);
      if (q.isNotEmpty) {
        final hay =
            '${client?.name ?? ''} ${festival?.name ?? ''} ${client?.companyName ?? ''}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (festivalFilter != 'all' && a.festivalId != festivalFilter) {
        return false;
      }
      // Month KPI filters (festival date in current calendar month).
      if (statusFilter == 'month') return isCurrentMonthJob(a);
      if (statusFilter == 'month_overdue') {
        return a.isOverdue() && isCurrentMonthJob(a);
      }
      if (statusFilter == 'month_sent') {
        return a.status == AssignmentStatus.sent && isCurrentMonthJob(a);
      }
      if (statusFilter == 'overdue') return a.isOverdue();
      if (statusFilter != 'all' && a.status.value != statusFilter) return false;
      return true;
    }).toList();
  }

  Future<void> addFestival({
    required String name,
    required DateTime date,
    String category = 'Major Festival',
    String? description,
  }) async {
    final festival = Festival(
      id: _uuid.v4(),
      name: name.trim(),
      date: Festival.dateOnly(date),
      category: category,
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      isCustom: true,
    );
    await _repo.upsertFestival(festival);
  }

  Future<void> updateFestival(Festival festival) async {
    await _repo.upsertFestival(
      festival.copyWith(date: Festival.dateOnly(festival.date)),
    );
  }

  Future<void> deleteFestival(String id) async {
    await _repo.deleteFestival(id);
  }

  Future<Client> saveClient({
    String? id,
    required String name,
    required String whatsappNumber,
    String? companyName,
    String? notes,
    List<String>? festivalIds,
    double? packagePrice,
    bool syncAssignments = false,
    bool createPackageIfNew = true,
    String? createdByUid,
  }) async {
    final existing = id != null ? clientById(id) : null;
    final isNew = existing == null;
    final now = DateTime.now();
    final client = Client(
      id: id ?? _uuid.v4(),
      name: name.trim(),
      whatsappNumber: whatsappNumber.trim(),
      companyName: companyName?.trim().isEmpty == true ? null : companyName?.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      festivalIds: festivalIds ?? existing?.festivalIds ?? const [],
      packagePrice: packagePrice ?? existing?.packagePrice,
      createdAt: existing?.createdAt ?? now,
    );
    await _repo.upsertClient(client);
    final i = clients.indexWhere((c) => c.id == client.id);
    if (i >= 0) {
      clients[i] = client;
    } else {
      clients = [...clients, client];
    }

    // Keep active package price in sync with client package price.
    if (packagePrice != null) {
      final active = clientPackages
          .where((p) => p.clientId == client.id && p.isActive)
          .toList();
      for (final p in active) {
        if (p.price != packagePrice) {
          await updatePackagePrice(
            p,
            newPrice: packagePrice,
            note: 'Updated from client profile',
            changedByUid: createdByUid,
          );
        }
      }
    }

    // New client with a package price → create 1-year package from creation date.
    if (isNew &&
        createPackageIfNew &&
        packagePrice != null &&
        packagePrice > 0) {
      final already = clientPackages.any((p) => p.clientId == client.id);
      if (!already) {
        final pkg = ClientPackage.initialForClient(
          id: _uuid.v4(),
          clientId: client.id,
          price: packagePrice,
          from: client.createdAt,
          createdByUid: createdByUid,
          paymentStatus: PackagePaymentStatus.paid,
        );
        await _repo.upsertClientPackage(pkg);
        await _repo.addPackagePriceHistory(
          PackagePriceHistory(
            id: _uuid.v4(),
            packageId: pkg.id,
            clientId: client.id,
            year: pkg.year,
            price: packagePrice,
            previousPrice: null,
            note: 'Initial package price at client creation',
            changedAt: now,
            changedByUid: createdByUid,
          ),
        );
        clientPackages = [...clientPackages, pkg];
      }
    }

    if (syncAssignments) {
      await _repo.syncClientAssignments(
        clientId: client.id,
        festivalIds: client.festivalIds,
        festivalsById: festivalsById,
        offsets: deadlineConfig,
      );
    }
    notifyListeners();
    return client;
  }

  Future<void> updateClientFestivals(String clientId, List<String> festivalIds) async {
    final existing = clientById(clientId);
    if (existing == null) return;
    final client = existing.copyWith(festivalIds: festivalIds);
    await _repo.upsertClient(client);
    await _repo.syncClientAssignments(
      clientId: clientId,
      festivalIds: festivalIds,
      festivalsById: festivalsById,
      offsets: deadlineConfig,
    );
    final i = clients.indexWhere((c) => c.id == clientId);
    if (i >= 0) clients[i] = client;
    notifyListeners();
  }

  Future<void> deleteClient(String id) async {
    await _repo.deleteClient(id);
  }

  Future<Assignment?> createAssignment({
    required String clientId,
    required String festivalId,
  }) async {
    final festival = festivalById(festivalId);
    if (festival == null) return null;

    final exists = assignments.any(
      (a) => a.clientId == clientId && a.festivalId == festivalId,
    );
    if (exists) {
      throw StateError('This client is already assigned to that festival');
    }

    final assignment = Assignment.create(
      id: _uuid.v4(),
      clientId: clientId,
      festivalId: festivalId,
      festivalDate: festival.date,
      offsets: deadlineConfig,
    );
    await _repo.upsertAssignment(assignment);
    assignments = [...assignments, assignment];
    notifyListeners();
    return assignment;
  }

  Future<void> deleteAssignment(String id) async {
    await _repo.deleteAssignment(id);
  }

  Future<void> advanceStatus(Assignment assignment, {UserRole? byRole}) async {
    if (assignment.status.isTerminal) return;
    final next = assignment.status.next;
    await setStatus(assignment, next, byRole: byRole);
  }

  Future<void> setStatus(
    Assignment assignment,
    AssignmentStatus status, {
    UserRole? byRole,
  }) async {
    await _repo.setAssignmentStatus(
      assignment.id,
      status,
      sentAt: status == AssignmentStatus.sent ? DateTime.now() : null,
      sentByRole: status == AssignmentStatus.sent ? byRole?.value : null,
    );

    // Dispatch real-time pushes for status changes
    if (status == AssignmentStatus.ready) {
       _dispatchPush(NotificationEventType.qcApproved, targetRole: 'manager', data: {
         'clientName': 'Client', // Would need lookup, but using general terms for now or fetching real data
         'festivalName': 'Festival', 
         'assignmentId': assignment.id,
         'route': '/pipeline'
       });
    }
  }

  /// Save poster as a free URL only (Google Drive / any public link).
  /// No Firebase Storage — Firestore (or local prefs) stores the string fields.
  

  /// Open WhatsApp with prefilled message and mark as sent.
  Future<bool> sendViaWhatsApp(
    Assignment assignment, {
    required UserRole byRole,
  }) async {
    final client = clientById(assignment.clientId);
    final festival = festivalById(assignment.festivalId);
    if (client == null || client.whatsappDigits.isEmpty) return false;

    final ok = await WhatsAppService.openChat(
      phoneNumber: client.whatsappDigits,
      clientName: client.name,
      festivalName: festival?.name ?? 'Festival',
      driveUrl: assignment.posterUrl,
    );
    if (ok) {
      await setStatus(assignment, AssignmentStatus.sent, byRole: byRole);
    }
    return ok;
  }

  Future<void> saveDeadlineOffsets(DeadlineOffsetConfig config) async {
    deadlineConfig = config;
    await _repo.saveDeadlineConfig(config);
    await _repo.recalculateAllDeadlines(
      festivalsById: festivalsById,
      offsets: config,
    );
    notifyListeners();
  }

  /// Generate in-app alerts for missing uploads / pending sends / overdue jobs /
  /// package renewals (15 days before end based on client creation cycle).
  Future<int> runDailyCheck() async {
    final now = DateTime.now();
    var created = 0;
    for (final a in activeAssignments) {
      final client = clientById(a.clientId);
      final festival = festivalById(a.festivalId);
      if (client == null || festival == null) continue;
      if (a.status == AssignmentStatus.sent) continue;

      if (!a.hasPoster) {
        await _repo.upsertNotification(
          NotificationLog(
            id: _uuid.v4(),
            assignmentId: a.id,
            clientName: client.name,
            festivalName: festival.name,
            type: NotificationType.uploadReminder,
            message:
                'Upload poster for ${client.name} — ${festival.name} is approaching!',
            sentAt: now,
            recipientRole: 'designer',
          ),
        );
        _dispatchPush(NotificationEventType.deadlineReminder, targetRole: 'designer', data: {
          'clientName': client.name,
          'festivalName': festival.name,
          'assignmentId': a.id,
          'route': '/pipeline'
        });
        created++;
      } else if (a.status != AssignmentStatus.sent) {
        await _repo.upsertNotification(
          NotificationLog(
            id: _uuid.v4(),
            assignmentId: a.id,
            clientName: client.name,
            festivalName: festival.name,
            type: NotificationType.sendReminder,
            message:
                'Send ${client.name}\'s poster via WhatsApp — event: ${festival.name}',
            sentAt: now,
            recipientRole: 'manager',
          ),
        );
        _dispatchPush(NotificationEventType.readyToSend, targetRole: 'manager', data: {
          'clientName': client.name,
          'festivalName': festival.name,
          'assignmentId': a.id,
          'route': '/pipeline'
        });
        created++;
      }

      if (a.isOverdue(now)) {
        await _repo.upsertNotification(
          NotificationLog(
            id: _uuid.v4(),
            assignmentId: a.id,
            clientName: client.name,
            festivalName: festival.name,
            type: NotificationType.overdueAlert,
            message:
                '${client.name} · ${festival.name} is ${a.daysLate(now)} day(s) past deadline',
            sentAt: now,
            recipientRole: 'all',
          ),
        );
        _dispatchPush(NotificationEventType.overdueReminder, targetRole: 'admin', data: { // Notify admins about overdue
          'clientName': client.name,
          'festivalName': festival.name,
          'assignmentId': a.id,
          'route': '/pipeline'
        });
        created++;
      }
    }

    created += await _runPackageRenewalChecks(now);
    return created;
  }

  /// 15-day renewal reminders + auto-stop when expired without payment.
  Future<int> _runPackageRenewalChecks(DateTime now) async {
    var created = 0;
    for (final pkg in List<ClientPackage>.from(clientPackages)) {
      if (!pkg.isActive) continue;
      final client = clientById(pkg.clientId);
      if (client == null) continue;

      // Ensure endDate exists (migrate old packages from client.createdAt).
      var current = pkg;
      if (current.endDate == null) {
        final start = current.startDate ??
            client.createdAt ??
            current.createdAt ??
            now;
        final end = DateTime(start.year + 1, start.month, start.day);
        current = current.copyWith(
          startDate: DateTime(start.year, start.month, start.day),
          endDate: end,
          updatedAt: now,
        );
        await _repo.upsertClientPackage(current);
        _replacePackageLocal(current);
      }

      // Auto-stop if package period ended and renewal payment not received.
      if (current.isExpired(now) && !current.isPaid) {
        final stopped = current.copyWith(
          packageStatus: PackageStatus.stopped,
          updatedAt: now,
          note: 'Auto-stopped: package expired without payment',
        );
        await _repo.upsertClientPackage(stopped);
        _replacePackageLocal(stopped);
        continue;
      }

      // Notify 15 days before renewal (once per renewal window).
      if (current.isRenewalDueSoon(windowDays: 15, now: now)) {
        final already = current.renewalNotifiedAt != null &&
            now.difference(current.renewalNotifiedAt!).inDays < 20;
        if (already) continue;

        final days = current.daysUntilRenewal(now) ?? 0;
        final priceLabel = current.price > 0
            ? ' · ${current.currency == 'INR' ? '₹' : ''}${current.price.toStringAsFixed(0)}'
            : '';
        await _repo.upsertNotification(
          NotificationLog(
            id: _uuid.v4(),
            assignmentId: current.id,
            clientName: client.name,
            festivalName: 'Package renewal',
            type: NotificationType.packageRenewal,
            message: days == 0
                ? '${client.name}: package renews today$priceLabel. Mark payment received, then renew — or stop.'
                : '${client.name}: package renews in $days day(s)$priceLabel. Collect payment to renew, or stop if unpaid.',
            sentAt: now,
            recipientRole: 'manager',
          ),
        );
        final marked = current.copyWith(
          renewalNotifiedAt: now,
          // Enter renewal collection state: payment needed for next year.
          paymentStatus: PackagePaymentStatus.unpaid,
          clearPaymentReceivedAt: true,
          updatedAt: now,
        );
        await _repo.upsertClientPackage(marked);
        _replacePackageLocal(marked);
        created++;
      }
    }
    notifyListeners();
    return created;
  }

  void _replacePackageLocal(ClientPackage pkg) {
    final i = clientPackages.indexWhere((p) => p.id == pkg.id);
    if (i >= 0) {
      clientPackages[i] = pkg;
    } else {
      clientPackages = [...clientPackages, pkg];
    }
  }

  /// Mark renewal / package payment as received.
  Future<void> markPackagePaymentReceived(ClientPackage package) async {
    final now = DateTime.now();
    final updated = package.copyWith(
      paymentStatus: PackagePaymentStatus.paid,
      paymentReceivedAt: now,
      updatedAt: now,
      packageStatus: PackageStatus.active,
    );
    await _repo.upsertClientPackage(updated);
    _replacePackageLocal(updated);
    notifyListeners();
  }

  /// Extend package by 1 year. Requires payment received.
  Future<void> renewClientPackage(ClientPackage package) async {
    if (!package.isPaid) {
      throw StateError('Mark payment as received before renewing the package.');
    }
    if (package.isStopped) {
      throw StateError('Stopped packages cannot be renewed. Mark payment first to reactivate.');
    }
    final now = DateTime.now();
    final oldEnd = package.endDate ?? now;
    final newStart = DateTime(oldEnd.year, oldEnd.month, oldEnd.day);
    // If already past end, renew from today.
    final start = newStart.isBefore(DateTime(now.year, now.month, now.day))
        ? DateTime(now.year, now.month, now.day)
        : newStart;
    final newEnd = DateTime(start.year + 1, start.month, start.day);
    final client = clientById(package.clientId);
    final price = client?.packagePrice ?? package.price;

    final renewed = package.copyWith(
      year: start.year,
      price: price,
      startDate: start,
      endDate: newEnd,
      paymentStatus: PackagePaymentStatus.paid,
      packageStatus: PackageStatus.active,
      paymentReceivedAt: package.paymentReceivedAt ?? now,
      updatedAt: now,
      clearRenewalNotifiedAt: true,
      note: 'Renewed for 1 year',
    );
    await _repo.upsertClientPackage(renewed);
    if (price != package.price) {
      await _repo.addPackagePriceHistory(
        PackagePriceHistory(
          id: _uuid.v4(),
          packageId: package.id,
          clientId: package.clientId,
          year: start.year,
          price: price,
          previousPrice: package.price,
          note: 'Price at renewal',
          changedAt: now,
        ),
      );
    }
    _replacePackageLocal(renewed);
    notifyListeners();
  }

  /// Stop package (e.g. payment not received).
  Future<void> stopClientPackage(ClientPackage package, {String? reason}) async {
    final now = DateTime.now();
    final stopped = package.copyWith(
      packageStatus: PackageStatus.stopped,
      updatedAt: now,
      note: reason ?? 'Stopped — payment not received',
    );
    await _repo.upsertClientPackage(stopped);
    _replacePackageLocal(stopped);
    notifyListeners();
  }

  /// Reactivate a stopped package after payment.
  Future<void> reactivateClientPackage(ClientPackage package) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(start.year + 1, start.month, start.day);
    final client = clientById(package.clientId);
    final updated = package.copyWith(
      packageStatus: PackageStatus.active,
      paymentStatus: PackagePaymentStatus.paid,
      paymentReceivedAt: now,
      startDate: start,
      endDate: end,
      year: start.year,
      price: client?.packagePrice ?? package.price,
      updatedAt: now,
      clearRenewalNotifiedAt: true,
      note: 'Reactivated after payment',
    );
    await _repo.upsertClientPackage(updated);
    _replacePackageLocal(updated);
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    await _repo.markNotificationRead(id);
  }

  Future<void> clearNotifications() async {
    await _repo.clearNotifications();
  }

  void _dispatchPush(NotificationEventType type, {String? targetUid, String? targetRole, Map<String, dynamic>? data}) {
    notificationApiClient?.sendEvent(
      eventType: type,
      targetUid: targetUid,
      targetRole: targetRole,
      data: data,
    );
  }

  // ── Year packages ────────────────────────────────────────────────────────

  ClientPackage? packageForClientYear(String clientId, int year) {
    try {
      return clientPackages.firstWhere(
        (p) => p.clientId == clientId && p.year == year,
      );
    } catch (_) {
      return null;
    }
  }

  List<ClientPackage> packagesForYear(int year) =>
      clientPackages.where((p) => p.year == year).toList();

  List<PackagePriceHistory> priceHistoryFor(String packageId) {
    final list =
        packagePriceHistory.where((h) => h.packageId == packageId).toList();
    list.sort((a, b) => b.changedAt.compareTo(a.changedAt));
    return list;
  }

  PackageProgress progressFor(ClientPackage package) {
    return buildPackageProgress(
      clientId: package.clientId,
      year: package.year,
      assignments: assignments,
      festivalsById: festivalsById,
    );
  }

  /// Bulk-create calendar-year packages for every client missing that year.
  Future<({int created, int skipped})> createYearPackagesForAllClients({
    required int year,
    required double price,
    String? createdByUid,
    UserRole? byRole,
  }) async {
    final before = clients.length;
    final created = await _repo.createYearPackagesForAllClients(
      year: year,
      price: price,
      createdByUid: createdByUid,
      createdByRole: byRole?.value,
    );
    final skipped = before - created;
    // Local store updates streams via persist; Firestore via snapshots.
    // Force local refresh awareness for callers.
    notifyListeners();
    return (created: created, skipped: skipped < 0 ? 0 : skipped);
  }

  Future<void> updatePackagePrice(
    ClientPackage package, {
    required double newPrice,
    String? note,
    String? changedByUid,
    UserRole? byRole,
  }) async {
    final now = DateTime.now();
    final previous = package.price;
    if (previous == newPrice && (note == null || note.trim().isEmpty)) return;

    final updated = package.copyWith(price: newPrice, updatedAt: now);
    await _repo.upsertClientPackage(updated);
    await _repo.addPackagePriceHistory(
      PackagePriceHistory(
        id: _uuid.v4(),
        packageId: package.id,
        clientId: package.clientId,
        year: package.year,
        price: newPrice,
        previousPrice: previous,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        changedAt: now,
        changedByUid: changedByUid,
        changedByRole: byRole?.value,
      ),
    );
    // Optimistic local update until stream catches up.
    final i = clientPackages.indexWhere((p) => p.id == package.id);
    if (i >= 0) clientPackages[i] = updated;
    notifyListeners();
  }

  Future<void> deleteClientPackage(String id) async {
    await _repo.deleteClientPackage(id);
    clientPackages.removeWhere((p) => p.id == id);
    packagePriceHistory.removeWhere((h) => h.packageId == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _festSub?.cancel();
    _clientSub?.cancel();
    _assignSub?.cancel();
    _notifSub?.cancel();
    _packageSub?.cancel();
    _priceHistorySub?.cancel();
    _repo.dispose();
    super.dispose();
  }
}

