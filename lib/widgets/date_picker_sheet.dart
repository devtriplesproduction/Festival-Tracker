import 'package:flutter/cupertino.dart';

import '../core/theme/app_theme.dart';

/// Full-width bottom sheet date picker with safe Cancel / Done bar.
///
/// Returns a **date-only** [DateTime] (local midnight) when the user taps Done.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  int? minimumYear,
  int? maximumYear,
  String title = 'Select date',
}) async {
  final nowYear = DateTime.now().year;
  final initial = DateTime(initialDate.year, initialDate.month, initialDate.day);
  final minYear = minimumYear ?? (initial.year < nowYear - 2 ? initial.year : nowYear - 2);
  final maxYear = maximumYear ?? (initial.year > nowYear + 3 ? initial.year : nowYear + 3);

  // CupertinoDatePicker asserts initialDateTime is within min/max year.
  final clampedInitial = DateTime(
    initial.year.clamp(minYear, maxYear),
    initial.month,
    initial.day,
  );

  DateTime temp = clampedInitial;

  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: Container(
          height: 320,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: AppFonts.poppins(
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppFonts.montserrat(
                          size: 15,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => Navigator.pop(
                        ctx,
                        DateTime(temp.year, temp.month, temp.day),
                      ),
                      child: Text(
                        'Done',
                        style: AppFonts.poppins(
                          size: 16,
                          weight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 0.5, color: AppColors.divider),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: clampedInitial,
                  minimumYear: minYear,
                  maximumYear: maxYear,
                  onDateTimeChanged: (d) => temp = d,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
