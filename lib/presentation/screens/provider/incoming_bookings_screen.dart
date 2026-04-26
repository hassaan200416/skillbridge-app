
// ---------------------------------------------------------------------------
// incoming_bookings_screen.dart
//
// Purpose: Provider incoming bookings list with status tabs and
// per-row actions (Accept/Reject/Mark Completed). Right sidebar
// shows real Booking Trends counts. No fake locations, no fake
// forecast, no fake report downloads.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/booking_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/booking_provider.dart';

class IncomingBookingsScreen extends ConsumerStatefulWidget {
  const IncomingBookingsScreen({super.key});

  @override
  ConsumerState<IncomingBookingsScreen> createState() =>
      _IncomingBookingsScreenState();
}

class _IncomingBookingsScreenState
    extends ConsumerState<IncomingBookingsScreen> {
  BookingStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final bookingsAsync = ref.watch(providerBookingsProvider(user.id));

    // Listen for action errors
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
        ref.invalidate(providerBookingsProvider(user.id));
      }
    });

    return bookingsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (bookings) {
        final filtered = _filter == null
            ? bookings
            : bookings.where((b) => b.status == _filter).toList();
        final sorted = [...filtered]
          ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

        final screenWidth = MediaQuery.sizeOf(context).width;
        final showSidebar = screenWidth >= 1200;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                bookings: bookings,
                filter: _filter,
                onFilterChange: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 24),
              if (showSidebar)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 70,
                      child: _BookingsList(
                        bookings: sorted,
                        providerId: user.id,
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 300,
                      child: _BookingTrendsCard(bookings: bookings),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _BookingTrendsCard(bookings: bookings),
                    const SizedBox(height: 20),
                    _BookingsList(
                      bookings: sorted,
                      providerId: user.id,
                    ),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.bookings,
    required this.filter,
    required this.onFilterChange,
  });
  final List<BookingModel> bookings;
  final BookingStatus? filter;
  final void Function(BookingStatus?) onFilterChange;

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        bookings.where((b) => b.status == BookingStatus.pending).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Incoming Bookings',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                )),
            if (pendingCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$pendingCount New',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Review and manage your service requests.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.grey500,
          ),
        ),
        const SizedBox(height: 16),
        // Filter tabs as pill row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _tabPill('All', null, bookings.length),
              const SizedBox(width: 8),
              _tabPill('Pending', BookingStatus.pending,
                  _count(BookingStatus.pending)),
              const SizedBox(width: 8),
              _tabPill('Confirmed', BookingStatus.confirmed,
                  _count(BookingStatus.confirmed)),
              const SizedBox(width: 8),
              _tabPill('Completed', BookingStatus.completed,
                  _count(BookingStatus.completed)),
              const SizedBox(width: 8),
              _tabPill('Cancelled', BookingStatus.cancelled,
                  _count(BookingStatus.cancelled)),
            ],
          ),
        ),
      ],
    );
  }

  int _count(BookingStatus s) => bookings.where((b) => b.status == s).length;

  Widget _tabPill(String label, BookingStatus? status, int count) {
    final selected = filter == status;
    return GestureDetector(
      onTap: () => onFilterChange(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.secondary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.secondary,
                )),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text('$count',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white70 : AppColors.grey500,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Bookings List ─────────────────────────────────────────────────────────────

class _BookingsList extends StatelessWidget {
  const _BookingsList({
    required this.bookings,
    required this.providerId,
  });
  final List<BookingModel> bookings;
  final String providerId;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined,
                size: 56, color: AppColors.grey300),
            const SizedBox(height: 14),
            Text('No bookings to show',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey500,
                )),
          ],
        ),
      );
    }
    return Column(
      children: bookings
          .map((b) => _BookingRow(
                booking: b,
                providerId: providerId,
              ))
          .toList(),
    );
  }
}

class _BookingRow extends ConsumerStatefulWidget {
  const _BookingRow({
    required this.booking,
    required this.providerId,
  });
  final BookingModel booking;
  final String providerId;

  @override
  ConsumerState<_BookingRow> createState() => _BookingRowState();
}

class _BookingRowState extends ConsumerState<_BookingRow> {
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      await ref.read(bookingActionProvider.notifier).acceptBooking(
            bookingId: widget.booking.id,
            customerId: widget.booking.customerId,
            providerId: widget.providerId,
            serviceName: widget.booking.serviceName ?? '',
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Decline booking?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text('Decline', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(bookingActionProvider.notifier).rejectBooking(
            bookingId: widget.booking.id,
            customerId: widget.booking.customerId,
            providerId: widget.providerId,
            serviceName: widget.booking.serviceName ?? '',
            reason: reasonCtrl.text.trim(),
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete() async {
    setState(() => _busy = true);
    try {
      await ref.read(bookingActionProvider.notifier).completeBooking(
            bookingId: widget.booking.id,
            customerId: widget.booking.customerId,
            providerId: widget.providerId,
            serviceName: widget.booking.serviceName ?? '',
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final rawName = b.customerName?.trim();
    final initials = (rawName != null && rawName.isNotEmpty)
        ? rawName.substring(0, 1).toUpperCase()
        : 'C';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go('/provider-booking/${widget.booking.id}'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: avatar + name + service + price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(initials,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            )),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              Text(b.customerName ?? 'Customer',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                  )),
                              _StatusBadge(status: b.status),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(b.serviceName ?? 'Service',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 13, color: AppColors.grey500),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${DateFormat('EEE, MMM d').format(b.bookingDate)} • ${b.timeSlot.displayName}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.grey500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('PKR ${b.priceAtBooking.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            )),
                        Text(
                            b.status == BookingStatus.confirmed
                                ? 'FIXED RATE'
                                : 'ESTIMATED',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.grey500,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            )),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _actionRow(b),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionRow(BookingModel b) {
    if (b.status == BookingStatus.pending) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _accept,
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: Text('Accept Booking',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _busy ? null : _reject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Reject',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    }
    if (b.status == BookingStatus.confirmed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _busy ? null : _complete,
          icon: const Icon(Icons.done_all, size: 16),
          label: Text('Mark as Completed',
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      );
    }
    // completed/cancelled/disputed → view details
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => context.go('/provider-booking/${b.id}'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text('View Details',
            style:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: 0.8,
          )),
    );
  }
}

// ── Booking Trends Card ──────────────────────────────────────────────────────

class _BookingTrendsCard extends StatelessWidget {
  const _BookingTrendsCard({required this.bookings});
  final List<BookingModel> bookings;

  @override
  Widget build(BuildContext context) {
    final confirmed =
        bookings.where((b) => b.status == BookingStatus.confirmed).length;
    final pending =
        bookings.where((b) => b.status == BookingStatus.pending).length;
    final completed =
        bookings.where((b) => b.status == BookingStatus.completed).length;
    final cancelled =
        bookings.where((b) => b.status == BookingStatus.cancelled).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_graph,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text('Booking Trends',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          _trendRow('Confirmed', confirmed, const Color(0xFF065F46)),
          const SizedBox(height: 10),
          _trendRow('Pending', pending, const Color(0xFFD97706)),
          const SizedBox(height: 10),
          _trendRow('Completed', completed, const Color(0xFF1E40AF)),
          const SizedBox(height: 10),
          _trendRow('Cancelled', cancelled, const Color(0xFF991B1B)),
          const SizedBox(height: 18),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  )),
              Text('${bookings.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trendRow(String label, int count, Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grey600,
                )),
          ],
        ),
        Text(count.toString().padLeft(2, '0'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            )),
      ],
    );
  }
}

