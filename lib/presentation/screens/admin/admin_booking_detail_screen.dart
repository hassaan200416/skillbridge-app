// ---------------------------------------------------------------------------
// admin_booking_detail_screen.dart
//
// Purpose: Read-only booking detail for admin. Stays inside AdminShell.
//   Shows booking info, service, customer, provider, status. No actions.
//
// Route: /admin/booking/:id  (inside AdminShell)
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/booking_model.dart';
import '../../providers/booking_provider.dart';

const _kPrimary = Color(0xFF2D9B6F);
const _kSecondary = Color(0xFF1A2B3C);
const _kBg = Color(0xFFF5F7FA);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);
const _kField = Color(0xFFEFF4F9);

const _kPendBg = Color(0xFFFEF3C7);
const _kPendFg = Color(0xFFD97706);
const _kConfBg = Color(0xFFD1FAE5);
const _kConfFg = Color(0xFF065F46);
const _kCompBg = Color(0xFFDBEAFE);
const _kCompFg = Color(0xFF1E40AF);
const _kCancBg = Color(0xFFFEE2E2);
const _kCancFg = Color(0xFF991B1B);

class AdminBookingDetailScreen extends ConsumerWidget {
  const AdminBookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Container(
      color: _kBg,
      child: bookingAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kPrimary)),
        error: (e, _) => Center(
          child: Text('Error: $e', style: GoogleFonts.inter(color: _kCancFg)),
        ),
        data: (b) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/admin/bookings'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBorder),
                      ),
                      child:
                          const Icon(Icons.arrow_back, size: 18, color: _kInk),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking #SB-${b.id.substring(b.id.length - 4).toUpperCase()}',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _kInk,
                          ),
                        ),
                        Text(
                          'Admin view - read only',
                          style:
                              GoogleFonts.inter(fontSize: 13, color: _kMuted),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(status: b.status),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (ctx, cons) {
                  final twoCol = cons.maxWidth >= 900;
                  final left = _InfoCard(booking: b);
                  final right = _SummaryCard(booking: b);
                  if (twoCol) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: left),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: right),
                      ],
                    );
                  }
                  return Column(
                      children: [left, const SizedBox(height: 20), right]);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      BookingStatus.pending => (_kPendBg, _kPendFg, 'PENDING'),
      BookingStatus.confirmed => (_kConfBg, _kConfFg, 'CONFIRMED'),
      BookingStatus.completed => (_kCompBg, _kCompFg, 'COMPLETED'),
      BookingStatus.cancelled => (_kCancBg, _kCancFg, 'CANCELLED'),
      BookingStatus.disputed => (_kCancBg, _kCancFg, 'DISPUTED'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.booking});
  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final slot = switch (booking.timeSlot) {
      TimeSlot.morning => 'Morning',
      TimeSlot.afternoon => 'Afternoon',
      TimeSlot.evening => 'Evening',
    };
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Details',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700, color: _kInk),
          ),
          const SizedBox(height: 16),
          _Row('Service', booking.serviceName ?? 'Unknown'),
          _Row('Price',
              'PKR ${NumberFormat('#,###').format(booking.priceAtBooking)}'),
          _Row('Date',
              DateFormat('EEE, dd MMM yyyy').format(booking.bookingDate)),
          _Row('Time Slot', '$slot slot'),
          _Row('Booked On',
              DateFormat('dd MMM yyyy, h:mm a').format(booking.createdAt)),
          if ((booking.note ?? '').isNotEmpty) ...[
            const Divider(color: _kBorder, height: 24),
            Text(
              'Customer Note',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kField,
                borderRadius: BorderRadius.circular(10),
                border:
                    const Border(left: BorderSide(color: _kPendFg, width: 3)),
              ),
              child: Text(
                '"${booking.note}"',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _kInk,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (booking.status == BookingStatus.cancelled &&
              (booking.rejectionReason ?? '').isNotEmpty) ...[
            const Divider(color: _kBorder, height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kCancBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cancellation Reason',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kCancFg,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    booking.rejectionReason!,
                    style: GoogleFonts.inter(fontSize: 13, color: _kCancFg),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500, color: _kMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _kInk),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.booking});
  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: _kSecondary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Parties',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _PartyRow(
            label: 'Customer',
            name: booking.customerName,
            url: booking.customerAvatarUrl,
            onTap: () => context.go('/admin/user/${booking.customerId}'),
          ),
          const SizedBox(height: 12),
          _PartyRow(
            label: 'Provider',
            name: booking.providerName,
            url: booking.providerAvatarUrl,
            onTap: () => context.go('/admin/user/${booking.providerId}'),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => context.go('/admin/service/${booking.serviceId}'),
            child: Text(
              'View Service',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyRow extends StatelessWidget {
  const _PartyRow(
      {required this.label, this.name, this.url, required this.onTap});
  final String label;
  final String? name;
  final String? url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final init = (name?.isNotEmpty ?? false) ? name![0].toUpperCase() : '?';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (url != null && url!.isNotEmpty)
              CircleAvatar(
                radius: 18,
                backgroundColor: _kBorder,
                backgroundImage: NetworkImage(url!),
                onBackgroundImageError: (_, __) {},
              )
            else
              CircleAvatar(
                radius: 18,
                backgroundColor: _kPrimary.withValues(alpha: 0.2),
                child: Text(
                  init,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    name ?? 'Unknown',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 12, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
