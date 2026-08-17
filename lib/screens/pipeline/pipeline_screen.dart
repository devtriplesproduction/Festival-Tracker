import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/assignment_status.dart';
import '../../models/user_role.dart';
import '../../providers/app_state.dart';
import '../../providers/auth_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/assignment_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ui_kit.dart';
import 'upload_poster_screen.dart';

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';
  String _festivalFilter = 'all';
  int _eventsLimit = 1;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final role = context.watch<AuthState>().role ?? UserRole.designer;
    final allRows = state.filteredPipeline(
      search: _searchCtrl.text,
      statusFilter: _statusFilter,
      festivalFilter: _festivalFilter,
    );

    // Extract distinct upcoming events/festivals in order of appearance
    final orderedFestivalIds = <String>[];
    for (final a in allRows) {
      if (!orderedFestivalIds.contains(a.festivalId)) {
        orderedFestivalIds.add(a.festivalId);
      }
    }

    final visibleFestivalIds = orderedFestivalIds.take(_eventsLimit).toSet();
    final rows = allRows.where((a) => visibleFestivalIds.contains(a.festivalId)).toList();
    final hasMore = orderedFestivalIds.length > _eventsLimit;
    final nextFestivalId = _eventsLimit < orderedFestivalIds.length ? orderedFestivalIds[_eventsLimit] : null;
    final nextFestival = nextFestivalId != null ? state.festivalById(nextFestivalId) : null;
    final nextFestivalName = nextFestival?.name;
    final canAssign = role.canCreateAssignments;
    final stats = state.stats;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ResponsiveContent(
          child: state.loading
              ? const Center(child: CupertinoActivityIndicator())
              : CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: PageHeader(
                      title: 'Festival Tracker',
                      subtitle: 'Track assignments & workflow status',
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: context.pageInsets,
                      child: AppSearchField(
                        controller: _searchCtrl,
                        placeholder: 'Search client or festival',
                        onChanged: (_) => setState(() {
                          _eventsLimit = 1;
                        }),
                        onClear: () => setState(() {
                          _searchCtrl.clear();
                          _eventsLimit = 1;
                        }),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.fromLTRB(
                        context.pagePadding,
                        12,
                        context.pagePadding,
                        4,
                      ),
                      child: Row(
                        children: [
                          FilterChipPill(
                            label: 'All',
                            selected: _statusFilter == 'all',
                            onTap: () => setState(() {
                              _statusFilter = 'all';
                              _eventsLimit = 1;
                            }),
                          ),
                          FilterChipPill(
                            label: 'Overdue',
                            selected: _statusFilter == 'overdue' ||
                                _statusFilter == 'month_overdue',
                            danger: true,
                            count: stats.monthOverdue > 0
                                ? stats.monthOverdue
                                : null,
                            onTap: () => setState(() {
                              _statusFilter = 'month_overdue';
                              _eventsLimit = 1;
                            }),
                          ),
                          ...AssignmentStatus.values.map(
                            (s) => FilterChipPill(
                              label: s.label,
                              selected: _statusFilter == s.value,
                              onTap: () => setState(() {
                                _statusFilter = s.value;
                                _eventsLimit = 1;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (state.assignments.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: CupertinoIcons.square_list,
                        title: 'No jobs yet',
                        message: canAssign
                            ? 'Assign a client to a festival. Deadlines are created automatically.'
                            : 'Waiting for Admin or Manager to assign work.',
                        actionLabel: canAssign ? 'Assign first job' : null,
                        onAction: canAssign ? () => _openAssign(context) : null,
                      ),
                    )
                  else if (rows.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(CupertinoIcons.search, size: 36, color: AppColors.textTertiary),
                            const SizedBox(height: 12),
                            Text(
                              'No jobs match this filter',
                              style: AppFonts.montserrat(size: 16, weight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try All, or clear search',
                              style: AppFonts.helvetica(size: 13),
                            ),
                            const SizedBox(height: 14),
                            SecondaryButton(
                              label: 'Clear filters',
                              onPressed: () => setState(() {
                                _statusFilter = 'all';
                                _festivalFilter = 'all';
                                _searchCtrl.clear();
                                _eventsLimit = 1;
                              }),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: context.pageInsetsOnly(top: 4, bottom: 6),
                        child: Text(
                          '${rows.length} job${rows.length == 1 ? '' : 's'}${orderedFestivalIds.isNotEmpty ? ' · ${visibleFestivalIds.length} of ${orderedFestivalIds.length} event${orderedFestivalIds.length == 1 ? '' : 's'}' : ''} · tap card to change stage',
                          style: AppFonts.helvetica(size: 12, color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: context.listBottomPadding, top: 2),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == rows.length) {
                              if (hasMore) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                                  child: Center(
                                    child: SecondaryButton(
                                      icon: CupertinoIcons.arrow_down_circle,
                                      label: nextFestivalName != null && nextFestivalName.isNotEmpty
                                          ? 'Load More ($nextFestivalName)'
                                          : 'Load More',
                                      onPressed: () {
                                        setState(() {
                                          _eventsLimit += 1;
                                        });
                                      },
                                    ),
                                  ),
                                );
                              } else if (rows.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: Text(
                                      'All upcoming events loaded',
                                      style: AppFonts.helvetica(size: 13, color: AppColors.textTertiary),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }

                            final a = rows[index];
                            return AssignmentCard(
                              assignment: a,
                              client: state.clientById(a.clientId),
                              festival: state.festivalById(a.festivalId),
                              role: role,
                              isInitiallyExpanded: index == 0,
                              onAdvance: () {
                                final next = a.status.next;
                                if (!role.canSetStatus(next.value)) {
                                  _roleAlert(context, 'Your role cannot advance to ${next.label}.');
                                  return;
                                }
                                state.advanceStatus(a, byRole: role);
                              },
                              onChangeStatus: (s) {
                                if (!role.canSetStatus(s.value)) {
                                  _roleAlert(context, 'Your role cannot set status to ${s.label}.');
                                  return;
                                }
                                state.setStatus(a, s, byRole: role);
                              },
                              onUpload: role.canUploadPoster ? () => _openUpload(context, a) : null,
                              onSendWhatsApp:
                                  role.canSendWhatsApp ? () => _sendWhatsApp(context, a, role) : null,
                              onQcApprove: role.canQcReview
                                  ? () => state.setStatus(a, AssignmentStatus.ready, byRole: role)
                                  : null,
                              onQcRequestChanges: role.canQcReview
                                  ? () => state.setStatus(a, AssignmentStatus.design, byRole: role)
                                  : null,
                            );
                          },
                          childCount: rows.length + 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
        ),
      ),
    );
  }

  Future<void> _openUpload(BuildContext context, assignment) async {
    final state = context.read<AppState>();
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => UploadPosterScreen(
          assignment: assignment,
          client: state.clientById(assignment.clientId),
          festival: state.festivalById(assignment.festivalId),
        ),
      ),
    );
  }

  Future<void> _sendWhatsApp(BuildContext context, assignment, UserRole role) async {
    final state = context.read<AppState>();
    final client = state.clientById(assignment.clientId);
    if (client == null || client.whatsappDigits.isEmpty) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('No WhatsApp number'),
          content: const Text('Add a WhatsApp number on the client first.'),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Send via WhatsApp?'),
        content: Text(
          'Opens WhatsApp for ${client.name} with the poster link.\n\n'
          'Status will be marked Sent.',
        ),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open WhatsApp')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final ok = await state.sendViaWhatsApp(assignment, byRole: role);
    if (!ok && context.mounted) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Could not open WhatsApp'),
          content: const Text('Check that WhatsApp is installed and the number is valid.'),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<void> _openAssign(BuildContext context) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const AssignWorkScreen()),
    );
  }

  Future<void> _roleAlert(BuildContext context, String msg) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Not allowed'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}

class AssignWorkScreen extends StatefulWidget {
  const AssignWorkScreen({super.key});

  @override
  State<AssignWorkScreen> createState() => _AssignWorkScreenState();
}

class _AssignWorkScreenState extends State<AssignWorkScreen> {
  String? _clientId;
  String? _festivalId;
  bool _saving = false;

  Future<void> _save() async {
    if (_clientId == null || _festivalId == null) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Select both'),
          content: const Text('Pick one client and one festival.'),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AppState>().createAssignment(
            clientId: _clientId!,
            festivalId: _festivalId!,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Bad state: ', '');
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Could not assign'),
          content: Text(msg),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sortedFestivals = List.of(state.festivals)..sort((a, b) {
      final aPast = a.date.isBefore(today);
      final bPast = b.date.isBefore(today);
      if (aPast && !bPast) return 1;
      if (!aPast && bPast) return -1;
      return a.date.compareTo(b.date);
    });

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.94),
        border: null,
        middle: Text('New job', style: AppFonts.montserrat(size: 17, weight: FontWeight.w700)),
        trailing: NavBarActionButton(
          label: 'Create',
          icon: CupertinoIcons.checkmark_alt,
          onPressed: _saving ? null : _save,
          loading: _saving,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionLabel('1 · Client'),
            const SizedBox(height: 8),
            if (state.clients.isEmpty)
              AppCard(
                child: Text(
                  'No clients yet. Add one under Clients first.',
                  style: AppFonts.poppins(size: 14, color: AppColors.textSecondary),
                ),
              )
            else
              ...state.clients.map((c) {
                final selected = _clientId == c.id;
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  highlightColor: selected ? AppColors.accent : null,
                  onTap: () => setState(() => _clientId = c.id),
                  child: Row(
                    children: [
                      LetterAvatar(label: c.name, size: 40, color: selected ? AppColors.accent : AppColors.textTertiary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: AppFonts.montserrat(size: 15, weight: FontWeight.w700)),
                            if (c.whatsappNumber.isNotEmpty)
                              Text('+${c.whatsappDigits}', style: AppFonts.helvetica(size: 12)),
                          ],
                        ),
                      ),
                      Icon(
                        selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                        color: selected ? AppColors.accent : AppColors.textTertiary,
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 18),
            const SectionLabel('2 · Festival'),
            const SizedBox(height: 8),
            if (sortedFestivals.isEmpty)
              AppCard(
                child: Text(
                  'No festivals yet. Admin should add festivals first.',
                  style: AppFonts.poppins(size: 14, color: AppColors.textSecondary),
                ),
              )
            else
              ...sortedFestivals.map((f) {
                final selected = _festivalId == f.id;
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  highlightColor: selected ? AppColors.accent : null,
                  onTap: () => setState(() => _festivalId = f.id),
                  child: Row(
                    children: [
                      IconBadge(
                        icon: CupertinoIcons.calendar,
                        color: selected ? AppColors.accent : AppColors.textTertiary,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.name, style: AppFonts.montserrat(size: 15, weight: FontWeight.w700)),
                            Text(formatDateWeekday(f.date), style: AppFonts.helvetica(size: 12)),
                          ],
                        ),
                      ),
                      Icon(
                        selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                        color: selected ? AppColors.accent : AppColors.textTertiary,
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Create job',
              icon: CupertinoIcons.checkmark_alt,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
