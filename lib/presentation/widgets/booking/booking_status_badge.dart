
// ---------------------------------------------------------------------------
// booking_status_badge.dart
//
// Purpose: Colored status pill for booking cards and detail screens.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/booking_model.dart';

class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final BookingStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (bg, text, label) = _getStyle(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: text),
      ),
    );
  }

  (Color, Color, String) _getStyle(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return (AppColors.warningLight, AppColors.warning, 'Pending');
      case BookingStatus.confirmed:
        return (AppColors.successLight, AppColors.success, 'Confirmed');
      case BookingStatus.completed:
        return (AppColors.infoLight, AppColors.info, 'Completed');
      case BookingStatus.cancelled:
        return (AppColors.errorLight, AppColors.error, 'Cancelled');
      case BookingStatus.disputed:
        return (AppColors.errorLight, AppColors.adminColor, 'Disputed');
    }
  }
}
