import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../providers/auth_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ui_kit.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final users = auth.team;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(backgroundColor: Color(0x00000000), border: null, leading: AppBackButton(margin: EdgeInsets.only(left: 8))),
      child: SafeArea(
        bottom: false,
        child: ResponsiveContent(
          child: users.isEmpty
              ? Column(
                  children: [
                    PageHeader(
                      title: 'Team',
                      subtitle: 'Designer · Manager accounts',
                      trailing: NavBarActionButton(
                        label: 'Add',
                        icon: CupertinoIcons.add,
                        onPressed: () => _openCreate(context),
                      ),
                    ),
                    Expanded(
                      child: EmptyState(
                        icon: CupertinoIcons.person_3,
                        title: 'No team members',
                        message: 'Create accounts for your team. They sign in with username & password.',
                        actionLabel: 'Add user',
                        onAction: () => _openCreate(context),
                      ),
                    ),
                  ],
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: PageHeader(
                        title: 'Team',
                        subtitle: '${users.length} account${users.length == 1 ? '' : 's'} · Admin only',
                        trailing: NavBarActionButton(
                          label: 'Add',
                          icon: CupertinoIcons.add,
                          onPressed: () => _openCreate(context),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: context.listBottomPadding),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final u = users[index];
                            return _UserTile(
                              user: u,
                              isSelf: u.id == auth.user?.id,
                              onResetPassword: () => _resetPassword(context, u),
                              onToggleActive: () => _toggleActive(context, u),
                            );
                          },
                          childCount: users.length,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => const CreateUserScreen()),
    );
  }

  Future<void> _resetPassword(BuildContext context, AppUser user) async {
    final ctrl = TextEditingController();
    bool obscure = true;
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('Reset password'),
          content: Column(
            children: [
              const SizedBox(height: 8),
              Text('New password for ${user.username}'),
              const SizedBox(height: 12),
              AppTextField(
                controller: ctrl,
                placeholder: 'Min 6 characters',
                obscureText: obscure,
                suffix: CupertinoButton(
                  padding: const EdgeInsets.only(right: 8),
                  onPressed: () => setState(() => obscure = !obscure),
                  child: Icon(
                    obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await context.read<AuthState>().setPassword(user.id, ctrl.text);
      } catch (e) {
        if (context.mounted) {
          await showCupertinoDialog<void>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: [
                CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              ],
            ),
          );
        }
      }
    }
    ctrl.dispose();
  }

  Future<void> _toggleActive(BuildContext context, AppUser user) async {
    final auth = context.read<AuthState>();
    try {
      if (user.isActive) {
        await auth.deactivateUser(user.id);
      } else {
        await auth.reactivateUser(user.id);
      }
    } catch (e) {
      if (context.mounted) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(
              e.toString().replaceFirst('Bad state: ', '').replaceFirst('Invalid argument(s): ', ''),
            ),
            actions: [
              CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.isSelf,
    required this.onResetPassword,
    required this.onToggleActive,
  });

  final AppUser user;
  final bool isSelf;
  final VoidCallback onResetPassword;
  final VoidCallback onToggleActive;

  Color get _roleColor {
    switch (user.role) {
      case UserRole.admin:
        return AppColors.accent;
      case UserRole.designer:
        return AppColors.warning;
      case UserRole.manager:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 5),
      child: Row(
        children: [
          LetterAvatar(label: user.displayName, color: _roleColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: AppFonts.montserrat(size: 15, weight: FontWeight.w700),
                ),
                Text(
                  '@${user.username}${isSelf ? ' · you' : ''}',
                  style: AppFonts.helvetica(size: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    user.role.label,
                    style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: _roleColor),
                  ),
                ),
                if (!user.isActive) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Inactive',
                    style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: AppColors.overdue),
                  ),
                ],
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onPressed: onResetPassword,
            child: const Icon(CupertinoIcons.lock_rotation, size: 20, color: AppColors.textTertiary),
          ),
          if (!isSelf)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed: onToggleActive,
              child: Icon(
                user.isActive ? CupertinoIcons.person_badge_minus : CupertinoIcons.person_badge_plus,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  UserRole _role = UserRole.designer;
  bool _saving = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthState>().createUser(
            username: _userCtrl.text,
            email: _emailCtrl.text,
            displayName: _nameCtrl.text,
            password: _passCtrl.text,
            role: _role,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      final msg =
          e.toString().replaceFirst('Bad state: ', '').replaceFirst('Invalid argument(s): ', '');
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Could not create user'),
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
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(leading: const AppBackButton(margin: EdgeInsets.only(left: 8)), 
        backgroundColor: AppColors.background.withValues(alpha: 0.94),
        border: null,
        middle: Text(
          'New account',
          style: AppFonts.montserrat(size: 17, weight: FontWeight.w700),
        ),
        trailing: NavBarActionButton(
          label: 'Create',
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
              label: 'Display name',
              child: AppTextField(controller: _nameCtrl, placeholder: 'e.g. Priya Sharma'),
            ),
            const SizedBox(height: 16),
            FormFieldBlock(
              label: 'Username',
              child: AppTextField(
                controller: _userCtrl,
                placeholder: 'e.g. priya',
                autocorrect: false,
              ),
            ),
            const SizedBox(height: 16),
            FormFieldBlock(
              label: 'Email',
              child: AppTextField(
                controller: _emailCtrl,
                placeholder: 'e.g. priya@tsp.com',
                autocorrect: false,
              ),
            ),
            const SizedBox(height: 16),
            FormFieldBlock(
              label: 'Temporary password',
              hint: 'Min 6 characters',
              child: StatefulBuilder(
                builder: (context, setState) {
                  bool obscure = true;
                  return AppTextField(
                    controller: _passCtrl,
                    placeholder: '••••••••',
                    obscureText: obscure,
                    suffix: CupertinoButton(
                      padding: const EdgeInsets.only(right: 8),
                      onPressed: () => setState(() => obscure = !obscure),
                      child: Icon(
                        obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                        size: 20,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const SectionLabel('Role'),
            const SizedBox(height: 8),
            ...UserRole.values.map((r) {
              final selected = _role == r;
              return AppCard(
                margin: const EdgeInsets.only(bottom: 8),
                highlightColor: selected ? AppColors.accent : null,
                onTap: () => setState(() => _role = r),
                child: Row(
                  children: [
                    Icon(
                      selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                      color: selected ? AppColors.accent : AppColors.textTertiary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.label, style: AppFonts.montserrat(size: 15, weight: FontWeight.w700)),
                          Text(_roleHint(r), style: AppFonts.helvetica(size: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Create account',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  String _roleHint(UserRole r) {
    switch (r) {
      case UserRole.admin:
        return 'Full access · team · settings';
      case UserRole.designer:
        return 'Attach poster links · advance design stages';
      case UserRole.manager:
        return 'Clients · assign · WhatsApp send';
    }
  }
}



