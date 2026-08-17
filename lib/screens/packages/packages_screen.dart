import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/client_package.dart';
import '../../models/user_role.dart';
import '../../providers/app_state.dart';
import '../../providers/auth_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ui_kit.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  Future<void> _openCreateAll() async {
    final result = await showCupertinoModalPopup<_CreatePackageResult>(
      context: context,
      builder: (ctx) => _CreateAllPackagesSheet(initialYear: _year),
    );
    if (result == null || !mounted) return;

    final auth = context.read<AuthState>();
    final state = context.read<AppState>();
    final outcome = await state.createYearPackagesForAllClients(
      year: result.year,
      price: result.price,
      createdByUid: auth.user?.id,
      byRole: auth.role,
    );

    if (!mounted) return;
    setState(() => _year = result.year);

    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Packages created'),
        content: Text(
          outcome.created == 0
              ? 'All clients already have a ${result.year} package.'
              : 'Created ${outcome.created} package(s) at ${formatInr(result.price)}.\n'
                  'Skipped ${outcome.skipped} (already had this year).',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final role = context.watch<AuthState>().role ?? UserRole.manager;
    final packages = state.packagesForYear(_year)
      ..sort((a, b) {
        final nameA = state.clientById(a.clientId)?.name.toLowerCase() ?? '';
        final nameB = state.clientById(b.clientId)?.name.toLowerCase() ?? '';
        return nameA.compareTo(nameB);
      });
    final canManage = role.canManagePackages;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ResponsiveContent(
          child: state.loading
              ? const Center(child: CupertinoActivityIndicator())
              : packages.isEmpty
                  ? Column(
                      children: [
                        PageHeader(
                          title: 'Packages',
                          subtitle: '$_year · 1-year festival poster packages',
                          trailing: canManage
                              ? NavBarActionButton(
                                  label: 'Create',
                                  icon: CupertinoIcons.add,
                                  onPressed: _openCreateAll,
                                )
                              : null,
                        ),
                        _YearFilter(
                          year: _year,
                          onChanged: (y) => setState(() => _year = y),
                        ),
                        Expanded(
                          child: EmptyState(
                            icon: CupertinoIcons.cube_box,
                            title: 'No packages for $_year',
                            message: canManage
                                ? 'Create a 1-year package for all clients with one price.'
                                : 'Admin has not created packages for this year yet.',
                            actionLabel:
                                canManage ? 'Create for all clients' : null,
                            onAction: canManage ? _openCreateAll : null,
                          ),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: PageHeader(
                            title: 'Packages',
                            subtitle:
                                '${packages.length} client${packages.length == 1 ? '' : 's'} · $_year',
                            trailing: canManage
                                ? NavBarActionButton(
                                    label: 'Create',
                                    icon: CupertinoIcons.add,
                                    onPressed: _openCreateAll,
                                  )
                                : null,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _YearFilter(
                            year: _year,
                            onChanged: (y) => setState(() => _year = y),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.only(
                            bottom: context.listBottomPadding,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == packages.length) {
                                  if (state.hasMorePackages) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      child: Center(
                                        child: state.loadingMorePackages
                                            ? const CupertinoActivityIndicator()
                                            : CupertinoButton(
                                                onPressed: () =>
                                                    state.loadMorePackages(),
                                                child: const Text('Load More'),
                                              ),
                                      ),
                                    );
                                  } else if (packages.isNotEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20),
                                      child: Center(
                                        child: Text(
                                          'No more packages',
                                          style: AppFonts.helvetica(
                                              size: 13,
                                              color: AppColors.textTertiary),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }

                                final pkg = packages[index];
                                final client = state.clientById(pkg.clientId);
                                final progress = state.progressFor(pkg);
                                final days = pkg.daysUntilRenewal();
                                return AppCard(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: context.pagePadding,
                                    vertical: 5,
                                  ),
                                  onTap: () => Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (_) => PackageDetailScreen(
                                        packageId: pkg.id,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      LetterAvatar(
                                        label: client?.name ?? '?',
                                        color: pkg.isStopped
                                            ? AppColors.textTertiary
                                            : AppColors.purple,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              client?.name ?? 'Unknown client',
                                              style: AppFonts.montserrat(
                                                size: 16,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              formatInr(pkg.price),
                                              style: AppFonts.poppins(
                                                size: 14,
                                                weight: FontWeight.w600,
                                                color: AppColors.accent,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              pkg.isStopped
                                                  ? 'Stopped'
                                                  : progress.isEmpty
                                                      ? (days != null
                                                          ? 'Renews in $days day(s)'
                                                          : 'Active package')
                                                      : '${progress.label} posters · ${pkg.paymentStatus.label}',
                                              style: AppFonts.helvetica(
                                                size: 12,
                                                color: pkg.isStopped
                                                    ? AppColors.overdue
                                                    : (pkg.isRenewalDueSoon()
                                                        ? AppColors.warning
                                                        : AppColors.textSecondary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _ProgressChip(
                                        label: pkg.isStopped
                                            ? 'Stop'
                                            : (progress.isEmpty
                                                ? pkg.paymentStatus.label
                                                : progress.label),
                                        complete: pkg.isPaid && !pkg.isStopped,
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        CupertinoIcons.chevron_right,
                                        size: 16,
                                        color: AppColors.textTertiary,
                                      ),
                                    ],
                                  ),
                                );
                              },
                              childCount: packages.length + 1,
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _YearFilter extends StatelessWidget {
  const _YearFilter({required this.year, required this.onChanged});

  final int year;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    final years = [now - 1, now, now + 1];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.pagePadding,
        0,
        context.pagePadding,
        10,
      ),
      child: Row(
        children: years.map((y) {
          final selected = y == year;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(y),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color:
                        selected ? AppColors.accent : AppColors.borderSubtle,
                  ),
                ),
                child: Text(
                  '$y',
                  style: AppFonts.poppins(
                    size: 13,
                    weight: FontWeight.w700,
                    color: selected
                        ? CupertinoColors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({required this.label, required this.complete});

  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: complete ? AppColors.success.withValues(alpha: 0.12) : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppFonts.poppins(
          size: 12,
          weight: FontWeight.w700,
          color: complete ? AppColors.success : AppColors.accent,
        ),
      ),
    );
  }
}

class _CreatePackageResult {
  const _CreatePackageResult({required this.year, required this.price});
  final int year;
  final double price;
}

class _CreateAllPackagesSheet extends StatefulWidget {
  const _CreateAllPackagesSheet({required this.initialYear});
  final int initialYear;

  @override
  State<_CreateAllPackagesSheet> createState() =>
      _CreateAllPackagesSheetState();
}

class _CreateAllPackagesSheetState extends State<_CreateAllPackagesSheet> {
  late int _year;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _priceCtrl = TextEditingController(text: '50000');
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _priceCtrl.text.replaceAll(',', '').trim();
    final price = double.tryParse(raw);
    if (price == null || price < 0) {
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Invalid price'),
          content: const Text('Enter a valid amount in rupees.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.pop(context, _CreatePackageResult(year: _year, price: price));
  }

  @override
  Widget build(BuildContext context) {
    final clientCount = context.watch<AppState>().clients.length;
    final now = DateTime.now().year;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.paddingOf(context).bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Create 1-year packages',
            style: AppFonts.montserrat(size: 18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Applies one price to all $clientCount client(s). '
            'Clients who already have this year are skipped.',
            style: AppFonts.helvetica(size: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          const SectionLabel('Year'),
          const SizedBox(height: 8),
          Row(
            children: [now - 1, now, now + 1].map((y) {
              final selected = y == _year;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _year = y),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accentSoft
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.accent
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Text(
                      '$y',
                      style: AppFonts.poppins(
                        size: 15,
                        weight: FontWeight.w700,
                        color: selected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          FormFieldBlock(
            label: 'Package price (₹)',
            hint:
                'Same price for every client; edit later per client if needed.',
            child: AppTextField(
              controller: _priceCtrl,
              placeholder: '50000',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Create for all clients',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ── Detail ───────────────────────────────────────────────────────────────────

class PackageDetailScreen extends StatelessWidget {
  const PackageDetailScreen({super.key, required this.packageId});

  final String packageId;

  ClientPackage? _pkg(AppState state) {
    try {
      return state.clientPackages.firstWhere((p) => p.id == packageId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _editPrice(BuildContext context, ClientPackage pkg) async {
    final priceCtrl = TextEditingController(
      text: pkg.price % 1 == 0
          ? pkg.price.toInt().toString()
          : pkg.price.toString(),
    );
    final noteCtrl = TextEditingController();

    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Update package price'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: priceCtrl,
              placeholder: 'New price',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text('₹'),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: noteCtrl,
              placeholder: 'Note (optional)',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) {
      priceCtrl.dispose();
      noteCtrl.dispose();
      return;
    }

    final price = double.tryParse(priceCtrl.text.replaceAll(',', '').trim());
    final note = noteCtrl.text.trim();
    priceCtrl.dispose();
    noteCtrl.dispose();

    if (price == null || price < 0) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Invalid price'),
          content: const Text('Enter a valid amount.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final auth = context.read<AuthState>();
    final state = context.read<AppState>();
    await state.updatePackagePrice(
      pkg,
      newPrice: price,
      note: note.isEmpty ? null : note,
      changedByUid: auth.user?.id,
      byRole: auth.role,
    );
    // Keep client package price aligned.
    final client = state.clientById(pkg.clientId);
    if (client != null) {
      await state.saveClient(
        id: client.id,
        name: client.name,
        whatsappNumber: client.whatsappNumber,
        companyName: client.companyName,
        notes: client.notes,
        festivalIds: client.festivalIds,
        packagePrice: price,
        createPackageIfNew: false,
        createdByUid: auth.user?.id,
      );
    }
  }

  Future<void> _alert(BuildContext context, String title, String msg) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _markPaid(BuildContext context, ClientPackage pkg) async {
    await context.read<AppState>().markPackagePaymentReceived(pkg);
    if (context.mounted) {
      await _alert(context, 'Payment received',
          'Payment marked. You can renew the package for another year.');
    }
  }

  Future<void> _renew(BuildContext context, ClientPackage pkg) async {
    try {
      await context.read<AppState>().renewClientPackage(pkg);
      if (context.mounted) {
        await _alert(context, 'Package renewed',
            'Package extended by 1 year. Next renewal is based on the new end date.');
      }
    } catch (e) {
      if (context.mounted) {
        await _alert(
          context,
          'Cannot renew',
          e.toString().replaceFirst('Bad state: ', ''),
        );
      }
    }
  }

  Future<void> _stop(BuildContext context, ClientPackage pkg) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Stop package?'),
        content: const Text(
          'Use this when payment is not received. '
          'The package will be stopped until payment is collected and reactivated.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Stop package'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<AppState>().stopClientPackage(pkg);
  }

  Future<void> _reactivate(BuildContext context, ClientPackage pkg) async {
    await context.read<AppState>().reactivateClientPackage(pkg);
    if (context.mounted) {
      await _alert(context, 'Package reactivated',
          'Payment recorded and package restarted for 1 year from today.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final role = context.watch<AuthState>().role ?? UserRole.manager;
    final pkg = _pkg(state);

    if (pkg == null) {
      return CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Package'),
        ),
        child: const Center(child: Text('Package not found')),
      );
    }

    final client = state.clientById(pkg.clientId);
    final progress = state.progressFor(pkg);
    final history = state.priceHistoryFor(pkg.id);
    final canManage = role.canManagePackages;
    final days = pkg.daysUntilRenewal();
    final canPay = canManage && !pkg.isPaid;
    final canRenew = canManage && pkg.isPaid && !pkg.isStopped;
    final canStop = canManage && pkg.isActive;
    final canReactivate = canManage && pkg.isStopped;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.94),
        border: null,
        middle: Text(
          '${pkg.year} package',
          style: AppFonts.montserrat(size: 17, weight: FontWeight.w700),
        ),
        trailing: canManage
            ? NavBarActionButton(
                label: 'Price',
                icon: CupertinoIcons.money_dollar,
                onPressed: () => _editPrice(context, pkg),
              )
            : null,
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(context.pagePadding),
          children: [
            Text(
              client?.name ?? 'Unknown client',
              style: AppFonts.montserrat(size: 22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              pkg.isStopped
                  ? 'Stopped package'
                  : (pkg.endDate != null
                      ? 'Active until ${formatDate(pkg.endDate!)}'
                      : 'Year ${pkg.year}'),
              style: AppFonts.helvetica(
                size: 14,
                color: pkg.isStopped
                    ? AppColors.overdue
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Row(
                children: [
                  const IconBadge(
                    icon: CupertinoIcons.money_dollar_circle,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Package price',
                          style: AppFonts.helvetica(
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Text(
                          formatInr(pkg.price),
                          style: AppFonts.montserrat(
                            size: 24,
                            weight: FontWeight.w800,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canManage)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _editPrice(context, pkg),
                      child: Text(
                        'Edit',
                        style: AppFonts.poppins(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              highlightColor: pkg.isStopped
                  ? AppColors.overdue
                  : (pkg.isPaid ? AppColors.success : AppColors.warning),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        pkg.isStopped
                            ? CupertinoIcons.pause_circle_fill
                            : (pkg.isPaid
                                ? CupertinoIcons.checkmark_seal_fill
                                : CupertinoIcons.money_dollar_circle),
                        color: pkg.isStopped
                            ? AppColors.overdue
                            : (pkg.isPaid
                                ? AppColors.success
                                : AppColors.warning),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          pkg.isStopped
                              ? 'Stopped'
                              : pkg.paymentStatus.label,
                          style: AppFonts.poppins(
                            size: 16,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (days != null && pkg.isActive)
                        Text(
                          days < 0
                              ? 'Expired ${-days}d ago'
                              : days == 0
                                  ? 'Renews today'
                                  : 'Renews in ${days}d',
                          style: AppFonts.helvetica(
                            size: 12,
                            color: days <= 15
                                ? AppColors.warning
                                : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  if (pkg.startDate != null && pkg.endDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${formatDate(pkg.startDate!)} → ${formatDate(pkg.endDate!)}',
                      style: AppFonts.helvetica(
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (pkg.paymentReceivedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Paid · ${formatDateTimeShort(pkg.paymentReceivedAt!)}',
                      style: AppFonts.helvetica(
                        size: 12,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                  if (pkg.isRenewalDueSoon()) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Renewal window open (15 days). Collect payment, then renew — or stop if unpaid.',
                      style: AppFonts.helvetica(
                        size: 12,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: 14),
              if (canPay)
                PrimaryButton(
                  label: 'Payment received',
                  icon: CupertinoIcons.checkmark_circle,
                  color: AppColors.success,
                  onPressed: () => _markPaid(context, pkg),
                ),
              if (canPay) const SizedBox(height: 10),
              if (canRenew)
                PrimaryButton(
                  label: 'Renew package (1 year)',
                  icon: CupertinoIcons.arrow_2_circlepath,
                  onPressed: () => _renew(context, pkg),
                ),
              if (canRenew) const SizedBox(height: 10),
              if (canStop)
                PrimaryButton(
                  label: 'Stop package (payment not received)',
                  icon: CupertinoIcons.stop_circle,
                  color: AppColors.overdue,
                  onPressed: () => _stop(context, pkg),
                ),
              if (canReactivate)
                PrimaryButton(
                  label: 'Payment received & reactivate',
                  icon: CupertinoIcons.play_circle_fill,
                  color: AppColors.success,
                  onPressed: () => _reactivate(context, pkg),
                ),
            ],
            const SizedBox(height: 12),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery progress',
                          style: AppFonts.helvetica(
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          progress.isEmpty
                              ? 'No jobs in ${pkg.year}'
                              : '${progress.label} posters delivered',
                          style: AppFonts.poppins(
                            size: 16,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    progress.isEmpty
                        ? '—'
                        : '${(progress.ratio * 100).round()}%',
                    style: AppFonts.montserrat(
                      size: 20,
                      weight: FontWeight.w800,
                      color: progress.isComplete
                          ? AppColors.success
                          : AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionLabel('Poster delivery checklist'),
            const SizedBox(height: 6),
            Text(
              'Auto-ticks when a poster is marked Sent (WhatsApp or status).',
              style:
                  AppFonts.helvetica(size: 12, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 10),
            if (progress.isEmpty)
              AppCard(
                child: Text(
                  'No assigned festivals in ${pkg.year} for this client. '
                  'Assign festivals on the client or create pipeline jobs.',
                  style: AppFonts.helvetica(
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ...progress.items.map((item) {
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  highlightColor: item.delivered ? AppColors.success : null,
                  child: Row(
                    children: [
                      Icon(
                        item.delivered
                            ? CupertinoIcons.checkmark_square_fill
                            : CupertinoIcons.square,
                        color: item.delivered
                            ? AppColors.success
                            : AppColors.textTertiary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.festivalName,
                              style: AppFonts.poppins(
                                size: 15,
                                weight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              formatDateWeekday(item.festivalDate),
                              style: AppFonts.helvetica(size: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.delivered
                                  ? (item.sentAt != null
                                      ? 'Delivered · ${formatDateTimeShort(item.sentAt!)}'
                                      : 'Delivered')
                                  : 'Pending · ${item.status.label}',
                              style: AppFonts.helvetica(
                                size: 12,
                                color: item.delivered
                                    ? AppColors.success
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 22),
            const SectionLabel('Price history'),
            const SizedBox(height: 10),
            if (history.isEmpty)
              AppCard(
                child: Text(
                  'No price changes recorded yet.',
                  style: AppFonts.helvetica(
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ...history.map((h) {
                final isInitial = h.previousPrice == null;
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isInitial
                                  ? formatInr(h.price)
                                  : '${formatInr(h.previousPrice!)} → ${formatInr(h.price)}',
                              style: AppFonts.poppins(
                                size: 15,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            formatDateTimeShort(h.changedAt),
                            style: AppFonts.helvetica(
                              size: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      if (h.note != null && h.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          h.note!,
                          style: AppFonts.helvetica(
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (h.changedByRole != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'By ${h.changedByRole}',
                          style: AppFonts.helvetica(
                            size: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
