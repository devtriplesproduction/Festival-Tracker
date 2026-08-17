import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/date_formatters.dart';
import '../../models/festival.dart';
import '../../models/user_role.dart';
import '../../providers/app_state.dart';
import '../../providers/auth_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/date_picker_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ui_kit.dart';

const _kCategories = [
  'Major Festival',
  'National',
  'Religious',
  'Cultural',
  'Global',
  'Custom',
];

class FestivalsScreen extends StatelessWidget {
  const FestivalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final role = context.watch<AuthState>().role ?? UserRole.designer;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final festivals = List<Festival>.from(state.festivals)
      ..sort((a, b) {
        final aPast = a.date.isBefore(today);
        final bPast = b.date.isBefore(today);
        if (aPast && !bPast) return 1;
        if (!aPast && bPast) return -1;
        return a.date.compareTo(b.date);
      });
    final canEdit = role.canManageFestivals;
    final offsets = state.deadlineConfig;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: state.loading
            ? const Center(child: CupertinoActivityIndicator())
            : festivals.isEmpty
                ? Column(
                    children: [
                      PageHeader(
                        title: 'Festivals',
                        subtitle: 'Event dates drive all deadlines',
                        trailing: canEdit
                            ? NavBarActionButton(
                                label: 'Add',
                                icon: CupertinoIcons.add,
                                onPressed: () => _openEditor(context),
                              )
                            : null,
                      ),
                      Expanded(
                        child: EmptyState(
                          icon: CupertinoIcons.calendar,
                          title: 'No festivals',
                          message: 'Add festival dates your clients need posters for.',
                          actionLabel: canEdit ? 'Add festival' : null,
                          onAction: canEdit ? () => _openEditor(context) : null,
                        ),
                      ),
                    ],
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: PageHeader(
                          title: 'Festivals',
                          subtitle:
                              '${festivals.length} events · deadlines = event − ${offsets.designDaysBefore}/${offsets.qcDaysBefore}/${offsets.readyDaysBefore}/1 days',
                          trailing: canEdit
                              ? NavBarActionButton(
                                  label: 'Add',
                                  icon: CupertinoIcons.add,
                                  onPressed: () => _openEditor(context),
                                )
                              : null,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: context.pageInsetsOnly(bottom: 10),
                          child: InfoBanner(
                            message:
                                'Tap any festival to edit its date. Lunar dates are estimates — update them each year; linked job deadlines recalculate on save.',
                            icon: CupertinoIcons.moon_stars,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.only(bottom: context.listBottomPadding),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == festivals.length) {
                                if (state.hasMoreFestivals) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: state.loadingMoreFestivals
                                          ? const CupertinoActivityIndicator()
                                          : CupertinoButton(
                                              onPressed: () => state.loadMoreFestivals(),
                                              child: const Text('Load More'),
                                            ),
                                    ),
                                  );
                                } else if (festivals.isNotEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text(
                                        'No more festivals',
                                        style: AppFonts.helvetica(size: 13, color: AppColors.textTertiary),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }

                              final f = festivals[index];
                              final isPast = f.date.isBefore(
                                DateTime(
                                  DateTime.now().year,
                                  DateTime.now().month,
                                  DateTime.now().day,
                                ),
                              );
                              return AppCard(
                                margin: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 5),
                                onTap: canEdit ? () => _openEditor(context, festival: f) : null,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 54,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${f.date.day}',
                                            style: AppFonts.montserrat(
                                              size: 24,
                                              weight: FontWeight.w800,
                                              color: isPast
                                                  ? AppColors.textTertiary
                                                  : AppColors.accent,
                                            ),
                                          ),
                                          Text(
                                            formatDateShort(f.date).split(' ').last.toUpperCase(),
                                            style: AppFonts.poppins(
                                              size: 12,
                                              weight: FontWeight.w700,
                                              color: isPast
                                                  ? AppColors.textTertiary
                                                  : const Color(0xFF3B5BDB),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            f.name,
                                            style: AppFonts.montserrat(
                                              size: 16,
                                              weight: FontWeight.w700,
                                              color: isPast
                                                  ? AppColors.textSecondary
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            formatDateWeekday(f.date),
                                            style: AppFonts.helvetica(size: 12),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentSoft,
                                              borderRadius: BorderRadius.circular(99),
                                            ),
                                            child: Text(
                                              f.category,
                                              style: AppFonts.poppins(
                                                size: 10,
                                                weight: FontWeight.w700,
                                                color: AppColors.accent,
                                              ),
                                            ),
                                          ),
                                          if (f.description?.isNotEmpty == true) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              f.description!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppFonts.helvetica(
                                                size: 11,
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '12',
                                          style: AppFonts.montserrat(size: 14, weight: FontWeight.w700),
                                        ),
                                        Text(
                                          'Jobs',
                                          style: AppFonts.helvetica(size: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    if (canEdit) ...[
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () => _confirmDelete(context, f),
                                        child: const Icon(
                                          CupertinoIcons.trash,
                                          size: 18,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ],
                                    const Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 16,
                                      color: AppColors.textTertiary,
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: festivals.length + 1,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {Festival? festival}) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => FestivalEditorScreen(festival: festival)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Festival festival) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete festival?'),
        content: Text('“${festival.name}” and related jobs will be removed.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AppState>().deleteFestival(festival.id);
    }
  }
}

class _AddBtn extends StatelessWidget {
  const _AddBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.add, size: 16, color: CupertinoColors.white),
            const SizedBox(width: 4),
            Text(
              'Add',
              style: AppFonts.poppins(size: 13, weight: FontWeight.w700, color: CupertinoColors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class FestivalEditorScreen extends StatefulWidget {
  const FestivalEditorScreen({super.key, this.festival});

  final Festival? festival;

  @override
  State<FestivalEditorScreen> createState() => _FestivalEditorScreenState();
}

class _FestivalEditorScreenState extends State<FestivalEditorScreen> {
  late final TextEditingController _nameCtrl;
  late DateTime _date;
  late String _category;
  bool _saving = false;
  bool _dateChanged = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.festival?.name ?? '');
    _date = Festival.dateOnly(
      widget.festival?.date ?? DateTime.now().add(const Duration(days: 30)),
    );
    _category = widget.festival?.category ?? 'Major Festival';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _date,
      title: 'Festival date',
    );
    if (picked == null || !mounted) return;
    final next = Festival.dateOnly(picked);
    final original = widget.festival != null
        ? Festival.dateOnly(widget.festival!.date)
        : null;
    setState(() {
      _date = next;
      _dateChanged = original != null &&
          (next.year != original.year ||
              next.month != original.month ||
              next.day != original.day);
    });
  }

  Future<void> _pickCategory() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Category'),
        actions: _kCategories
            .map(
              (c) => CupertinoActionSheetAction(
                onPressed: () {
                  setState(() => _category = c);
                  Navigator.pop(ctx);
                },
                child: Text(c),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Name required'),
          content: const Text('Please enter a festival name.'),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final state = context.read<AppState>();
    final existing = widget.festival;
    final eventDate = Festival.dateOnly(_date);

    try {
      if (existing != null) {
        await state.updateFestival(
          existing.copyWith(
            name: name,
            date: eventDate,
            category: _category,
            isCustom: true,
          ),
        );
      } else {
        await state.addFestival(
          name: name,
          date: eventDate,
          category: _category,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Could not save'),
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.festival != null;
    final offsets = context.watch<AppState>().deadlineConfig;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.94),
        border: null,
        middle: Text(
          isEdit ? 'Edit festival' : 'Add festival',
          style: AppFonts.montserrat(size: 17, weight: FontWeight.w700),
        ),
        trailing: NavBarActionButton(
          label: 'Save',
          icon: CupertinoIcons.checkmark_alt,
          onPressed: _saving ? null : _save,
          loading: _saving,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(context.pagePadding),
          children: [
            FormFieldBlock(
              label: 'Name',
              child: AppTextField(controller: _nameCtrl, placeholder: 'e.g. Ganesh Chaturthi'),
            ),
            const SizedBox(height: 16),
            const SectionLabel('Category'),
            const SizedBox(height: 8),
            AppCard(
              onTap: _pickCategory,
              child: Row(
                children: [
                  const IconBadge(icon: CupertinoIcons.tag, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _category,
                      style: AppFonts.poppins(size: 16, weight: FontWeight.w600),
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.textTertiary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FormFieldBlock(
              label: 'Event date',
              hint: 'Tap to pick a new date — fully editable for every festival',
              child: AppCard(
                onTap: _pickDate,
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_date.day}',
                            style: AppFonts.montserrat(
                              size: 18,
                              weight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                          Text(
                            formatDateShort(_date).split(' ').last,
                            style: AppFonts.poppins(
                              size: 10,
                              weight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatDateWeekday(_date),
                            style: AppFonts.poppins(size: 16, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to change date',
                            style: AppFonts.helvetica(
                              size: 12,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Edit',
                        style: AppFonts.poppins(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            InfoBanner(
              message: _dateChanged
                  ? 'Date changed — saving will recalculate Design / QC / Ready / Send '
                      'deadlines for all jobs linked to this festival.\n'
                      'Offsets: −${offsets.designDaysBefore} / −${offsets.qcDaysBefore} / '
                      '−${offsets.readyDaysBefore} / −${offsets.sendDaysBefore} days'
                  : 'Auto deadlines from this date:\n'
                      'Design −${offsets.designDaysBefore} · QC −${offsets.qcDaysBefore} · '
                      'Ready −${offsets.readyDaysBefore} · Send −${offsets.sendDaysBefore}',
              icon: _dateChanged
                  ? CupertinoIcons.arrow_2_circlepath
                  : CupertinoIcons.info_circle_fill,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: isEdit ? 'Save changes' : 'Add festival',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
