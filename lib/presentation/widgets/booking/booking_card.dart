
// ---------------------------------------------------------------------------
// booking_card.dart
//
// Purpose: Booking list item card shown in booking history and
// provider incoming bookings screen.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/booking_model.dart';
import '../common/user_avatar.dart';
import 'booking_status_badge.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.isProvider = false,
    this.onTap,
  });

  final BookingModel booking;
  final bool isProvider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = isProvider
        ? booking.customerName ?? 'Customer'
        : booking.providerName ?? 'Provider';
    final avatarUrl =
        isProvider ? booking.customerAvatarUrl : booking.providerAvatarUrl;
    final route = isProvider
        ? '/provider-booking/${booking.id}'
        : '/booking/${booking.id}';

    return GestureDetector(
      onTap: onTap ?? () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Avatar
            UserAvatar(name: displayName, imageUrl: avatarUrl, size: 48),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.serviceName ?? 'Service',
                    style: AppTextStyles.headingSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(booking.bookingDate),
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_outlined,
                          size: 12, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(
                        booking.timeSlot.displayName.split(' ').first,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Status + price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BookingStatusBadge(status: booking.status, compact: true),
                const SizedBox(height: 6),
                Text(
                  'PKR ${booking.priceAtBooking.toStringAsFixed(0)}',
                  style: AppTextStyles.priceSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
