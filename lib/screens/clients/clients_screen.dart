import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/client.dart';
import '../../models/user_role.dart';
import '../../providers/app_state.dart';
import '../../providers/auth_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ui_kit.dart';
import '../packages/packages_screen.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final role = context.watch<AuthState>().role ?? UserRole.manager;
    final clients = state.clients;
    final canEdit = role.canManageClients;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ResponsiveContent(
          child: state.loading
              ? const Center(child: CupertinoActivityIndicator())
              : clients.isEmpty
                  ? Column(
                      children: [
                        PageHeader(
                          title: 'Clients',
                          subtitle: 'WhatsApp contacts for poster delivery',
                          trailing: canEdit ? NavBarActionButton(label: 'Add', icon: CupertinoIcons.add, onPressed: () => _openEditor(context)) : null,
                        ),
                        Expanded(
                          child: EmptyState(
                            icon: CupertinoIcons.person_2,
                            title: 'No clients yet',
                            message:
                                'Add name + WhatsApp. Optionally pick festivals to auto-create jobs.',
                            actionLabel: canEdit ? 'Add client' : null,
                            onAction: canEdit ? () => _openEditor(context) : null,
                          ),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: PageHeader(
                            title: 'Clients',
                            subtitle:
                                '${clients.length} contact${clients.length == 1 ? '' : 's'} · tap to edit',
                            trailing: canEdit ? NavBarActionButton(label: 'Add', icon: CupertinoIcons.add, onPressed: () => _openEditor(context)) : null,
                          ),
                        ),
                      SliverPadding(
                        padding: EdgeInsets.only(bottom: context.listBottomPadding),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == clients.length) {
                                if (state.hasMoreClients) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: state.loadingMoreClients
                                          ? const CupertinoActivityIndicator()
                                          : CupertinoButton(
                                              onPressed: () => state.loadMoreClients(),
                                              child: const Text('Load More'),
                                            ),
                                    ),
                                  );
                                } else if (clients.isNotEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text(
                                        'No more clients',
                                        style: AppFonts.helvetica(size: 13, color: AppColors.textTertiary),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }

                              final c = clients[index];
                              final year = DateTime.now().year;
                              final pkg = state.packageForClientYear(c.id, year);
                              final progress =
                                  pkg != null ? state.progressFor(pkg) : null;
                              return AppCard(
                                margin: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 5),
                                onTap: canEdit ? () => _openEditor(context, client: c) : null,
                                child: Row(
                                  children: [
                                    LetterAvatar(label: c.name, color: AppColors.teal),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.name,
                                            style: AppFonts.montserrat(
                                              size: 16,
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                          if (c.companyName?.isNotEmpty == true)
                                            Text(
                                              c.companyName!,
                                              style: AppFonts.poppins(
                                                size: 12,
                                                weight: FontWeight.w500,
                                                color: AppColors.accent,
                                              ),
                                            ),
                                          const SizedBox(height: 2),
                                          Text(
                                            c.whatsappNumber.isEmpty
                                                ? 'No WhatsApp'
                                                : '+${c.whatsappDigits}',
                                            style: AppFonts.helvetica(
                                              size: 13,
                                              color: c.whatsappNumber.isEmpty
                                                  ? AppColors.textTertiary
                                                  : AppColors.success,
                                            ),
                                          ),
                                          if (pkg != null) ...[
                                            const SizedBox(height: 4),
                                            GestureDetector(
                                              onTap: () => Navigator.of(context).push(
                                                CupertinoPageRoute(
                                                  builder: (_) => PackageDetailScreen(
                                                    packageId: pkg.id,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                progress == null || progress.isEmpty
                                                    ? '$year pkg · ${formatInr(pkg.price)}'
                                                    : '${formatInr(pkg.price)} · ${progress.label} delivered',
                                                style: AppFonts.poppins(
                                                  size: 11,
                                                  weight: FontWeight.w700,
                                                  color: AppColors.purple,
                                                ),
                                              ),
                                            ),
                                          ]  
                                        ],
                                      ),
                                    ),
                                    if (canEdit) ...[
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () => _confirmDelete(context, c),
                                        child: const Icon(
                                          CupertinoIcons.trash,
                                          size: 18,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                      const Icon(
                                        CupertinoIcons.chevron_right,
                                        size: 16,
                                        color: AppColors.textTertiary,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                            childCount: clients.length + 1,
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {Client? client}) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => ClientEditorScreen(client: client)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Client client) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete client?'),
        content: Text('“${client.name}” and related pipeline jobs will be removed.'),
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
      await context.read<AppState>().deleteClient(client.id);
    }
  }
}


class ClientEditorScreen extends StatefulWidget {
  const ClientEditorScreen({super.key, this.client});

  final Client? client;

  @override
  State<ClientEditorScreen> createState() => _ClientEditorScreenState();
}

class _ClientEditorScreenState extends State<ClientEditorScreen> {
  static const String _indiaCountryCode = '91';

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _packagePriceCtrl;
  late Set<String> _selectedFestivals;
  bool _saving = false;

  /// Local mobile digits only (no country code). +91 is fixed in the UI.
  static String _localPhoneDigits(String? stored) {
    if (stored == null || stored.isEmpty) return '';
    var digits = stored.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith(_indiaCountryCode) && digits.length > 10) {
      digits = digits.substring(_indiaCountryCode.length);
    }
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// Full WhatsApp number with India country code (digits only).
  static String _fullWhatsappNumber(String localInput) {
    var digits = localInput.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith(_indiaCountryCode) && digits.length > 10) {
      digits = digits.substring(_indiaCountryCode.length);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return '$_indiaCountryCode$digits';
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.client?.name ?? '');
    _phoneCtrl = TextEditingController(
      text: _localPhoneDigits(widget.client?.whatsappNumber),
    );
    _companyCtrl = TextEditingController(text: widget.client?.companyName ?? '');
    final price = widget.client?.packagePrice;
    _packagePriceCtrl = TextEditingController(
      text: price == null
          ? ''
          : (price % 1 == 0 ? price.toInt().toString() : price.toString()),
    );
    _selectedFestivals = {...?widget.client?.festivalIds};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _packagePriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Name required'),
          content: const Text('Please enter a client name.'),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final priceRaw = _packagePriceCtrl.text.replaceAll(',', '').trim();
    double? packagePrice;
    if (priceRaw.isNotEmpty) {
      packagePrice = double.tryParse(priceRaw);
      if (packagePrice == null || packagePrice < 0) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Invalid package price'),
            content: const Text('Enter a valid amount in rupees, or leave blank.'),
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
    }

    setState(() => _saving = true);
    final auth = context.read<AuthState>();
    await context.read<AppState>().saveClient(
          id: widget.client?.id,
          name: name,
          whatsappNumber: _fullWhatsappNumber(_phoneCtrl.text),
          companyName: _companyCtrl.text,
          notes: widget.client?.notes ?? '',
          festivalIds: _selectedFestivals.toList(),
          packagePrice: packagePrice,
          syncAssignments: true,
          createdByUid: auth.user?.id,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.client != null;
    final festivals = context.watch<AppState>().festivals;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.94),
        border: null,
        middle: Text(
          isEdit ? 'Edit client' : 'New client',
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
              child: AppTextField(controller: _nameCtrl, placeholder: 'Client or business name'),
            ),
            const SizedBox(height: 16),
            FormFieldBlock(
              label: 'Company (optional)',
              child: AppTextField(controller: _companyCtrl, placeholder: 'Company name'),
            ),
            const SizedBox(height: 16),
            FormFieldBlock(
              label: 'WhatsApp number',
              hint: 'Country code +91 is fixed. Enter 10-digit mobile number.',
              child: AppTextField(
                controller: _phoneCtrl,
                placeholder: '9876543210',
                keyboardType: TextInputType.phone,
                prefix: Text(
                  '+$_indiaCountryCode',
                  style: AppFonts.poppins(
                    size: 15,
                    weight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                onChanged: (value) {
                  // Keep only digits; user cannot type/remove country code.
                  final digits = value.replaceAll(RegExp(r'[^\d]'), '');
                  final limited =
                      digits.length > 10 ? digits.substring(0, 10) : digits;
                  if (limited != value) {
                    _phoneCtrl.value = TextEditingValue(
                      text: limited,
                      selection: TextSelection.collapsed(offset: limited.length),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            FormFieldBlock(
              label: 'Package price (₹)',
              hint: isEdit
                  ? 'Client-specific yearly package price. Updates the active package.'
                  : 'Different per client. Creates a 1-year package from today; renewal alert 15 days before.',
              child: AppTextField(
                controller: _packagePriceCtrl,
                placeholder: 'e.g. 50000',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefix: Text(
                  '₹',
                  style: AppFonts.poppins(
                    size: 15,
                    weight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionLabel('Festival packages'),
                if (festivals.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedFestivals.length == festivals.length) {
                          _selectedFestivals.clear();
                        } else {
                          _selectedFestivals = festivals.map((f) => f.id).toSet();
                        }
                      });
                    },
                    child: Text(
                      _selectedFestivals.length == festivals.length
                          ? 'Deselect all'
                          : 'Select all',
                      style: AppFonts.helvetica(
                        size: 13,
                        color: AppColors.accent,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Optional — creates pipeline jobs when saved',
              style: AppFonts.helvetica(size: 12, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 10),
            if (festivals.isEmpty)
              Text('No festivals yet.', style: AppFonts.helvetica(size: 13))
            else
              ...festivals.map((f) {
                final selected = _selectedFestivals.contains(f.id);
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  highlightColor: selected ? AppColors.accent : null,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedFestivals.remove(f.id);
                      } else {
                        _selectedFestivals.add(f.id);
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        selected ? CupertinoIcons.checkmark_square_fill : CupertinoIcons.square,
                        color: selected ? AppColors.accent : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f.name,
                          style: AppFonts.poppins(size: 15, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
            PrimaryButton(
              label: isEdit ? 'Save changes' : 'Create client',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
