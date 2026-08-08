import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/date_formatters.dart';
import '../../models/notification_log.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ui_kit.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _running = false;

  Future<void> _runCheck() async {
    setState(() => _running = true);
    final count = await context.read<AppState>().runDailyCheck();
    if (!mounted) return;
    setState(() => _running = false);
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Check complete'),
        content: Text(count == 0 ? 'No new alerts.' : 'Created $count alert(s).'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _clearAll() async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Clear all alerts?'),
        content: const Text('Removes the in-app notification log.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppState>().clearNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = state.notifications;
    final unread = state.unreadNotificationsCount;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: list.isEmpty
            ? Column(
                children: [
                  PageHeader(
                    title: 'Alerts',
                    subtitle: 'Upload · send · overdue reminders',
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _running ? null : _runCheck,
                      child: _running
                          ? const CupertinoActivityIndicator()
                          : Text(
                              'Run check',
                              style: AppFonts.poppins(
                                size: 14,
                                weight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: EmptyState(
                      icon: CupertinoIcons.bell,
                      title: 'All clear',
                      message:
                          'Run a check anytime to scan for missing posters, pending sends, and overdue jobs.',
                      actionLabel: 'Run check now',
                      onAction: _runCheck,
                    ),
                  ),
                ],
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: PageHeader(
                      title: 'Alerts',
                      subtitle: unread > 0
                          ? '$unread unread · tap an alert to mark read'
                          : 'All read · run check for fresh scans',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.only(right: 4),
                            onPressed: _clearAll,
                            child: const Icon(
                              CupertinoIcons.trash,
                              size: 20,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _running ? null : _runCheck,
                            child: _running
                                ? const CupertinoActivityIndicator()
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Run check',
                                      style: AppFonts.poppins(
                                        size: 13,
                                        weight: FontWeight.w700,
                                        color: CupertinoColors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 100, top: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final n = list[index];
                          return _AlertTile(
                            log: n,
                            onTap: () => context.read<AppState>().markNotificationRead(n.id),
                          );
                        },
                        childCount: list.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.log, required this.onTap});

  final NotificationLog log;
  final VoidCallback onTap;

  Color get _tint {
    switch (log.type) {
      case NotificationType.uploadReminder:
        return AppColors.warning;
      case NotificationType.sendReminder:
        return AppColors.purple;
      case NotificationType.overdueAlert:
        return AppColors.overdue;
      case NotificationType.packageRenewal:
        return AppColors.teal;
    }
  }

  IconData get _icon {
    switch (log.type) {
      case NotificationType.uploadReminder:
        return CupertinoIcons.link;
      case NotificationType.sendReminder:
        return CupertinoIcons.paperplane_fill;
      case NotificationType.overdueAlert:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case NotificationType.packageRenewal:
        return CupertinoIcons.arrow_2_circlepath;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 5),
      highlightColor: log.read ? null : _tint,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: _icon, color: _tint, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.type.label,
                        style: AppFonts.poppins(
                          size: 12,
                          weight: FontWeight.w700,
                          color: _tint,
                        ),
                      ),
                    ),
                    if (!log.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(log.message, style: AppFonts.poppins(size: 14, height: 1.35)),
                const SizedBox(height: 4),
                Text(
                  '${log.clientName} · ${formatDate(log.sentAt)}',
                  style: AppFonts.helvetica(size: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
