
// ---------------------------------------------------------------------------
// booking_detail_screen.dart
//
// Purpose: Shows full booking details with status, actions (cancel,
// review CTA), and provider info. Adapted to DB schema — no location,
// no fake price breakdown, no payment fields.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/user_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/booking_provider.dart';
import '../../../presentation/providers/review_provider.dart';
import '../../../presentation/widgets/common/app_sidebar.dart';
import '../../../presentation/widgets/common/app_top_bar.dart';

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AppSidebar(role: UserRole.customer, currentRoute: '/booking'),
          Expanded(
            child: bookingAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (booking) => Column(
                children: [
                  const AppTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT — details
                          Expanded(
                            flex: 65,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Breadcrumb(),
                                const SizedBox(height: 16),
                                _StatusBadge(status: booking.status),
                                const SizedBox(height: 8),
                                Text(
                                  booking.serviceName ?? 'Service',
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Date + Total cards row
                                _DateAmountRow(booking: booking),

                                const SizedBox(height: 20),

                                // Note card (only if note exists)
                                if (booking.note != null &&
                                    booking.note!.isNotEmpty) ...[
                                  _NoteCard(note: booking.note!),
                                  const SizedBox(height: 20),
                                ],

                                // Provider card
                                _ProviderCard(booking: booking),

                                // Review section (only if completed)
                                if (booking.status ==
                                    BookingStatus.completed) ...[
                                  const SizedBox(height: 28),
                                  _ReviewCtaCard(
                                    bookingId: bookingId,
                                    ref: ref,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 24),

                          // RIGHT — action card
                          SizedBox(
                            width: 320,
                            child: _ActionCard(
                              booking: booking,
                              ref: ref,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Breadcrumb ────────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go(RouteNames.customerHome),
          child: Text('Dashboard',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 16, color: AppColors.grey400),
        ),
        GestureDetector(
          onTap: () => context.go(RouteNames.myBookings),
          child: Text('Bookings',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 16, color: AppColors.grey400),
        ),
        Text('Details',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey500)),
      ],
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      BookingStatus.pending => (
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
          'PENDING'
        ),
      BookingStatus.confirmed => (
          const Color(0xFFD1FAE5),
          const Color(0xFF065F46),
          'CONFIRMED'
        ),
      BookingStatus.completed => (
          const Color(0xFFDBEAFE),
          const Color(0xFF1E40AF),
          'COMPLETED'
        ),
      BookingStatus.cancelled => (
          const Color(0xFFFEE2E2),
          const Color(0xFF991B1B),
          'CANCELLED'
        ),
      BookingStatus.disputed => (
          const Color(0xFFFEE2E2),
          const Color(0xFF7B341E),
          'DISPUTED'
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date + Amount row ─────────────────────────────────────────────────────────

class _DateAmountRow extends StatelessWidget {
  const _DateAmountRow({required this.booking});
  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.calendar_today_outlined,
            label: 'SERVICE DATE',
            value: DateFormat('MMM d, yyyy').format(booking.bookingDate),
            sub: booking.timeSlot.displayName,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _InfoCard(
            icon: Icons.payments_outlined,
            label: 'TOTAL AMOUNT',
            value: 'PKR ${booking.priceAtBooking.toStringAsFixed(0)}',
            sub: 'Price at time of booking',
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });
  final IconData icon;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.grey500),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey500,
                    letterSpacing: 1,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              )),
          const SizedBox(height: 2),
          Text(sub,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.grey500,
              )),
        ],
      ),
    );
  }
}

// ── Note Card ─────────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note_alt_outlined,
                  size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text('Customer Note',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Text(note,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.grey600,
                height: 1.6,
              )),
        ],
      ),
    );
  }
}

// ── Provider Card ─────────────────────────────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.booking});
  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final initials =
        (booking.providerName ?? 'P').substring(0, 1).toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(initials,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                )),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.providerName ?? 'Provider',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.verified,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('Verified Provider',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: OutlinedButton(
              onPressed: () => context.go('/provider/${booking.providerId}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size(0, 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('View Profile',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Review CTA (completed bookings) ──────────────────────────────────────────

class _ReviewCtaCard extends StatelessWidget {
  const _ReviewCtaCard({required this.bookingId, required this.ref});
  final String bookingId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final hasReviewAsync = ref.watch(hasReviewProvider(bookingId));
    return hasReviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (hasReview) {
        if (hasReview) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You\'ve already reviewed this service. Thanks!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Leave a Review',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  )),
              const SizedBox(height: 4),
              Text(
                'Share your experience to help other customers.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grey500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/review/$bookingId'),
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: Text('Write a Review',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Action Card (right column) ────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.booking, required this.ref});
  final BookingModel booking;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking ID row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BOOKING ID',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey400,
                        letterSpacing: 1,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    '#${booking.id.substring(0, 8).toUpperCase()}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: booking.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking ID copied'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_outlined,
                    size: 18, color: AppColors.grey500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 14),

          // Booked on + status-specific content
          _KeyValueRow(
            label: 'Booked on',
            value: DateFormat('dd MMM yyyy').format(booking.createdAt),
          ),
          const SizedBox(height: 10),
          _KeyValueRow(
            label: 'Price',
            value: 'PKR ${booking.priceAtBooking.toStringAsFixed(0)}',
            valueColor: AppColors.primary,
          ),
          const SizedBox(height: 18),

          // Status-specific actions
          ..._buildStatusActions(context, booking),
        ],
      ),
    );
  }

  List<Widget> _buildStatusActions(BuildContext context, BookingModel booking) {
    switch (booking.status) {
      case BookingStatus.pending:
        return [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _confirmCancel(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Cancel Booking',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Provider has 24h to respond.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey400),
            textAlign: TextAlign.center,
          ),
        ];
      case BookingStatus.confirmed:
        return [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Confirmed by provider',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      case BookingStatus.completed:
        return [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.task_alt,
                        size: 18, color: Color(0xFF1E40AF)),
                    const SizedBox(width: 8),
                    Text('Service Completed',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E40AF),
                        )),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Thanks for using SkillBridge.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
          ),
        ];
      case BookingStatus.cancelled:
        return [
          if (booking.rejectionReason != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rejection Reason',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF991B1B),
                      )),
                  const SizedBox(height: 4),
                  Text(booking.rejectionReason!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF991B1B),
                      )),
                ],
              ),
            ),
          ] else
            Text('This booking was cancelled.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grey500,
                )),
        ];
      case BookingStatus.disputed:
        return [
          Text('This booking is under dispute.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.grey500,
              )),
        ];
    }
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cancel booking?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to cancel this booking?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                await ref.read(bookingActionProvider.notifier).cancelBooking(
                      bookingId: booking.id,
                      customerId: user.id,
                      providerId: booking.providerId,
                      serviceName: booking.serviceName ?? '',
                    );
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Cancel booking',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey500)),
        Text(value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.secondary,
            )),
      ],
    );
  }
}

