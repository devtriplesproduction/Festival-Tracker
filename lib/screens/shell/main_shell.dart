import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Badge,
        Colors,
        InkWell,
        Material,
        NavigationRail,
        NavigationRailDestination,
        NavigationRailLabelType,
        VerticalDivider;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../providers/app_state.dart';
import '../../providers/auth_state.dart';
import '../../core/services/onesignal_service.dart';
import '../../widgets/ui_kit.dart';
import '../alerts/alerts_screen.dart';
import '../festivals/festivals_screen.dart';
import '../management/studio_management_screen.dart';
import '../pipeline/pipeline_screen.dart';

/// Role-aware shell: bottom tabs on phones, side rail on tablets.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthState>().user;
      if (user != null) {
        try {
          context.read<OneSignalService>().login(user.id);
        } catch (_) {
          // OneSignalService might not be provided in local mode
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthState>().user?.id ?? '';
    final role = context.watch<AuthState>().role ?? UserRole.designer;
    final unread = context.watch<AppState>().unreadNotificationsCount(uid, role);
    final tabs = _tabsFor(role, unread);

    // Keep index in range when role changes tab count.
    if (_index >= tabs.length) {
      _index = 0;
    }

    final useRail = context.isTablet && context.screenWidth >= 700;

    if (useRail) {
      return _TabletShell(
        tabs: tabs,
        index: _index,
        onSelect: (i) => setState(() => _index = i),
      );
    }

    return CupertinoTabScaffold(
      backgroundColor: AppColors.background,
      tabBar: CupertinoTabBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.96),
        activeColor: AppColors.accent,
        inactiveColor: AppColors.textTertiary,
        height: context.screenWidth < 360 ? 50 : 54,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 0.6),
        ),
        items: tabs.map((t) => t.item).toList(),
      ),
      tabBuilder: (context, index) {
        final safe = index.clamp(0, tabs.length - 1);
        return CupertinoTabView(
          builder: (_) => ResponsiveContent(
            child: tabs[safe].builder(context),
          ),
        );
      },
    );
  }

  List<_TabSpec> _tabsFor(UserRole role, int unreadAlerts) {
    final list = <_TabSpec>[
      _TabSpec(
        item: const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.square_list),
          activeIcon: Icon(CupertinoIcons.square_list_fill),
          label: 'Pipeline',
        ),
        railIcon: CupertinoIcons.square_list,
        railSelectedIcon: CupertinoIcons.square_list_fill,
        label: 'Pipeline',
        builder: (_) => const PipelineScreen(),
      ),
    ];

    if (role.canManageFestivals || role == UserRole.designer) {
      list.add(
        _TabSpec(
          item: const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar),
            activeIcon: Icon(CupertinoIcons.calendar_today),
            label: 'Festivals',
          ),
          railIcon: CupertinoIcons.calendar,
          railSelectedIcon: CupertinoIcons.calendar_today,
          label: 'Festivals',
          builder: (_) => const FestivalsScreen(),
        ),
      );
    }

    list.add(
      _TabSpec(
        item: BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: unreadAlerts > 0,
            backgroundColor: AppColors.overdue,
            label: Text(
              '$unreadAlerts',
              style: const TextStyle(fontSize: 10, color: Color(0xFFFFFFFF)),
            ),
            child: const Icon(CupertinoIcons.bell),
          ),
          activeIcon: Badge(
            isLabelVisible: unreadAlerts > 0,
            backgroundColor: AppColors.overdue,
            label: Text(
              '$unreadAlerts',
              style: const TextStyle(fontSize: 10, color: Color(0xFFFFFFFF)),
            ),
            child: const Icon(CupertinoIcons.bell_fill),
          ),
          label: 'Alerts',
        ),
        railIcon: CupertinoIcons.bell,
        railSelectedIcon: CupertinoIcons.bell_fill,
        label: 'Alerts',
        badgeCount: unreadAlerts,
        builder: (_) => const AlertsScreen(),
      ),
    );

    list.add(
      _TabSpec(
        item: const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person_crop_circle),
          activeIcon: Icon(CupertinoIcons.person_crop_circle_fill),
          label: 'Account',
        ),
        railIcon: CupertinoIcons.person_crop_circle,
        railSelectedIcon: CupertinoIcons.person_crop_circle_fill,
        label: 'Account',
        builder: (_) => const AccountScreen(),
      ),
    );

    return list;
  }
}

class _TabletShell extends StatelessWidget {
  const _TabletShell({
    required this.tabs,
    required this.index,
    required this.onSelect,
  });

  final List<_TabSpec> tabs;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final extended = context.screenWidth >= 1000;

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: extended,
              backgroundColor: AppColors.surface,
              selectedIndex: index,
              onDestinationSelected: onSelect,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: AppColors.accent),
              unselectedIconTheme: const IconThemeData(color: AppColors.textTertiary),
              selectedLabelTextStyle: AppFonts.poppins(
                size: 12,
                weight: FontWeight.w600,
                color: AppColors.accent,
              ),
              unselectedLabelTextStyle: AppFonts.poppins(
                size: 12,
                color: AppColors.textTertiary,
              ),
              indicatorColor: AppColors.accentSoft,
              minWidth: 72,
              minExtendedWidth: 200,
              destinations: [
                for (final t in tabs)
                  NavigationRailDestination(
                    icon: t.badgeCount > 0
                        ? Badge(
                            backgroundColor: AppColors.overdue,
                            label: Text(
                              '${t.badgeCount}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFFFFFFFF)),
                            ),
                            child: Icon(t.railIcon),
                          )
                        : Icon(t.railIcon),
                    selectedIcon: t.badgeCount > 0
                        ? Badge(
                            backgroundColor: AppColors.overdue,
                            label: Text(
                              '${t.badgeCount}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFFFFFFFF)),
                            ),
                            child: Icon(t.railSelectedIcon),
                          )
                        : Icon(t.railSelectedIcon),
                    label: Text(t.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),
            Expanded(
              child: ResponsiveContent(
                child: tabs[index].builder(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSpec {
  _TabSpec({
    required this.item,
    required this.builder,
    required this.railIcon,
    required this.railSelectedIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final BottomNavigationBarItem item;
  final WidgetBuilder builder;
  final IconData railIcon;
  final IconData railSelectedIcon;
  final String label;
  final int badgeCount;
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final app = context.watch<AppState>();
    final user = auth.user;
    final role = auth.role ?? UserRole.designer;
    final stats = app.stats;
    final p = context.pagePadding;

    final canManageAny = role.canViewClients ||
        role.canViewPackages ||
        role.canManageTeam ||
        role.canManageSettings;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: ResponsiveContent(
          maxWidth: 760,
          child: ListView(
            padding: EdgeInsets.fromLTRB(0, 8, 0, context.listBottomPadding),
            children: [
              const PageHeader(
                title: 'Account',
                subtitle: 'Profile, workspace settings, and security',
              ),
              SizedBox(height: context.sectionGap * 0.4),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: p),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Premium User Profile Card
                    Container(
                      padding: EdgeInsets.all(context.isCompact ? 20 : 26),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accent,
                            Color(0xFF88003E),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: context.isCompact ? 64 : 76,
                            height: context.isCompact ? 64 : 76,
                            decoration: BoxDecoration(
                              color: const Color(0x28FFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0x66FFFFFF),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (user?.displayName.isNotEmpty == true)
                                  ? user!.displayName[0].toUpperCase()
                                  : '?',
                              style: AppFonts.montserrat(
                                size: context.isCompact ? 28 : 34,
                                weight: FontWeight.w800,
                                color: const Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.displayName ?? 'User',
                                  style: AppFonts.montserrat(
                                    size: context.isCompact ? 20 : 22,
                                    weight: FontWeight.w800,
                                    color: const Color(0xFFFFFFFF),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0x33FFFFFF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '@${user?.username ?? ''}',
                                        style: AppFonts.poppins(
                                          size: 11.5,
                                          weight: FontWeight.w600,
                                          color: const Color(0xFFFFFFFF),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFFFF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        user?.role.label ?? '',
                                        style: AppFonts.montserrat(
                                          size: 11,
                                          weight: FontWeight.w800,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Key Pipeline Metrics Row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider, width: 1.2),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        children: [
                          _miniStat('${stats.total}', 'Jobs',
                              color: const Color(0xFF0284C7),
                              bgColor: const Color(0xFFE0F2FE)),
                          _miniStat('${stats.overdueCount}', 'Overdue',
                              color: AppColors.overdue,
                              bgColor: const Color(0xFFFEF2F2)),
                          _miniStat('${stats.readyToSend}', 'Ready',
                              color: const Color(0xFF16A34A),
                              bgColor: const Color(0xFFDCFCE7)),
                          _miniStat('${stats.sent}', 'Sent',
                              color: const Color(0xFF9333EA),
                              bgColor: const Color(0xFFF3E8FF)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section 1: Studio Operations (Consolidated Management Hub)
                    if (canManageAny) ...[
                      Text(
                        'OPERATIONS & STUDIO',
                        style: AppFonts.montserrat(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ModernCardTile(
                        icon: CupertinoIcons.square_grid_2x2_fill,
                        title: 'Studio Management',
                        subtitle: 'Clients, Packages, Poster Gallery, Team & Deadlines',
                        badge: '5 Modules',
                        badgeColor: AppColors.accent,
                        iconColor: AppColors.accent,
                        iconBgGradient: const [Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => const StudioManagementScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Section 2: Security & Preferences
                    Text(
                      'SECURITY & PREFERENCES',
                      style: AppFonts.montserrat(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _ModernCardTile(
                      icon: CupertinoIcons.lock_shield_fill,
                      title: 'Update Password',
                      subtitle: 'Change your login credentials & account security',
                      iconColor: const Color(0xFF4F46E5),
                      iconBgGradient: const [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                      onTap: () {
                        if (user != null) {
                          _updatePassword(context, user);
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    _ModernCardTile(
                      icon: CupertinoIcons.lightbulb_fill,
                      title: 'How It Works',
                      subtitle: 'Production workflow: Festival → Deadlines → QC → WhatsApp',
                      iconColor: const Color(0xFFD97706),
                      iconBgGradient: const [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                      onTap: () {
                        showCupertinoDialog<void>(
                          context: context,
                          builder: (ctx) => CupertinoAlertDialog(
                            title: const Text('Production Workflow Guide'),
                            content: const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                '1. Manage festivals & add clients in Studio\n'
                                '2. Assign client × festival in Pipeline\n'
                                '3. Designer uploads Google Drive poster URL\n'
                                '4. QC verifies and approves designs\n'
                                '5. Manager sends WhatsApp poster dispatch\n'
                                '6. Check Alerts tab for pending or overdue deadlines',
                                textAlign: TextAlign.left,
                              ),
                            ),
                            actions: [
                              CupertinoDialogAction(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Understood'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Log Out Action
                    PrimaryButton(
                      label: 'Log Out',
                      icon: CupertinoIcons.square_arrow_right,
                      color: AppColors.accent,
                      onPressed: () async {
                        final ok = await showCupertinoDialog<bool>(
                          context: context,
                          builder: (ctx) => CupertinoAlertDialog(
                            title: const Text('Log Out?'),
                            content: const Text(
                              'Are you sure you want to sign out of your account?',
                            ),
                            actions: [
                              CupertinoDialogAction(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          try {
                            await context.read<OneSignalService>().logout();
                          } catch (_) {}
                          await context.read<AuthState>().logout();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updatePassword(BuildContext context, AppUser user) async {
    final ctrl = TextEditingController();
    bool obscure = true;
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('Update Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text('Enter a new password for your account.'),
              const SizedBox(height: 12),
              AppTextField(
                controller: ctrl,
                placeholder: 'Min 6 characters',
                obscureText: obscure,
                suffix: CupertinoButton(
                  padding: const EdgeInsets.only(right: 8),
                  minSize: 0,
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
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
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
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
    ctrl.dispose();
  }

  Widget _miniStat(
    String value,
    String label, {
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: AppFonts.montserrat(
                size: 20,
                weight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppFonts.poppins(
              size: 11,
              weight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernCardTile extends StatelessWidget {
  const _ModernCardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBgGradient,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final List<Color> iconBgGradient;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider, width: 1.2),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          splashColor: iconColor.withValues(alpha: 0.08),
          highlightColor: iconColor.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: iconBgGradient,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: AppFonts.montserrat(
                                size: 15.5,
                                weight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (badgeColor ?? iconColor).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge!,
                                style: AppFonts.poppins(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: badgeColor ?? iconColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppFonts.poppins(
                          size: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

