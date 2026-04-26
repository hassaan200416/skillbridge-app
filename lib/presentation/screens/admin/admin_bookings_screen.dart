// ---------------------------------------------------------------------------
// admin_bookings_screen.dart
//
// Purpose: Platform-wide booking log. Admin read-only view of all bookings
//   with search and status filtering. Admin cannot act on bookings.
//
// Route: /admin/bookings  (inside AdminShell)
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

enum _StatusFilter { all, pending, confirmed, completed, cancelled }

class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  ConsumerState<AdminBookingsScreen> createState() =>
      _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
  String _search = '';
  _StatusFilter _status = _StatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(getAllBookingsProvider);

    return Container(
      color: _kBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bookings',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Platform-wide booking activity',
              style: GoogleFonts.inter(fontSize: 13.5, color: _kMuted),
            ),
            const SizedBox(height: 24),
            _ControlsRow(
              search: _search,
              status: _status,
              onSearchChanged: (v) => setState(() => _search = v),
              onStatusChanged: (s) => setState(() => _status = s),
              count: bookingsAsync.maybeWhen(
                data: (b) => _apply(b).length,
                orElse: () => null,
              ),
            ),
            const SizedBox(height: 20),
            bookingsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child:
                    Center(child: CircularProgressIndicator(color: _kPrimary)),
              ),
              error: (e, _) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kCancBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: _kCancFg, size: 32),
                    const SizedBox(height: 10),
                    Text(
                      'Could not load bookings',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kCancFg,
                      ),
                    ),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: _kCancFg),
                    ),
                  ],
                ),
              ),
              data: (bookings) {
                final filtered = _apply(bookings);
                if (filtered.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 56),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.event_busy,
                              color: _kMuted, size: 26),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No bookings found',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try adjusting your search or filter',
                          style:
                              GoogleFonts.inter(fontSize: 12.5, color: _kMuted),
                        ),
                      ],
                    ),
                  );
                }
                return _BookingsTable(bookings: filtered);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<BookingModel> _apply(List<BookingModel> list) {
    var out = list;
    if (_status != _StatusFilter.all) {
      final match = switch (_status) {
        _StatusFilter.pending => BookingStatus.pending,
        _StatusFilter.confirmed => BookingStatus.confirmed,
        _StatusFilter.completed => BookingStatus.completed,
        _StatusFilter.cancelled => BookingStatus.cancelled,
        _ => null,
      };
      if (match != null) {
        out = out.where((b) => b.status == match).toList();
      }
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      out = out
          .where((b) =>
              (b.serviceName ?? '').toLowerCase().contains(q) ||
              (b.customerName ?? '').toLowerCase().contains(q) ||
              (b.providerName ?? '').toLowerCase().contains(q))
          .toList();
    }
    return out;
  }
}

class _ControlsRow extends StatelessWidget {
  const _ControlsRow({
    required this.search,
    required this.status,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.count,
  });

  final String search;
  final _StatusFilter status;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_StatusFilter> onStatusChanged;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final compact = w < 1000;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchFld(value: search, onChanged: onSearchChanged),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusTabs(current: status, onChanged: onStatusChanged),
                const SizedBox(width: 14),
                if (count != null) _CountPill(count: count!),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
            width: 280,
            child: _SearchFld(value: search, onChanged: onSearchChanged)),
        const SizedBox(width: 14),
        _StatusTabs(current: status, onChanged: onStatusChanged),
        const Spacer(),
        if (count != null) _CountPill(count: count!),
      ],
    );
  }
}

class _SearchFld extends StatelessWidget {
  const _SearchFld({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 13.5, color: _kInk),
      decoration: InputDecoration(
        hintText: 'Search bookings...',
        hintStyle: GoogleFonts.inter(fontSize: 13.5, color: _kMuted),
        prefixIcon: const Icon(Icons.search, size: 18, color: _kMuted),
        filled: true,
        fillColor: _kField,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({required this.current, required this.onChanged});

  final _StatusFilter current;
  final ValueChanged<_StatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _StatusFilter.values.map((s) {
          final active = s == current;
          final label = switch (s) {
            _StatusFilter.all => 'All',
            _StatusFilter.pending => 'Pending',
            _StatusFilter.confirmed => 'Confirmed',
            _StatusFilter.completed => 'Completed',
            _StatusFilter.cancelled => 'Cancelled',
          };

          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: InkWell(
              onTap: () => onChanged(s),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? _kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : _kMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_available, size: 14, color: _kPrimary),
          const SizedBox(width: 6),
          Text(
            '$count bookings',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingsTable extends StatelessWidget {
  const _BookingsTable({required this.bookings});

  final List<BookingModel> bookings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _TH(),
          for (var i = 0; i < bookings.length; i++) ...[
            _TR(booking: bookings[i]),
            if (i < bookings.length - 1)
              const Divider(
                  height: 1, color: _kBorder, indent: 20, endIndent: 20),
          ],
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  const _TH();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _CL('BOOKING')),
          Expanded(flex: 3, child: _CL('SERVICE')),
          Expanded(flex: 2, child: _CL('CUSTOMER')),
          Expanded(flex: 2, child: _CL('PROVIDER')),
          Expanded(flex: 2, child: _CL('AMOUNT', center: true)),
          Expanded(flex: 2, child: _CL('STATUS', center: true)),
          Expanded(flex: 1, child: _CL('', center: true)),
        ],
      ),
    );
  }
}

class _CL extends StatelessWidget {
  const _CL(this.label, {this.center = false});

  final String label;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _kMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _TR extends StatefulWidget {
  const _TR({required this.booking});

  final BookingModel booking;

  @override
  State<_TR> createState() => _TRState();
}

class _TRState extends State<_TR> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final idShort = b.id.length >= 4
        ? b.id.substring(b.id.length - 4).toUpperCase()
        : b.id.toUpperCase();
    final slotLabel = switch (b.timeSlot) {
      TimeSlot.morning => 'Morning',
      TimeSlot.afternoon => 'Afternoon',
      TimeSlot.evening => 'Evening',
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        color: _hover ? _kBg : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#SB-$idShort',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy').format(b.bookingDate),
                    style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kField,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      slotLabel,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _kMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                b.serviceName ?? 'Service',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kInk,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child:
                  _PersonCell(name: b.customerName, url: b.customerAvatarUrl),
            ),
            Expanded(
              flex: 2,
              child:
                  _PersonCell(name: b.providerName, url: b.providerAvatarUrl),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  'PKR ${NumberFormat('#,###').format(b.priceAtBooking)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(child: _BookingPill(status: b.status)),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Tooltip(
                  message: 'View details',
                  child: InkWell(
                    onTap: () => context.go('/admin/booking/${b.id}'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.visibility_outlined,
                          size: 16, color: _kMuted),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonCell extends StatelessWidget {
  const _PersonCell({this.name, this.url});

  final String? name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final init = (name?.isNotEmpty ?? false) ? name![0].toUpperCase() : '?';
    return Row(
      children: [
        if (url != null && url!.isNotEmpty)
          CircleAvatar(
            radius: 14,
            backgroundColor: _kBorder,
            backgroundImage: NetworkImage(url!),
            onBackgroundImageError: (_, __) {},
          )
        else
          CircleAvatar(
            radius: 14,
            backgroundColor: _kPrimary.withValues(alpha: 0.12),
            child: Text(
              init,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: _kPrimary,
                fontSize: 11,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name ?? 'Unknown',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _kInk,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BookingPill extends StatelessWidget {
  const _BookingPill({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
