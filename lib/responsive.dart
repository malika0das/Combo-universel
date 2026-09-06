import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// Responsive system
/// ---------------------------------------------------------------------------
/// Breakpoints are chosen around content, not devices: the number of list
/// columns that stay readable at our body size.
enum ScreenSize {
  /// Phones in portrait — a single column.
  compact,

  /// Large phones landscape / small tablets — two columns.
  medium,

  /// Tablets and foldables opened — two columns plus a persistent side panel.
  expanded;

  bool get isCompact => this == ScreenSize.compact;
  bool get isMedium => this == ScreenSize.medium;
  bool get isExpanded => this == ScreenSize.expanded;
  bool get isWide => this != ScreenSize.compact;
}

class Breakpoints {
  const Breakpoints._();
  static const double medium = 600;
  static const double expanded = 905;

  /// Content never stretches past this — long lines of model names become hard
  /// to scan on a tablet otherwise.
  static const double maxContentWidth = 1100;
}

extension ResponsiveContext on BuildContext {
  ScreenSize get screen {
    final width = MediaQuery.sizeOf(this).width;
    if (width >= Breakpoints.expanded) return ScreenSize.expanded;
    if (width >= Breakpoints.medium) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  bool get isWide => screen.isWide;

  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Horizontal page padding that grows with the viewport.
  double get pagePadding => switch (screen) {
        ScreenSize.compact => 16,
        ScreenSize.medium => 24,
        ScreenSize.expanded => 32,
      };

  /// Column count for the list-of-cards layouts.
  int get listColumns => switch (screen) {
        ScreenSize.compact => 1,
        ScreenSize.medium => 2,
        ScreenSize.expanded => 2,
      };
}

/// Centres and width-limits page content on large screens, and applies the
/// responsive horizontal padding. Use this instead of hand-rolled EdgeInsets.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// A list that becomes a multi-column masonry-ish grid on wide screens while
/// staying a plain, fast [ListView] on phones.
class AdaptiveCardList extends StatelessWidget {
  const AdaptiveCardList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.header,
    this.spacing = 10,
    this.controller,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets? padding;
  final Widget? header;
  final double spacing;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final columns = context.listColumns;
    final pad = padding ??
        EdgeInsets.fromLTRB(context.pagePadding, 12, context.pagePadding, 24);

    if (columns == 1) {
      return PageBody(
        child: ListView.separated(
          controller: controller,
          padding: pad,
          itemCount: itemCount + (header == null ? 0 : 1),
          separatorBuilder: (_, __) => SizedBox(height: spacing),
          itemBuilder: (context, i) {
            if (header != null) {
              if (i == 0) return header!;
              return itemBuilder(context, i - 1);
            }
            return itemBuilder(context, i);
          },
        ),
      );
    }

    // Distribute items across columns round-robin so each column grows evenly
    // regardless of individual card height.
    final buckets = List.generate(columns, (_) => <int>[]);
    for (var i = 0; i < itemCount; i++) {
      buckets[i % columns].add(i);
    }

    return PageBody(
      child: SingleChildScrollView(
        controller: controller,
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) header!,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) SizedBox(width: spacing),
                  Expanded(
                    child: Column(
                      children: [
                        for (final i in buckets[c]) ...[
                          itemBuilder(context, i),
                          SizedBox(height: spacing),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
