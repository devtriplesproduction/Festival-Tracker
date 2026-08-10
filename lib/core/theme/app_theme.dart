import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Soft, modern palette for TSP Festival Tracker — clear hierarchy, easy scan.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF9FAFB);

  static const Color accent = Color(0xFFB10255);
  static const Color accentSoft = Color(0xFFFFF0F5);
  static const Color accentDeep = Color(0xFF800040);

  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  static const Color borderSubtle = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  static const Color overdue = Color(0xFFDC2626);
  static const Color overdueSoft = Color(0xFFFEF2F2);
  static const Color overdueBorder = Color(0xFFF5C2C2);

  static const Color success = Color(0xFF000000); // Black for high-contrast actions
  static const Color successSoft = Color(0xFFF3F4F6); // Soft grey background

  static const Color warning = Color(0xFF4B5563); // Dark grey for secondary actions
  static const Color warningSoft = Color(0xFFF9FAFB);

  static const Color purple = Color(0xFFB10255); // Match primary accent
  static const Color purpleSoft = Color(0xFFFFF0F5);

  static const Color teal = Color(0xFF800040); // Deep plum
  static const Color tealSoft = Color(0xFFFCE8F3);
}

class AppFonts {
  AppFonts._();

  static TextStyle montserrat({
    double size = 16,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: TextDecoration.none,
    );
  }

  static TextStyle poppins({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: TextDecoration.none,
    );
  }

  static TextStyle helvetica({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textSecondary,
  }) {
    return TextStyle(
      fontFamily: 'Helvetica',
      fontFamilyFallback: const ['Helvetica Neue', 'Arial', 'sans-serif'],
      fontSize: size,
      fontWeight: weight,
      color: color,
      decoration: TextDecoration.none,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get material {
    final baseText = GoogleFonts.poppinsTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
        primary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseText.copyWith(
        headlineLarge: AppFonts.montserrat(size: 28, weight: FontWeight.w700, letterSpacing: -0.6),
        headlineMedium: AppFonts.montserrat(size: 22, weight: FontWeight.w700, letterSpacing: -0.4),
        titleLarge: AppFonts.montserrat(size: 18, weight: FontWeight.w700),
        titleMedium: AppFonts.montserrat(size: 16, weight: FontWeight.w600),
        bodyLarge: AppFonts.poppins(size: 16),
        bodyMedium: AppFonts.poppins(size: 14),
        bodySmall: AppFonts.helvetica(size: 13),
        labelLarge: AppFonts.poppins(size: 14, weight: FontWeight.w600, color: AppColors.accent),
        labelMedium: AppFonts.helvetica(size: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppFonts.montserrat(size: 20, weight: FontWeight.w700, letterSpacing: -0.3),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }

  static CupertinoThemeData get cupertino {
    return CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.background,
      barBackgroundColor: const Color(0xF0F3F5F9),
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.accent,
        textStyle: AppFonts.poppins(size: 16).copyWith(inherit: false),
        navTitleTextStyle:
            AppFonts.montserrat(size: 17, weight: FontWeight.w700).copyWith(inherit: false),
        navLargeTitleTextStyle: AppFonts.montserrat(
          size: 30,
          weight: FontWeight.w800,
          letterSpacing: -0.6,
        ).copyWith(inherit: false),
        actionTextStyle: AppFonts.poppins(size: 16, weight: FontWeight.w600, color: AppColors.accent)
            .copyWith(inherit: false),
      ),
    );
  }
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0x0D1A237E),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0x08000000),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: const Color(0x0A1A237E),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];
}

/// Shared layout constants for consistent spacing.
/// Prefer [ResponsiveContext] pagePadding for device-aware insets.
class AppSpace {
  AppSpace._();
  static const double page = 20;
  static const double cardGap = 10;
  static const double section = 18;

  /// Compact phone horizontal inset.
  static const double pageCompact = 14;

  /// Tablet / wide horizontal inset.
  static const double pageWide = 28;

  /// Max readable content width on large displays.
  static const double contentMax = 1120;
}
