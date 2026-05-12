import 'package:flutter/material.dart';

/// Shared responsive rules for the app.
/// These thresholds decide when the layout should switch between mobile,
/// tablet, and desktop behavior.
abstract class AppBreakpoints {
  static const double compact = 600;
  static const double expanded = 800;

  /// True when the screen is small enough for the mobile layout.
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  /// True when the screen sits between the compact and expanded sizes.
  static bool isMedium(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= compact && w < expanded;
  }

  /// True when the screen should use tablet or desktop layout rules.
  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;

  /// True when the sidebar should stay visible on wider screens.
  static bool showSidebar(BuildContext context) => isExpanded(context);

  /// Returns one of three values based on the current screen width.
  static T value<T>(
    BuildContext context, {
    required T compact,
    T? medium,
    required T expanded,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= AppBreakpoints.expanded) return expanded;
    if (w >= AppBreakpoints.compact) return medium ?? compact;
    return compact;
  }
}
