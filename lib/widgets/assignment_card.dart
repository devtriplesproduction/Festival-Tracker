import 'package:flutter/cupertino.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/date_formatters.dart';
import '../core/utils/responsive.dart';
import '../models/assignment.dart';
import '../models/assignment_status.dart';
import '../models/client.dart';
import '../models/festival.dart';
import '../models/user_role.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_card.dart';
import 'status_step_indicator.dart';
import 'ui_kit.dart';

/// Pipeline row: client + festival up top, one key deadline, status, one main action.
class AssignmentCard extends StatefulWidget {
  const AssignmentCard({
    super.key,
    required this.assignment,
    required this.client,
    required this.festival,
    required this.role,
    required this.onAdvance,
    required this.onChangeStatus,
    this.onUpload,
    this.onSendWhatsApp,
    this.onQcApprove,
    this.onQcRequestChanges,
    this.isInitiallyExpanded = false,
  });

  final Assignment assignment;
  final Client? client;
  final Festival? festival;
  final UserRole role;
  final VoidCallback onAdvance;
  final ValueChanged<AssignmentStatus> onChangeStatus;
  final VoidCallback? onUpload;
  final VoidCallback? onSendWhatsApp;
  final VoidCallback? onQcApprove;
  final VoidCallback? onQcRequestChanges;
  final bool isInitiallyExpanded;

  @override
  State<AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<AssignmentCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final overdue = widget.assignment.isOverdue();
    final daysLate = widget.assignment.daysLate();
    final clientName = widget.client?.name ?? 'Unknown client';
    final festivalName = widget.festival?.name ?? 'Unknown festival';
    final festivalDate = widget.festival?.date;
    final deadline = widget.assignment.currentStageDeadline;

    final p = context.pagePadding;
    final compact = context.screenWidth < 360;

    return AppCard(
      overdue: false, // Disabling card-level overdue highlight to avoid full red theme
      margin: EdgeInsets.symmetric(horizontal: p * 0.85, vertical: 4),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        compact ? 12 : 16,
        compact ? 12 : 16,
        compact ? 12 : 16,
      ),
      onTap: () => _showStatusSheet(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Identity row ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LetterAvatar(
                label: clientName,
                color: AppColors.accent,
                size: compact ? 36 : 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: AppFonts.montserrat(
                        size: compact ? 15 : 17,
                        weight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(CupertinoIcons.calendar, size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$festivalName${festivalDate != null ? ' · ${formatDateWeekday(festivalDate)}' : ''}',
                            style: AppFonts.helvetica(size: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusPill(status: widget.assignment.status, overdue: overdue),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    _isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),

          if (_isExpanded) ...[
            const SizedBox(height: 14),
            _PipelineTimeline(
              assignment: widget.assignment,
              overdue: overdue,
              daysLate: daysLate,
              deadline: deadline,
            ),
            if (widget.assignment.hasPoster) ...[
              const SizedBox(height: 10),
              _PosterRow(assignment: widget.assignment),
            ],
            const SizedBox(height: 12),
            _RoleActions(
              role: widget.role,
              assignment: widget.assignment,
              onAdvance: widget.onAdvance,
              onUpload: widget.onUpload,
              onSendWhatsApp: widget.onSendWhatsApp,
              onQcApprove: widget.onQcApprove,
              onQcRequestChanges: widget.onQcRequestChanges,
            ),
          ],
        ],
      ),
    );
  }

  void _showStatusSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return CupertinoActionSheet(
          title: Text(widget.client?.name ?? 'Assignment'),
          message: Text('Change stage · ${widget.festival?.name ?? ''}'),
          actions: AssignmentStatus.values.map((s) {
            final selected = s == widget.assignment.status;
            final allowed = widget.role.canSetStatus(s.value);
            return CupertinoActionSheetAction(
              onPressed: allowed
                  ? () {
                      Navigator.pop(ctx);
                      widget.onChangeStatus(s);
                    }
                  : () {},
              child: Text(
                allowed ? s.label : '${s.label} (locked)',
                style: AppFonts.poppins(
                  size: 17,
                  weight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: !allowed
                      ? AppColors.textTertiary
                      : selected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }
}

class _PipelineTimeline extends StatelessWidget {
  const _PipelineTimeline({
    required this.assignment,
    required this.overdue,
    required this.daysLate,
    required this.deadline,
  });

  final Assignment assignment;
  final bool overdue;
  final int daysLate;
  final DateTime? deadline;

  String _focusLine() {
    if (assignment.status.isTerminal) {
      final when = assignment.sentAt != null
          ? ' · ${formatDateShort(assignment.sentAt!)}'
          : '';
      return 'Sent to client$when';
    }
    if (deadline == null) return 'No deadline set';
    if (overdue) {
      return '${relativeDeadlineLabel(deadline!)} · was ${formatDateShort(deadline!)}';
    }
    return '${relativeDeadlineLabel(deadline!)} · ${formatDateShort(deadline!)}';
  }

  @override
  Widget build(BuildContext context) {
    final status = assignment.status;
    final filled = status.filledStages;

    final stages = [
      (label: 'Design', date: assignment.designDueDate),
      (label: 'QC', date: assignment.qcDueDate),
      (label: 'Ready', date: assignment.readyDueDate),
      (label: 'Send', date: assignment.sendDueDate),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: overdue && !status.isTerminal
            ? AppColors.overdueSoft.withValues(alpha: 0.35)
            : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: overdue && !status.isTerminal
              ? AppColors.overdue.withValues(alpha: 0.25)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        children: [
          // Header: Focus deadline status & poster indicator
          Row(
            children: [
              Icon(
                status.isTerminal
                    ? CupertinoIcons.checkmark_seal_fill
                    : overdue
                        ? CupertinoIcons.alarm_fill
                        : CupertinoIcons.clock,
                size: 13,
                color: status.isTerminal
                    ? AppColors.success
                    : overdue
                        ? AppColors.overdue
                        : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _focusLine(),
                  style: AppFonts.poppins(
                    size: 12,
                    weight: FontWeight.w600,
                    color: status.isTerminal
                        ? AppColors.success
                        : overdue
                            ? AppColors.overdue
                            : AppColors.textPrimary,
                  ),
                ),
              ),
              if (assignment.hasPoster)
                const Icon(CupertinoIcons.link, size: 13, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 10),

          // 4-Stage Stepper with Stage Names & Dates directly under each dot
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(4, (i) {
              final stage = stages[i];
              final isDone = i < filled;
              final isCurrent = filled == 0
                  ? i == 0 && status == AssignmentStatus.notStarted
                  : i == filled - 1 && !status.isTerminal;
              final isOverdueStage = isCurrent && overdue;

              // Line colors
              final leftLineDone = i <= filled - 1;
              final rightLineDone = i < filled - 1;

              final dotColor = isDone
                  ? AppColors.accent
                  : isOverdueStage
                      ? AppColors.overdue
                      : isCurrent
                          ? AppColors.accentSoft
                          : CupertinoColors.transparent;

              final borderColor = isDone || isCurrent
                  ? (isOverdueStage ? AppColors.overdue : AppColors.accent)
                  : AppColors.borderSubtle;

              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot and Connecting lines
                    SizedBox(
                      height: 14,
                      child: Row(
                        children: [
                          Expanded(
                            child: i == 0
                                ? const SizedBox.shrink()
                                : Container(
                                    height: 2,
                                    color: leftLineDone
                                        ? AppColors.accent
                                        : AppColors.borderSubtle,
                                  ),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: borderColor,
                                width: 2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: i == 3
                                ? const SizedBox.shrink()
                                : Container(
                                    height: 2,
                                    color: rightLineDone
                                        ? AppColors.accent
                                        : AppColors.borderSubtle,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      stage.label,
                      style: AppFonts.poppins(
                        size: 11,
                        weight: isDone || isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isOverdueStage
                            ? AppColors.overdue
                            : (isDone || isCurrent)
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      formatDateShort(stage.date),
                      style: AppFonts.poppins(
                        size: 10,
                        weight: isDone || isCurrent ? FontWeight.w600 : FontWeight.w400,
                        color: isOverdueStage
                            ? AppColors.overdue
                            : (isDone || isCurrent)
                                ? AppColors.textSecondary
                                : AppColors.textTertiary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PosterRow extends StatelessWidget {
  const _PosterRow({required this.assignment});

  final Assignment assignment;

  @override
  Widget build(BuildContext context) {
    final preview = assignment.posterPreviewPath;
    final openUrl = assignment.posterUrl ?? preview;

    Widget fallbackThumb = Container(
      width: 40,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(CupertinoIcons.link, color: AppColors.success, size: 18),
    );
    
    Widget thumb = fallbackThumb;

    final isPdf = openUrl != null && openUrl.toLowerCase().contains('.pdf');

    if (isPdf) {
      thumb = Container(
        width: 40,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(CupertinoIcons.doc_fill, color: AppColors.accent, size: 24),
      );
    } else if (openUrl != null && (openUrl.startsWith('http') || openUrl.startsWith('https'))) {
      thumb = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          openUrl,
          width: 40,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallbackThumb,
        ),
      );
    } else if (preview != null && !preview.startsWith('http')) {
      // It's a blob URL (web) or local path
      thumb = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          preview,
          width: 40,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallbackThumb,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        if (openUrl != null && (openUrl.startsWith('http') || openUrl.startsWith('https'))) {
          launchUrl(Uri.parse(openUrl));
        }
      }, 
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.successSoft.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            thumb,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPdf ? 'PDF ready' : 'Poster link ready',
                    style: AppFonts.poppins(size: 12, weight: FontWeight.w700, color: AppColors.success),
                  ),
                  Text(
                    assignment.designerNotes?.isNotEmpty == true
                        ? assignment.designerNotes!
                        : 'Tap to open file',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.helvetica(size: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.arrow_up_right_square, size: 18, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}

class _RoleActions extends StatelessWidget {
  const _RoleActions({
    required this.role,
    required this.assignment,
    required this.onAdvance,
    this.onUpload,
    this.onSendWhatsApp,
    this.onQcApprove,
    this.onQcRequestChanges,
  });

  final UserRole role;
  final Assignment assignment;
  final VoidCallback onAdvance;
  final VoidCallback? onUpload;
  final VoidCallback? onSendWhatsApp;
  final VoidCallback? onQcApprove;
  final VoidCallback? onQcRequestChanges;

  @override
  Widget build(BuildContext context) {
    // QC Review actions (Only when stage is QC)
    if (role.canQcReview &&
        onQcApprove != null &&
        onQcRequestChanges != null &&
        assignment.status == AssignmentStatus.qc) {
      return Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Changes',
              icon: CupertinoIcons.arrow_uturn_left,
              color: AppColors.overdue,
              onPressed: onQcRequestChanges,
              expanded: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PrimaryButton(
              label: 'Approve',
              icon: CupertinoIcons.checkmark_seal_fill,
              color: AppColors.accent,
              onPressed: onQcApprove,
              expanded: true,
            ),
          ),
        ],
      );
    }

    // WhatsApp actions (When stage is Ready or Sent)
    if (role.canSendWhatsApp &&
        onSendWhatsApp != null &&
        (assignment.status == AssignmentStatus.ready ||
            assignment.status == AssignmentStatus.sent ||
            role == UserRole.admin)) {
      return Row(
        children: [
          if (role.canUploadPoster && onUpload != null) ...[
            Expanded(
              child: SecondaryButton(
                label: assignment.hasPoster ? 'Edit link' : 'Attach link',
                icon: CupertinoIcons.link,
                color: AppColors.accent,
                onPressed: onUpload,
                expanded: true,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: PrimaryButton(
              label: assignment.status == AssignmentStatus.sent ? 'Resend' : 'WhatsApp',
              icon: CupertinoIcons.chat_bubble_2_fill,
              color: AppColors.accent,
              onPressed: onSendWhatsApp,
              expanded: true,
            ),
          ),
        ],
      );
    }

    // Design stage actions
    if (assignment.status == AssignmentStatus.design) {
      return Row(
        children: [
          if (role.canUploadPoster && onUpload != null) ...[
            Expanded(
              child: SecondaryButton(
                label: assignment.hasPoster ? 'Edit link' : 'Attach link',
                icon: CupertinoIcons.link,
                color: AppColors.accent,
                onPressed: onUpload,
                expanded: true,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: PrimaryButton(
              label: 'Submit for QC',
              icon: CupertinoIcons.arrow_right_circle_fill,
              color: AppColors.accent,
              onPressed: onAdvance,
              expanded: true,
            ),
          ),
        ],
      );
    }

    if (role.canUploadPoster && onUpload != null) {
      return PrimaryButton(
        label: assignment.hasPoster ? 'Update poster link' : 'Attach poster link',
        icon: CupertinoIcons.link,
        color: AppColors.accent,
        onPressed: onUpload,
        expanded: true,
      );
    }

    if (!assignment.status.isTerminal) {
      return PrimaryButton(
        label: assignment.status == AssignmentStatus.notStarted ? 'Start work' : 'Advance stage',
        icon: CupertinoIcons.arrow_right_circle_fill,
        onPressed: onAdvance,
        expanded: true,
      );
    }

    return const SizedBox.shrink();
  }
}
