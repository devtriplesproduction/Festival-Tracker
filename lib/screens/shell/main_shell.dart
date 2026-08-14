import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Badge,
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
import '../clients/clients_screen.dart';
import '../festivals/festivals_screen.dart';
import '../packages/packages_screen.dart';
import '../pipeline/pipeline_screen.dart';
import '../settings/deadline_settings_screen.dart';
import '../team/team_screen.dart';
import '../gallery/gallery_screen.dart';

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
    final unread = context.watch<AppState>().unreadNotificationsCount(uid);
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

    if (role.canManageFestivals || role == UserRole.designer || role == UserRole.qc) {
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

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(p, 8, p, 40),
          children: [
            const PageHeader(
              title: 'Account',
              subtitle: 'Profile, settings, and sign out',
            ),
            SizedBox(height: context.sectionGap * 0.5),
            // Counteract PageHeader horizontal padding so card aligns with list padding.
            Transform.translate(
              offset: Offset(-p, 0),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: p),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Container(
                    padding: EdgeInsets.all(context.isCompact ? 18 : 22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3B5BDB), Color(0xFF5C7CFA)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: context.isCompact ? 64 : 72,
                          height: context.isCompact ? 64 : 72,
                          decoration: BoxDecoration(
                            color: const Color(0x33FFFFFF),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0x55FFFFFF)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            (user?.displayName.isNotEmpty == true)
                                ? user!.displayName[0].toUpperCase()
                                : '?',
                            style: AppFonts.montserrat(
                              size: 30,
                              weight: FontWeight.w800,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user?.displayName ?? '',
                          textAlign: TextAlign.center,
                          style: AppFonts.montserrat(
                            size: 20,
                            weight: FontWeight.w800,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${user?.username ?? ''} · ${user?.role.label ?? ''}',
                          textAlign: TextAlign.center,
                          style: AppFonts.poppins(
                            size: 13,
                            color: const Color(0xCCFFFFFF),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _miniStat('${stats.total}', 'Jobs'),
                            _miniStat('${stats.overdueCount}', 'Overdue'),
                            _miniStat('${stats.readyToSend}', 'Ready'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (app.usingLocalStore)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: InfoBanner(
                        icon: CupertinoIcons.device_phone_portrait,
                        message: 'Local mode — data is stored on this device only.',
                        color: AppColors.warning,
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: InfoBanner(
                        icon: CupertinoIcons.cloud_fill,
                        message: 'Cloud mode — data syncs via Firestore.',
                        color: AppColors.success,
                      ),
                    ),
                  
                  if (role.canViewClients)
                    _SettingsTile(
                      icon: CupertinoIcons.person_2,
                      title: 'Clients',
                      subtitle: 'Manage client accounts',
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(builder: (_) => const ClientsScreen()),
                        );
                      },
                    ),
                  if (role.canViewPackages)
                    _SettingsTile(
                      icon: CupertinoIcons.cube_box,
                      title: 'Packages',
                      subtitle: 'Manage client packages',
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(builder: (_) => const PackagesScreen()),
                        );
                      },
                    ),
                  if (role.canManageTeam) ...[
                    _SettingsTile(
                      icon: CupertinoIcons.photo_on_rectangle,
                      title: 'Gallery',
                      subtitle: 'View all completed posters',
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(builder: (_) => const GalleryScreen()),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: CupertinoIcons.person_3,
                      title: 'Team',
                      subtitle: 'Manage team members',
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(builder: (_) => const TeamScreen()),
                        );
                      },
                    ),
                  ],

                  if (role.canManageSettings)
                    _SettingsTile(
                      icon: CupertinoIcons.slider_horizontal_3,
                      title: 'Deadline settings',
                      subtitle: 'Days before event for Design / QC / Ready',
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(builder: (_) => const DeadlineSettingsScreen()),
                        );
                      },
                    ),

                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: CupertinoIcons.lock_rotation,
                    title: 'Update password',
                    subtitle: 'Change your account password',
                    onTap: () {
                      if (user != null) {
                        _updatePassword(context, user);
                      }
                    },
                  ),
                  _SettingsTile(
                    icon: CupertinoIcons.info_circle,
                    title: 'How it works',
                    subtitle: 'Festival date → auto deadlines → poster URL → WhatsApp',
                    onTap: () {
                      showCupertinoDialog<void>(
                        context: context,
                        builder: (ctx) => CupertinoAlertDialog(
                          title: const Text('How it works'),
                          content: const Text(
                            '1. Add festivals & clients\n'
                            '2. Assign client × festival (Pipeline)\n'
                            '3. Designer pastes Drive poster URL\n'
                            '4. QC approves · Manager sends WhatsApp\n'
                            '5. Check Alerts for overdue jobs',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Log out',
                    icon: CupertinoIcons.square_arrow_right,
                    color: AppColors.overdue,
                    onPressed: () async {
                      final ok = await showCupertinoDialog<bool>(
                        context: context,
                        builder: (ctx) => CupertinoAlertDialog(
                          title: const Text('Log out?'),
                          content: const Text('You will need your username and password again.'),
                          actions: [
                            CupertinoDialogAction(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Log out'),
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
              ),
            ),
          ],
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
          title: const Text('Update password'),
          content: Column(
            children: [
              const SizedBox(height: 8),
              const Text('Enter a new password for your account.'),
              const SizedBox(height: 12),
              CupertinoTextField(
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

  Widget _miniStat(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppFonts.montserrat(
                size: 18,
                weight: FontWeight.w800,
                color: const Color(0xFFFFFFFF),
              ),
            ),
            Text(
              label,
              style: AppFonts.poppins(
                size: 11,
                color: const Color(0xCCFFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(context.isCompact ? 14 : 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.soft,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            IconBadge(icon: icon, size: context.isCompact ? 38 : 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppFonts.montserrat(size: 15, weight: FontWeight.w700)),
                  Text(
                    subtitle,
                    style: AppFonts.helvetica(size: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
