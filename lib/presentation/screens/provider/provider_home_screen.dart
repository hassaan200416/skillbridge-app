
// ---------------------------------------------------------------------------
// provider_home_screen.dart
//
// Purpose: Provider dashboard — welcome, 4 metric cards, recent bookings,
// pending requests with accept/decline actions. All data from real providers.
// No fake priority/location/trend fields.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/service_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/booking_provider.dart';
import '../../../presentation/providers/service_provider.dart';
import '../../widgets/common/provider_skillbot_widget.dart';

class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final bookingsAsync = ref.watch(providerBookingsProvider(user.id));
    final servicesAsync = ref.watch(providerServicesProvider(user.id));

    // Listen for booking action errors/successes
    ref.listen(bookingActionProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: ${next.error!.message}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.isSuccess && next.result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking updated'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Force refresh the bookings list
        ref.invalidate(providerBookingsProvider(user.id));
      }
    });

    return ProviderSkillBotWidget(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Greeting(
              name: user.name,
              bookingsAsync: bookingsAsync,
            ),
            const SizedBox(height: 24),
            _MetricCards(
              bookingsAsync: bookingsAsync,
              servicesAsync: servicesAsync,
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left 60% — recent bookings
                Expanded(
                  flex: 60,
                  child: _RecentBookingsSection(bookingsAsync: bookingsAsync),
                ),
                const SizedBox(width: 24),
                // Right 40% — pending requests
                Expanded(
                  flex: 40,
                  child: _PendingRequestsSection(
                    bookingsAsync: bookingsAsync,
                    providerId: user.id,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Greeting ──────────────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.bookingsAsync,
  });
  final String name;
  final AsyncValue<List<BookingModel>> bookingsAsync;

  @override
  Widget build(BuildContext context) {
    final pending = bookingsAsync.valueOrNull
            ?.where((b) => b.status == BookingStatus.pending)
            .length ??
        0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back, $name',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            )),
        const SizedBox(height: 4),
        if (pending > 0)
          Text.rich(TextSpan(
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.grey500,
            ),
            children: [
              const TextSpan(text: 'You have '),
              TextSpan(
                text: '$pending new request${pending == 1 ? '' : 's'}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const TextSpan(text: ' to review today.'),
            ],
          ))
        else
          Text('No pending requests right now. Check in later.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.grey500,
              )),
      ],
    );
  }
}

// ── Metric Cards ──────────────────────────────────────────────────────────────

class _MetricCards extends StatelessWidget {
  const _MetricCards({
    required this.bookingsAsync,
    required this.servicesAsync,
  });
  final AsyncValue<List<BookingModel>> bookingsAsync;
  final AsyncValue<List<ServiceModel>> servicesAsync;

  @override
  Widget build(BuildContext context) {
    final bookings = bookingsAsync.valueOrNull ?? [];
    final services = servicesAsync.valueOrNull ?? [];

    final total = bookings.length;
    final pending =
        bookings.where((b) => b.status == BookingStatus.pending).length;
    final activeServices = services.where((s) => s.isActive).length;
    final earnings = bookings
        .where((b) => b.status == BookingStatus.completed)
        .fold<double>(0, (sum, b) => sum + b.priceAtBooking);

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.calendar_today_outlined,
            iconBg: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF0369A1),
            label: 'Total Bookings',
            value: '$total',
            highlighted: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            icon: Icons.pending_actions,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            label: 'Pending Requests',
            value: pending.toString().padLeft(2, '0'),
            highlighted: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            icon: Icons.handyman_outlined,
            iconBg: AppColors.grey100,
            iconColor: AppColors.grey600,
            label: 'Active Services',
            value: activeServices.toString().padLeft(2, '0'),
            highlighted: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            icon: Icons.account_balance_wallet_outlined,
            iconBg: AppColors.white.withValues(alpha: 0.2),
            iconColor: Colors.white,
            label: 'Total Earnings',
            value: 'PKR ${NumberFormat('#,###').format(earnings)}',
            highlighted: true,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.highlighted,
  });
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: highlighted ? Colors.transparent : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 18),
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: highlighted
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.grey500,
              )),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: highlighted ? Colors.white : AppColors.secondary,
              )),
        ],
      ),
    );
  }
}

// ── Recent Bookings Section ───────────────────────────────────────────────────

class _RecentBookingsSection extends StatelessWidget {
  const _RecentBookingsSection({required this.bookingsAsync});
  final AsyncValue<List<BookingModel>> bookingsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Bookings',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                )),
            TextButton(
              onPressed: () => context.go(RouteNames.incomingBookings),
              child: Text('View All',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        bookingsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (bookings) {
            // Show latest non-pending first, but filter to any status
            final recent = [...bookings]
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final displayed = recent.take(4).toList();

            if (displayed.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 40, color: AppColors.grey300),
                    const SizedBox(height: 10),
                    Text('No bookings yet',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey500,
                        )),
                    Text('Your first bookings will appear here',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.grey400)),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: displayed.map((b) {
                  final isLast = b == displayed.last;
                  return _RecentBookingRow(
                    booking: b,
                    isLast: isLast,
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RecentBookingRow extends StatelessWidget {
  const _RecentBookingRow({
    required this.booking,
    required this.isLast,
  });
  final BookingModel booking;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final rawName = booking.customerName?.trim();
    final initials = (rawName != null && rawName.isNotEmpty)
        ? rawName.substring(0, 1).toUpperCase()
        : 'C';
    return InkWell(
      onTap: () => context.go('/provider-booking/${booking.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFFEF3C7),
              child: Text(
                initials,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD97706),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.customerName ?? 'Customer',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      )),
                  Text(booking.serviceName ?? 'Service',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.grey500,
                      )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(
                          DateFormat('MMM d, h:mm a')
                              .format(booking.bookingDate),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.grey500,
                          )),
                      const SizedBox(width: 10),
                      Text('PKR ${booking.priceAtBooking.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            _StatusBadge(status: booking.status),
          ],
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
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

// ── Pending Requests Section ──────────────────────────────────────────────────

class _PendingRequestsSection extends StatelessWidget {
  const _PendingRequestsSection({
    required this.bookingsAsync,
    required this.providerId,
  });
  final AsyncValue<List<BookingModel>> bookingsAsync;
  final String providerId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bookingsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (bookings) {
            final pending = bookings
                .where((b) => b.status == BookingStatus.pending)
                .toList();
            return Row(
              children: [
                Text('Pending Requests',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    )),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${pending.length}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        bookingsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (bookings) {
            final pending = bookings
                .where((b) => b.status == BookingStatus.pending)
                .take(3)
                .toList();
            if (pending.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Center(
                  child: Text('All caught up!',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.grey500,
                      )),
                ),
              );
            }
            return Column(
              children: pending
                  .map((b) => _PendingRequestCard(
                        booking: b,
                        providerId: providerId,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _PendingRequestCard extends ConsumerStatefulWidget {
  const _PendingRequestCard({
    required this.booking,
    required this.providerId,
  });
  final BookingModel booking;
  final String providerId;

  @override
  ConsumerState<_PendingRequestCard> createState() =>
      _PendingRequestCardState();
}

class _PendingRequestCardState extends ConsumerState<_PendingRequestCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final providerId = widget.providerId;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('STANDARD',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey500,
                    letterSpacing: 0.8,
                  )),
              Text('PKR ${booking.priceAtBooking.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          Text(booking.serviceName ?? 'Service',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              )),
          const SizedBox(height: 2),
          Text(
              '${booking.customerName ?? 'Customer'} • ${DateFormat('MMM d').format(booking.bookingDate)} • ${booking.timeSlot.displayName}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.grey500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          try {
                            final ok = await ref
                                .read(bookingActionProvider.notifier)
                                .acceptBooking(
                                  bookingId: booking.id,
                                  customerId: booking.customerId,
                                  providerId: providerId,
                                  serviceName: booking.serviceName ?? '',
                                );
                            debugPrint('Accept booking result: $ok');
                            if (ok) {
                              ref.invalidate(
                                  providerBookingsProvider(providerId));
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text('Accept',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _rejectDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Decline',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _rejectDialog(BuildContext context) {
    final booking = widget.booking;
    final providerId = widget.providerId;
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Decline request'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              setState(() => _busy = true);
              try {
                final ok = await ref
                    .read(bookingActionProvider.notifier)
                    .rejectBooking(
                      bookingId: booking.id,
                      customerId: booking.customerId,
                      providerId: providerId,
                      serviceName: booking.serviceName ?? '',
                      reason: reasonCtrl.text.trim(),
                    );
                debugPrint('Reject booking result: $ok');
                if (ok) {
                  ref.invalidate(providerBookingsProvider(providerId));
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
            child: Text('Decline', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

