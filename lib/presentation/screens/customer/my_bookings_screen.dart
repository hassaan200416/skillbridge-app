
// ---------------------------------------------------------------------------
// my_bookings_screen.dart
//
// Purpose: Customer booking history with status tabs and list view.
// Web layout: sidebar + main content with tab filter bar.
//
// ---------------------------------------------------------------------------

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/booking_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/booking_provider.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  BookingStatus? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final bookingsAsync = ref.watch(customerBookingsProvider(currentUser.id));
    return bookingsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (bookings) {
        final filtered = _selectedFilter == null
            ? bookings
            : bookings.where((b) => b.status == _selectedFilter).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(total: bookings.length),
              const SizedBox(height: 20),
              _TabBar(
                selectedFilter: _selectedFilter,
                bookings: bookings,
                onSelect: (f) => setState(() => _selectedFilter = f),
              ),
              const SizedBox(height: 24),
              if (filtered.isEmpty)
                const _EmptyState()
              else
                ...filtered.map((b) => _BookingRowCard(booking: b)),
              const SizedBox(height: 40),
              _BottomCta(),
            ],
          ),
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'My Bookings',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$total',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your active service appointments, track status updates, and view historical transactions.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey500,
          ),
        ),
      ],
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.selectedFilter,
    required this.bookings,
    required this.onSelect,
  });

  final BookingStatus? selectedFilter;
  final List<BookingModel> bookings;
  final void Function(BookingStatus?) onSelect;

  @override
  Widget build(BuildContext context) {
    final tabs = <(BookingStatus?, String)>[
      (null, 'All'),
      (BookingStatus.pending, 'Pending'),
      (BookingStatus.confirmed, 'Confirmed'),
      (BookingStatus.completed, 'Completed'),
      (BookingStatus.cancelled, 'Cancelled'),
    ];

    int countFor(BookingStatus? s) => s == null
        ? bookings.length
        : bookings.where((b) => b.status == s).length;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = selectedFilter == tab.$1;
          final count = countFor(tab.$1);
          return GestureDetector(
            onTap: () => onSelect(tab.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    tab.$2,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.grey500,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : AppColors.grey200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.grey500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Booking Row Card ──────────────────────────────────────────────────────────

class _BookingRowCard extends StatelessWidget {
  const _BookingRowCard({required this.booking});
  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/booking/${booking.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Image thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: booking.serviceImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: booking.serviceImageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  _StatusBadge(status: booking.status),
                  const SizedBox(height: 6),
                  Text(
                    booking.serviceName ?? 'Service',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('MMM d, yyyy').format(booking.bookingDate)} • ${booking.timeSlot.displayName}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Price
            Expanded(
              flex: 1,
              child: Text(
                'PKR ${booking.priceAtBooking.toStringAsFixed(0)}',
                textAlign: TextAlign.end,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // View details link
            TextButton(
              onPressed: () => context.go('/booking/${booking.id}'),
              child: Text(
                'View Details',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grey500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.grey100,
        child: const Icon(Icons.home_repair_service_outlined,
            size: 24, color: AppColors.grey300),
      );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 56, color: AppColors.grey300),
          const SizedBox(height: 14),
          Text(
            'No bookings here yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.grey500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your bookings will appear here once you book a service.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey400),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push(RouteNames.search),
            icon: const Icon(Icons.search, size: 16),
            label: Text('Browse Services',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom CTA ────────────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  static const double _desktopButtonWidth = 220;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 760;
          final ctaButton = ElevatedButton(
            onPressed: () => context.push(RouteNames.search),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Explore Marketplace',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          );

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need to schedule a new service?',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect with trusted providers for your next project.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.grey500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ctaButton,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need to schedule a new service?',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                            Text(
                              'Connect with trusted providers for your next project.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: _desktopButtonWidth,
                        child: ctaButton,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

