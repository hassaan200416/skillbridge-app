// ---------------------------------------------------------------------------
// app_colors.dart
//
// Purpose: Centralized color palette for SkillBridge.
// All colors used across the app must come from here.
// Never hardcode colors in widgets.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand colors
  static const Color primary = Color(0xFF1D9E75);
  static const Color primaryDark = Color(0xFF0F6E56);
  static const Color primaryLight = Color(0xFF5DCAA5);

  static const Color secondary = Color(0xFF0D1B2A);
  static const Color secondaryLight = Color(0xFF1A3347);

  static const Color accent = Color(0xFFEF9F27);
  static const Color accentDark = Color(0xFFBA7517);

  // Semantic colors
  static const Color error = Color(0xFFE24B4A);
  static const Color errorLight = Color(0xFFFCEBEB);
  static const Color success = Color(0xFF1D9E75);
  static const Color successLight = Color(0xFFE1F5EE);
  static const Color warning = Color(0xFFEF9F27);
  static const Color warningLight = Color(0xFFFAEEDA);
  static const Color info = Color(0xFF378ADD);
  static const Color infoLight = Color(0xFFE6F1FB);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // Background colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // Role-specific colors
  static const Color customerColor = Color(0xFF378ADD);
  static const Color providerColor = Color(0xFF1D9E75);
  static const Color adminColor = Color(0xFFD85A30);

  // Status colors for booking badges
  static const Color statusPending = Color(0xFFEF9F27);
  static const Color statusConfirmed = Color(0xFF1D9E75);
  static const Color statusCompleted = Color(0xFF378ADD);
  static const Color statusCancelled = Color(0xFFE24B4A);
  static const Color statusDisputed = Color(0xFFD85A30);

  // Star rating color
  static const Color starColor = Color(0xFFEF9F27);

  // Divider and border
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderFocus = Color(0xFF1D9E75);

  // Shadow
  static const Color shadow = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
}
