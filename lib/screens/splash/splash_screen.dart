import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

class SplashScreen extends StatelessWidget {
  final String message;

  const SplashScreen({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final iconPad = context.isCompact ? 20.0 : 24.0;
    final iconSize = context.isCompact ? 52.0 : 64.0;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.accent,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPad),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.calendar_today,
                    size: iconSize,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'TSP Festival Tracker',
                  textAlign: TextAlign.center,
                  style: AppFonts.montserrat(
                    size: context.isCompact ? 20 : 24,
                    weight: FontWeight.w800,
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 24),
                const CupertinoActivityIndicator(
                  radius: 12,
                  color: AppColors.surface,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppFonts.poppins(
                    size: 14,
                    weight: FontWeight.w500,
                    color: AppColors.surface.withValues(alpha: 0.9),
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
