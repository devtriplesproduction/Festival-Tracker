import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/assignment_status.dart';

/// Compact 4-stage progress: Design → QC → Ready → Send
class StatusStepIndicator extends StatelessWidget {
  const StatusStepIndicator({
    super.key,
    required this.status,
    this.compact = false,
  });

  final AssignmentStatus status;
  final bool compact;

  static const _labels = ['Design', 'QC', 'Ready', 'Send'];

  @override
  Widget build(BuildContext context) {
    final filled = status.filledStages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(4, (i) {
            final isDone = i < filled;
            final isCurrent = filled == 0
                ? i == 0 && status == AssignmentStatus.notStarted
                : i == filled - 1;

            final circle = AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: compact ? 11 : 14,
              height: compact ? 11 : 14,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.accent
                    : isCurrent
                        ? AppColors.accentSoft
                        : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone || isCurrent ? AppColors.accent : AppColors.borderSubtle,
                  width: 2,
                ),
              ),
            );

            if (i == 3) {
              return circle;
            }

            return Expanded(
              child: Row(
                children: [
                  circle,
                  Expanded(
                    child: Container(
                      height: 2.5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.accent : AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (i) {
              final isDone = i < filled;
              return Text(
                _labels[i],
                style: AppFonts.poppins(
                  size: 10,
                  weight: isDone ? FontWeight.w700 : FontWeight.w500,
                  color: isDone ? AppColors.textPrimary : AppColors.textTertiary,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
    this.overdue = false,
  });

  final AssignmentStatus status;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    if (overdue && !status.isTerminal) {
      bg = AppColors.overdueSoft;
      fg = AppColors.overdue;
    } else {
      switch (status) {
        case AssignmentStatus.sent:
          bg = AppColors.successSoft;
          fg = AppColors.success;
        case AssignmentStatus.ready:
          bg = AppColors.purpleSoft;
          fg = AppColors.purple;
        case AssignmentStatus.qc:
          bg = AppColors.accentSoft;
          fg = AppColors.accent;
        case AssignmentStatus.design:
          bg = AppColors.warningSoft;
          fg = AppColors.warning;
        case AssignmentStatus.notStarted:
          bg = AppColors.surfaceMuted;
          fg = AppColors.textSecondary;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        overdue && !status.isTerminal ? 'Overdue' : status.label,
        style: AppFonts.poppins(size: 11, weight: FontWeight.w700, color: fg),
      ),
    );
  }
}
