import 'package:flutter/widgets.dart';

/// Breakpoints (logical pixels) aligned with Material adaptive guidelines.
class Breakpoints {
  Breakpoints._();

  /// Phones (portrait / small).
  static const double compact = 600;

  /// Large phones / small tablets.
  static const double medium = 900;

  /// Tablets / desktops.
  static const double expanded = 1200;
}

/// Device size class for layout decisions.
enum DeviceSize { compact, medium, expanded }

/// Responsive helpers via [BuildContext].
extension ResponsiveContext on BuildContext {
  MediaQueryData get mq => MediaQuery.of(this);

  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => screenSize.width;

  double get screenHeight => screenSize.height;

  double get shortestSide => screenSize.shortestSide;

  double get longestSide => screenSize.longestSide;

  bool get isLandscape => screenWidth > screenHeight;

  DeviceSize get deviceSize {
    final w = screenWidth;
    if (w >= Breakpoints.expanded) return DeviceSize.expanded;
    if (w >= Breakpoints.compact) return DeviceSize.medium;
    return DeviceSize.compact;
  }

  bool get isCompact => deviceSize == DeviceSize.compact;

  bool get isMedium => deviceSize == DeviceSize.medium;

  bool get isExpanded => deviceSize == DeviceSize.expanded;

  /// Tablet-class: wide enough for multi-column / side nav.
  bool get isTablet => shortestSide >= 600 || screenWidth >= Breakpoints.compact;

  /// Horizontal page inset.
  double get pagePadding {
    switch (deviceSize) {
      case DeviceSize.expanded:
        return 32;
      case DeviceSize.medium:
        return 24;
      case DeviceSize.compact:
        return screenWidth < 360 ? 14.0 : 18.0;
    }
  }

  /// Vertical gap between major sections.
  double get sectionGap {
    switch (deviceSize) {
      case DeviceSize.expanded:
        return 22;
      case DeviceSize.medium:
        return 18;
      case DeviceSize.compact:
        return 14;
    }
  }

  /// Max content width for readable lines on large screens.
  double get contentMaxWidth {
    switch (deviceSize) {
      case DeviceSize.expanded:
        return 1120;
      case DeviceSize.medium:
        return 840;
      case DeviceSize.compact:
        return double.infinity;
    }
  }

  /// Columns for card/list grids.
  int get listColumns {
    if (screenWidth >= Breakpoints.expanded) return 2;
    if (screenWidth >= 700 && isLandscape) return 2;
    if (screenWidth >= Breakpoints.medium) return 2;
    return 1;
  }

  /// Metric strip columns (pipeline KPIs — three tiles).
  int get metricColumns {
    if (screenWidth < 340) return 1;
    return 3;
  }

  double get titleFontSize {
    if (isExpanded) return 30;
    if (isMedium) return 28;
    return screenWidth < 360 ? 22.0 : 26.0;
  }

  double get bodyFontScale {
    if (screenWidth < 340) return 0.95;
    if (isExpanded) return 1.05;
    return 1.0;
  }

  /// Bottom safe padding so lists clear the tab bar / home indicator.
  double get listBottomPadding {
    final bottom = mq.padding.bottom;
    final tab = isTablet && !isCompact ? 24.0 : 88.0;
    return bottom + tab;
  }

  EdgeInsets get pageInsets => EdgeInsets.symmetric(horizontal: pagePadding);

  EdgeInsets pageInsetsOnly({
    double top = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.fromLTRB(pagePadding, top, pagePadding, bottom);
}

/// Centers [child] and caps width on tablets/desktops.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final max = maxWidth ?? context.contentMaxWidth;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max.isFinite ? max : double.infinity),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}

/// Horizontal page padding that scales with breakpoints.
class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({
    super.key,
    required this.child,
    this.top = 0,
    this.bottom = 0,
    this.includeVertical = false,
  });

  final Widget child;
  final double top;
  final double bottom;
  final bool includeVertical;

  @override
  Widget build(BuildContext context) {
    final p = context.pagePadding;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        p,
        includeVertical ? p : top,
        p,
        includeVertical ? p : bottom,
      ),
      child: child,
    );
  }
}

/// Builds a responsive grid or single-column list of [itemCount] children.
class ResponsiveItemGrid extends StatelessWidget {
  const ResponsiveItemGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 12,
    this.childAspectRatio,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.padding,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double spacing;
  final double? childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cols = context.listColumns;
    if (cols <= 1) {
      return ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      );
    }

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio ?? (context.isLandscape ? 1.55 : 1.35),
      ),
      itemBuilder: itemBuilder,
    );
  }
}

/// Wraps sliver children with max-width constraint for CustomScrollView.
class ResponsiveSliver extends StatelessWidget {
  const ResponsiveSliver({super.key, required this.sliver});

  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    final max = context.contentMaxWidth;
    if (!max.isFinite) return sliver;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        if (width <= max) return sliver;
        final side = (width - max) / 2;
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: side),
          sliver: sliver,
        );
      },
    );
  }
}

/// Applies horizontal inset for a sliver based on [pagePadding].
class ResponsiveSliverPadding extends StatelessWidget {
  const ResponsiveSliverPadding({
    super.key,
    required this.sliver,
    this.top = 0,
    this.bottom = 0,
  });

  final Widget sliver;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final p = context.pagePadding;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(p, top, p, bottom),
      sliver: sliver,
    );
  }
}

/// Metric / chip rows that wrap on narrow screens.
class ResponsiveWrap extends StatelessWidget {
  const ResponsiveWrap({
    super.key,
    required this.children,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}
