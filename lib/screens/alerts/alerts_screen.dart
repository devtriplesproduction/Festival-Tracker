import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/date_formatters.dart';
import '../../models/notification_log.dart';
import '../../models/user_role.dart';
import '../../providers/app_state.dart';
import '../../providers/auth_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ui_kit.dart';
import '../../services/whatsapp_service.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final authState = context.watch<AuthState>();
    final uid = authState.user?.id ?? '';
    final role = authState.role ?? UserRole.designer;

    final seenIds = <String>{};
    final list = state.notifications.where((n) {
      if (n.type == NotificationType.newAssignment) return false;
      if (n.readBy.contains(uid)) return false;
      if (role != UserRole.admin && n.recipientRole != 'all' && n.recipientRole.toLowerCase() != role.value.toLowerCase()) {
        return false;
      }
      // Deduplicate identical alerts
      return seenIds.add(n.id);
    }).toList();

    final unread = list.length;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0x00000000),
        border: null,
        leading: AppBackButton(margin: EdgeInsets.only(left: 8)),
      ),
      child: SafeArea(
        bottom: false,
        child: ResponsiveContent(
          child: list.isEmpty
              ? const Column(
                  children: [
                    PageHeader(
                      title: 'Alerts',
                      subtitle: 'Upload · send · overdue reminders',
                    ),
                    Expanded(
                      child: EmptyState(
                        icon: CupertinoIcons.bell_slash,
                        title: 'All caught up',
                        message:
                            'You have no new alerts. New notifications and workflow updates will appear here automatically.',
                      ),
                    ),
                  ],
                )
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: PageHeader(
                        title: 'Alerts',
                        subtitle: unread > 0
                            ? '$unread unread · tap to mark read'
                            : 'All caught up',
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.pagePadding,
                        vertical: 4,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == list.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: state.loadingMoreNotifications
                                      ? const CupertinoActivityIndicator()
                                      : CupertinoButton(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                          onPressed: () => state.loadMoreNotifications(),
                                          child: Text(
                                            'Load Older Alerts',
                                            style: AppFonts.poppins(
                                              size: 14,
                                              weight: FontWeight.w600,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            }
                            final n = list[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AlertTile(
                                log: n,
                                uid: uid,
                                onTap: () => context.read<AppState>().markNotificationRead(n.id, uid),
                              ),
                            );
                          },
                          childCount: list.length + (state.hasMoreNotifications ? 1 : 0),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.log,
    required this.onTap,
    required this.uid,
  });

  final NotificationLog log;
  final VoidCallback onTap;
  final String uid;

  bool get _isUrgent {
    switch (log.type) {
      case NotificationType.overdueAlert:
      case NotificationType.overdueReminder:
      case NotificationType.qcRejected:
      case NotificationType.uploadFailed:
        return true;
      default:
        return false;
    }
  }

  Color get _color => _isUrgent ? AppColors.overdue : AppColors.accent;
  Color get _bg => _isUrgent ? AppColors.overdueSoft : AppColors.accentSoft;

  IconData get _icon {
    switch (log.type) {
      case NotificationType.uploadReminder:
      case NotificationType.deadlineReminder:
        return CupertinoIcons.clock_fill;
      case NotificationType.sendReminder:
      case NotificationType.readyToSend:
        return CupertinoIcons.paperplane_fill;
      case NotificationType.overdueAlert:
      case NotificationType.overdueReminder:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case NotificationType.packageRenewal:
      case NotificationType.packageExpiry:
        return CupertinoIcons.arrow_2_circlepath;
      case NotificationType.newAssignment:
        return CupertinoIcons.person_crop_circle_badge_plus;
      case NotificationType.qcUploaded:
        return CupertinoIcons.cloud_upload_fill;
      case NotificationType.qcRejected:
        return CupertinoIcons.xmark_circle_fill;
      case NotificationType.qcApproved:
        return CupertinoIcons.checkmark_seal_fill;
      case NotificationType.posterSent:
        return CupertinoIcons.paperplane_fill;
      case NotificationType.uploadFailed:
        return CupertinoIcons.exclamationmark_circle_fill;
      case NotificationType.upcomingFestival:
        return CupertinoIcons.calendar;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isRead = log.readBy.contains(uid);
    final color = _color;
    final bg = _bg;

    final isPackageAlert = log.type == NotificationType.packageExpiry || log.type == NotificationType.packageRenewal;
    final hasClient = log.clientId.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge matching app design
          IconBadge(
            icon: _icon,
            color: color,
            bg: bg,
            size: 42,
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type tag & relative timestamp
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.type.label,
                        style: AppFonts.montserrat(
                          size: 11,
                          weight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(log.sentAt),
                      style: AppFonts.helvetica(
                        size: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    if (!isRead) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Message
                Text(
                  log.message,
                  style: AppFonts.poppins(
                    size: 13.5,
                    weight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                // Client details footer
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.person_fill,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        log.clientName,
                        style: AppFonts.poppins(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (log.festivalName.isNotEmpty) ...[
                      Text(
                        ' · ',
                        style: AppFonts.helvetica(
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          log.festivalName,
                          style: AppFonts.helvetica(
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (isPackageAlert && hasClient) ...[
                  const SizedBox(height: 12),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(8),
                    minSize: 0,
                    onPressed: () {
                      final client = context.read<AppState>().clientById(log.clientId);
                      if (client != null && client.whatsappNumber.isNotEmpty) {
                        final price = client.packagePrice ?? 2500.0; // fallback default
                        WhatsAppService.openBillingChat(
                          phoneNumber: client.whatsappNumber,
                          clientName: client.name,
                          isExpired: log.type == NotificationType.packageExpiry,
                          price: price,
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.chat_bubble_text_fill, size: 14, color: CupertinoColors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Message on WhatsApp',
                          style: AppFonts.poppins(size: 12, weight: FontWeight.w600, color: CupertinoColors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
