import 'package:flutter/material.dart';

/// Breakpoint constants for SkillBridge.
/// compact  : < 600px  → phones
/// medium   : 600–799px → large phones / small tablets
/// expanded : ≥ 800px  → tablets / desktop
abstract class AppBreakpoints {
  static const double compact = 600;
  static const double expanded = 800;

  /// True when the screen is phone-sized (< 600px).
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  /// True when the screen is between 600 and 799px.
  static bool isMedium(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= compact && w < expanded;
  }

  /// True when the screen is desktop/tablet (≥ 800px).
  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;

  /// True when sidebar should be visible (≥ 800px).
  /// Matches the threshold already used in app_router.dart.
  static bool showSidebar(BuildContext context) => isExpanded(context);

  /// Returns one of three values based on screen width.
  /// Usage: AppBreakpoints.value(context, compact: 1, medium: 2, expanded: 3)
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
