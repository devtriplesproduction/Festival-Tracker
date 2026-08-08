import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';

/// Page top: title + short “what to do” line.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.pagePadding;
    final narrow = context.screenWidth < 360;
    final stackTrailing = trailing != null && context.screenWidth < 340;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.montserrat(
            size: context.titleFontSize,
            weight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppFonts.poppins(
            size: narrow ? 12 : 13,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(p, 8, p, 4),
      child: stackTrailing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: trailing!),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
    );
  }
}

/// Soft circular icon badge for list rows.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.accent,
    this.bg,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final Color? bg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.42),
    );
  }
}

/// Letter avatar for people / clients.
class LetterAvatar extends StatelessWidget {
  const LetterAvatar({
    super.key,
    required this.label,
    this.color = AppColors.accent,
    this.size = 46,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppFonts.montserrat(
          size: size * 0.38,
          weight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppFonts.poppins(
        size: 11,
        weight: FontWeight.w700,
        color: AppColors.textTertiary,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Consistent text field chrome for forms.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.autocorrect = true,
    this.textInputAction,
    this.onSubmitted,
    this.prefix,
    this.suffix,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? placeholder;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool autocorrect;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autocorrect: autocorrect,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      prefix: prefix == null
          ? null
          : Padding(padding: const EdgeInsets.only(left: 12), child: prefix),
      suffix: suffix,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      style: AppFonts.poppins(size: 15),
      placeholderStyle: AppFonts.poppins(size: 15, color: AppColors.textTertiary),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.soft,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.color,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? color;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.accent;
    final child = loading
        ? const CupertinoActivityIndicator(color: Colors.white)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppFonts.poppins(
                  size: 15,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          );

    final btn = CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: loading ? null : onPressed,
      pressedOpacity: 0.75,
      child: Container(
        width: expanded ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bg,
              Color.lerp(bg, Colors.black, 0.15) ?? bg,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
            const BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );

    return btn;
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    final btn = CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      pressedOpacity: 0.6,
      child: Container(
        width: expanded ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: c.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: c),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppFonts.poppins(size: 13, weight: FontWeight.w700, color: c),
            ),
          ],
        ),
      ),
    );
    
    return btn;
  }
}

/// Filter / chip control.
class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.danger = false,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool danger;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.overdue : AppColors.accent;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : AppColors.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? color : AppColors.borderSubtle,
            ),
            boxShadow: selected ? null : AppShadows.soft,
          ),
          child: Text(
            count != null ? '$label ($count)' : label,
            style: AppFonts.poppins(
              size: 12,
              weight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact metric tile for dashboard strip.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tile = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          context.isCompact ? 10 : 12,
          context.isCompact ? 10 : 12,
          context.isCompact ? 10 : 12,
          context.isCompact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.45) : AppColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? null : AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 13, color: color),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.poppins(
                      size: 10,
                      weight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppFonts.montserrat(
                size: context.screenWidth < 360 ? 18 : 22,
                weight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );

    // Parent may place tiles in a Row of Expanded or a Wrap/Grid.
    return tile;
  }
}

/// Horizontal or wrapping strip of [MetricTile]s that stays usable on small phones.
class MetricStrip extends StatelessWidget {
  const MetricStrip({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cols = context.metricColumns;
    // Prefer equal-width row when we can fit all tiles (e.g. 3 KPIs).
    if (cols >= children.length || children.length <= 3) {
      return Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: context.pagePadding * 0.4),
            Expanded(child: children[i]),
          ],
        ],
      );
    }

    // Wrap grid for larger sets on narrow devices.
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 8.0;
        final perRow = cols.clamp(1, children.length);
        final w = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map(
                (c) => SizedBox(width: w, child: c),
              )
              .toList(),
        );
      },
    );
  }
}

/// Soft tip / info banner.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon = CupertinoIcons.info_circle_fill,
    this.color = AppColors.accent,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppFonts.poppins(size: 13, color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class FormFieldBlock extends StatelessWidget {
  const FormFieldBlock({
    super.key,
    required this.label,
    required this.child,
    this.hint,
  });

  final String label;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: 8),
        child,
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint!,
            style: AppFonts.helvetica(size: 12, color: AppColors.textTertiary),
          ),
        ],
      ],
    );
  }
}

/// Attractive button for Navigation Bar trailing actions
class NavBarActionButton extends StatelessWidget {
  const NavBarActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? AppColors.accent : AppColors.textSecondary;
    
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: loading ? null : onPressed,
      pressedOpacity: 0.7,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2),
        ),
        child: loading
            ? const CupertinoActivityIndicator(radius: 8)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: AppFonts.poppins(size: 13, weight: FontWeight.w600, color: color),
                  ),
                ],
              ),
      ),
    );
  }
}

