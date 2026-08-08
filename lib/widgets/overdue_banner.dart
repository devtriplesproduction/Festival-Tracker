import 'package:flutter/cupertino.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';

class OverdueBanner extends StatelessWidget {
  const OverdueBanner({super.key, required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final p = context.pagePadding;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(p, 4, p, 8),
        padding: EdgeInsets.symmetric(
          horizontal: context.isCompact ? 12 : 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF0F0), Color(0xFFFFE3E3)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.overdueBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.overdue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: AppColors.overdue,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 1 ? '1 job overdue' : '$count jobs overdue',
                    style: AppFonts.poppins(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.overdue,
                    ),
                  ),
                  Text(
                    onTap != null ? 'Tap to show only overdue' : 'Needs action before event',
                    style: AppFonts.helvetica(size: 12, color: AppColors.overdue),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.overdue),
          ],
        ),
      ),
    );
  }
}
