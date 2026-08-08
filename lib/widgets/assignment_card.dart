import 'dart:io';

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;

import '../core/theme/app_theme.dart';
import '../core/utils/date_formatters.dart';
import '../core/utils/responsive.dart';
import '../models/assignment.dart';
import '../models/assignment_status.dart';
import '../models/client.dart';
import '../models/festival.dart';
import '../models/user_role.dart';
import '../services/share_download_service.dart';
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
      margin: EdgeInsets.symmetric(horizontal: p * 0.85, vertical: 8),
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
            const SizedBox(height: 20),
            StatusStepIndicator(status: widget.assignment.status, compact: false),
            const SizedBox(height: 20),

            // ── Focus & Mini Deadlines ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderSubtle,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        overdue ? CupertinoIcons.alarm_fill : CupertinoIcons.clock,
                        size: 14,
                        color: overdue ? AppColors.overdue : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _focusLine(deadline, overdue, daysLate),
                          style: AppFonts.poppins(
                            size: 12,
                            weight: FontWeight.w600,
                            color: overdue ? AppColors.overdue : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (widget.assignment.hasPoster)
                        const Icon(CupertinoIcons.link, size: 14, color: AppColors.success),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.borderSubtle),
                  ),
                  _MiniDeadlines(assignment: widget.assignment, overdue: overdue),
                ],
              ),
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

  String _focusLine(DateTime? deadline, bool overdue, int daysLate) {
    if (widget.assignment.status.isTerminal) {
      final when = widget.assignment.sentAt != null
          ? ' · ${formatDateShort(widget.assignment.sentAt!)}'
          : '';
      return 'Sent to client$when';
    }
    if (deadline == null) return 'No deadline';
    if (overdue) {
      return '${relativeDeadlineLabel(deadline)} · was ${formatDateShort(deadline)}';
    }
    return '${relativeDeadlineLabel(deadline)} · ${formatDateShort(deadline)}';
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

class _MiniDeadlines extends StatelessWidget {
  const _MiniDeadlines({required this.assignment, required this.overdue});

  final Assignment assignment;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, DateTime date, bool active) {
      final late = active && overdue;
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppFonts.poppins(
                size: 9,
                weight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatDateShort(date),
              style: AppFonts.poppins(
                size: 11,
                weight: FontWeight.w700,
                color: late ? AppColors.overdue : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final s = assignment.status;
    return Row(
      children: [
        cell('DESIGN', assignment.designDueDate, s == AssignmentStatus.notStarted || s == AssignmentStatus.design),
        Container(width: 1, height: 24, color: AppColors.borderSubtle, margin: const EdgeInsets.symmetric(horizontal: 8)),
        cell('QC', assignment.qcDueDate, s == AssignmentStatus.qc),
        Container(width: 1, height: 24, color: AppColors.borderSubtle, margin: const EdgeInsets.symmetric(horizontal: 8)),
        cell('READY', assignment.readyDueDate, s == AssignmentStatus.ready),
        Container(width: 1, height: 24, color: AppColors.borderSubtle, margin: const EdgeInsets.symmetric(horizontal: 8)),
        cell('SEND', assignment.sendDueDate, s == AssignmentStatus.ready || s == AssignmentStatus.sent),
      ],
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
    // One primary action + optional secondary — avoids button clutter.
    if (role.canQcReview &&
        onQcApprove != null &&
        onQcRequestChanges != null &&
        (assignment.status == AssignmentStatus.qc ||
            assignment.status == AssignmentStatus.design)) {
      return Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Changes',
              icon: CupertinoIcons.arrow_uturn_left,
              color: AppColors.warning,
              onPressed: onQcRequestChanges,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PrimaryButton(
              label: 'Approve',
              icon: CupertinoIcons.checkmark_seal_fill,
              color: AppColors.purple,
              onPressed: onQcApprove,
            ),
          ),
        ],
      );
    }

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
                label: assignment.hasPoster ? 'Edit link' : 'Add link',
                icon: CupertinoIcons.link,
                onPressed: onUpload,
                expanded: true,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: role.canUploadPoster ? 1 : 1,
            child: PrimaryButton(
              label: assignment.status == AssignmentStatus.sent ? 'Resend' : 'WhatsApp',
              icon: CupertinoIcons.chat_bubble_2_fill,
              color: AppColors.success,
              onPressed: onSendWhatsApp,
            ),
          ),
        ],
      );
    }

    if (role.canUploadPoster && onUpload != null) {
      return PrimaryButton(
        label: assignment.hasPoster ? 'Update poster link' : 'Attach poster link',
        icon: CupertinoIcons.link,
        color: AppColors.warning,
        onPressed: onUpload,
      );
    }

    if (!assignment.status.isTerminal) {
      return Align(
        alignment: Alignment.centerRight,
        child: PrimaryButton(
          label: assignment.status == AssignmentStatus.notStarted ? 'Start work' : 'Advance stage',
          icon: CupertinoIcons.arrow_right_circle_fill,
          onPressed: onAdvance,
          expanded: false,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
