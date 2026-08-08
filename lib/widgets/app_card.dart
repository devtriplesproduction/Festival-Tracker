import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.overdue = false,
    this.margin = EdgeInsets.zero,
    this.highlightColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool overdue;
  final EdgeInsetsGeometry margin;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final accent = highlightColor ?? (overdue ? AppColors.overdue : null);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent != null ? accent.withValues(alpha: 0.12) : const Color(0x0C000000),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          const BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: accent != null ? accent.withValues(alpha: 0.4) : AppColors.borderSubtle.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            highlightColor: accent?.withValues(alpha: 0.05),
            splashColor: accent?.withValues(alpha: 0.1),
            child: Stack(
              children: [
                if (accent != null)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.06),
                            AppColors.surface.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: padding,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
