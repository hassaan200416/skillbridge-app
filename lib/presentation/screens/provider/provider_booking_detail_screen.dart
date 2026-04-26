// ---------------------------------------------------------------------------
// provider_booking_detail_screen.dart
//
// Purpose: Provider-facing booking detail view. Redesigned web UI from
//   Stitch mockups. Shows booking summary (service, price, schedule,
//   location, customer info, requirements) and a context-aware action
//   panel that changes based on booking status.
//
// Route: /p/booking/:id  (OUTSIDE ProviderShell - provides own Scaffold)
//
// Actions via bookingActionProvider:
//   - pending   -> Accept Booking / Decline Request (with reason dialog)
//   - confirmed -> Mark as Completed
//   - completed/cancelled/disputed -> read-only with context
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/booking_model.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/app_top_bar.dart';

// -- Design Tokens -----------------------------------------------------------
const _kPrimary = Color(0xFF2D9B6F);
const _kSecondary = Color(0xFF1A2B3C);
const _kBg = Color(0xFFF5F7FA);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);

// Status badge colors (from design system)
const _kPendBg = Color(0xFFFEF3C7);
const _kPendFg = Color(0xFFD97706);
const _kConfBg = Color(0xFFD1FAE5);
const _kConfFg = Color(0xFF065F46);
const _kCompBg = Color(0xFFDBEAFE);
const _kCompFg = Color(0xFF1E40AF);
const _kCancBg = Color(0xFFFEE2E2);
const _kCancFg = Color(0xFF991B1B);

class ProviderBookingDetailScreen extends ConsumerWidget {
  const ProviderBookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= 800;

    // Error/success listener for actions
    ref.listen(bookingActionProvider, (prev, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking updated'),
            backgroundColor: _kPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(bookingDetailProvider(bookingId));
      }
      if (next.error != null) {
        debugPrint('[BookingAction] ${next.error!.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!.message),
            backgroundColor: _kCancFg,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: _kBg,
      body: Row(
        children: [
          if (showSidebar)
            const AppSidebar(
              role: UserRole.provider,
              currentRoute: '/provider-booking',
            ),
          Expanded(
            child: bookingAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _kPrimary)),
              error: (e, _) => _ErrorView(message: e.toString()),
              data: (booking) => _DetailContent(booking: booking),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// MAIN CONTENT
// ===========================================================================

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.booking});
  final BookingModel booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(userProfileProvider(booking.customerId));
    final width = MediaQuery.sizeOf(context).width;
    final useTwoColumn = width >= 1100;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppTopBar(),
          const SizedBox(height: 24),
          _HeaderRow(booking: booking),
          const SizedBox(height: 24),
          if (useTwoColumn)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _LeftColumn(
                      booking: booking,
                      customer: customerAsync,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: _RightColumn(
                      booking: booking,
                      customer: customerAsync,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LeftColumn(booking: booking, customer: customerAsync),
                const SizedBox(height: 20),
                _RightColumn(booking: booking, customer: customerAsync),
              ],
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// -- Header: back button + booking id + status pill ------------------------

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.booking});
  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final idShort = booking.id.length >= 4
        ? booking.id.substring(booking.id.length - 4).toUpperCase()
        : booking.id.toUpperCase();
    final received = _relativeTime(booking.createdAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackButton(
          onTap: () =>
              context.canPop() ? context.pop() : context.go('/p/bookings'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking #SB-$idShort',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Received $received',
                style: GoogleFonts.inter(fontSize: 13, color: _kMuted),
              ),
            ],
          ),
        ),
        _StatusPill(status: booking.status),
      ],
    );
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    return DateFormat('MMM d, y').format(t);
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back, color: _kInk, size: 20),
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
      BookingStatus.pending => (_kPendBg, _kPendFg, 'PENDING APPROVAL'),
      BookingStatus.confirmed => (_kConfBg, _kConfFg, 'CONFIRMED'),
      BookingStatus.completed => (_kCompBg, _kCompFg, 'COMPLETED'),
      BookingStatus.cancelled => (_kCancBg, _kCancFg, 'CANCELLED'),
      BookingStatus.disputed => (_kCancBg, _kCancFg, 'DISPUTED'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
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

// ===========================================================================
// LEFT COLUMN: service card, schedule/location, customer requirements
// ===========================================================================

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.booking, required this.customer});
  final BookingModel booking;
  final AsyncValue<UserModel> customer;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final stackBlocks = width < 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ServiceCard(booking: booking),
        const SizedBox(height: 20),
        if (stackBlocks)
          Column(
            children: [
              _ScheduleCard(booking: booking),
              const SizedBox(height: 12),
              _LocationCard(customer: customer),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _ScheduleCard(booking: booking)),
              const SizedBox(width: 12),
              Expanded(child: _LocationCard(customer: customer)),
            ],
          ),
        if ((booking.note ?? '').isNotEmpty) ...[
          const SizedBox(height: 20),
          _RequirementsCard(note: booking.note!),
        ],
        if (booking.status == BookingStatus.cancelled &&
            (booking.rejectionReason ?? '').isNotEmpty) ...[
          const SizedBox(height: 20),
          _RejectionCard(reason: booking.rejectionReason!),
        ],
      ],
    );
  }
}

// -- Service card (image + title + description + price) --------------------

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.booking});
  final BookingModel booking;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image header
          AspectRatio(
            aspectRatio: 16 / 6,
            child: _ServiceImage(url: booking.serviceImageUrl),
          ),
          // Title + description + price
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName ?? 'Service',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _kInk,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Booked on ${DateFormat('MMM d, y').format(booking.createdAt)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _kMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'PRICE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PKR ${NumberFormat('#,###').format(booking.priceAtBooking)}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceImage extends StatelessWidget {
  const _ServiceImage({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: _kSecondary,
        child: const Center(
          child: Icon(Icons.handyman_outlined, color: Colors.white30, size: 48),
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: _kSecondary,
        child: const Center(
          child: Icon(Icons.broken_image_outlined,
              color: Colors.white30, size: 48),
        ),
      ),
    );
  }
}

// -- Schedule / Location mini-cards ----------------------------------------

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.booking});
  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final slotLabel = switch (booking.timeSlot) {
      TimeSlot.morning => 'Morning',
      TimeSlot.afternoon => 'Afternoon',
      TimeSlot.evening => 'Evening',
    };
    return _InfoTile(
      icon: Icons.calendar_today_outlined,
      label: 'Schedule',
      primary: DateFormat('EEE, MMM d, y').format(booking.bookingDate),
      secondary: '$slotLabel slot',
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.customer});
  final AsyncValue<UserModel> customer;

  @override
  Widget build(BuildContext context) {
    final city = customer.whenOrNull(data: (u) => u.city) ?? 'Not specified';
    return _InfoTile(
      icon: Icons.location_on_outlined,
      label: 'Location',
      primary: city,
      secondary: 'Customer area',
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.primary,
    required this.secondary,
  });
  final IconData icon;
  final String label;
  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4F9),
        borderRadius: BorderRadius.circular(14),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _kPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            primary,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            secondary,
            style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

// -- Customer requirements --------------------------------------------------

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sticky_note_2_outlined,
                  color: _kPendFg,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Customer Requirements',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: const Border(left: BorderSide(color: _kPendFg, width: 3)),
            ),
            child: Text(
              '"$note"',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _kInk,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Rejection reason (cancelled state) ------------------------------------

class _RejectionCard extends StatelessWidget {
  const _RejectionCard({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCancBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined, color: _kCancFg, size: 18),
              const SizedBox(width: 8),
              Text(
                'Cancellation Reason',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kCancFg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: GoogleFonts.inter(fontSize: 13, color: _kCancFg),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// RIGHT COLUMN: action panel + customer card
// ===========================================================================

class _RightColumn extends ConsumerWidget {
  const _RightColumn({required this.booking, required this.customer});
  final BookingModel booking;
  final AsyncValue<UserModel> customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionPanel(booking: booking),
        const SizedBox(height: 16),
        _CustomerCard(booking: booking, customer: customer),
      ],
    );
  }
}

// -- Action panel (context-aware) ------------------------------------------

class _ActionPanel extends ConsumerStatefulWidget {
  const _ActionPanel({required this.booking});
  final BookingModel booking;

  @override
  ConsumerState<_ActionPanel> createState() => _ActionPanelState();
}

class _ActionPanelState extends ConsumerState<_ActionPanel> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final currentUser = ref.watch(currentUserProvider);

    Widget body;
    switch (b.status) {
      case BookingStatus.pending:
        body = _pendingBody(currentUser);
        break;
      case BookingStatus.confirmed:
        body = _confirmedBody(currentUser);
        break;
      case BookingStatus.completed:
        body = _readOnlyBody(
          title: 'Booking Completed',
          subtitle:
              'This booking was marked as completed. Customers can now leave a review.',
          icon: Icons.check_circle_outline,
        );
        break;
      case BookingStatus.cancelled:
        body = _readOnlyBody(
          title: 'Booking Cancelled',
          subtitle: 'This booking is no longer active.',
          icon: Icons.cancel_outlined,
        );
        break;
      case BookingStatus.disputed:
        body = _readOnlyBody(
          title: 'Under Dispute',
          subtitle:
              'An admin is reviewing this booking. You will be notified of the outcome.',
          icon: Icons.gavel_outlined,
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _kSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: body,
    );
  }

  // -- Pending: Accept + Decline --
  Widget _pendingBody(UserModel? currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Review Booking',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Respond to this request to lock in the schedule. '
          'The customer will be notified as soon as you decide.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryActionBtn(
          icon: Icons.check_circle,
          label: 'Accept Booking',
          busy: _busy,
          onTap: () => _accept(currentUser),
        ),
        const SizedBox(height: 10),
        _SecondaryActionBtn(
          icon: Icons.cancel,
          label: 'Decline Request',
          busy: _busy,
          onTap: () => _showRejectDialog(currentUser),
        ),
      ],
    );
  }

  // -- Confirmed: Mark Complete --
  Widget _confirmedBody(UserModel? currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Booking Confirmed',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'When the service is delivered, mark it as completed so the customer '
          'can leave a review.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryActionBtn(
          icon: Icons.task_alt,
          label: 'Mark as Completed',
          busy: _busy,
          onTap: () => _complete(currentUser),
        ),
      ],
    );
  }

  // -- Read-only --
  Widget _readOnlyBody({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // -- Actions --

  Future<void> _accept(UserModel? user) async {
    if (user == null || _busy) return;
    setState(() => _busy = true);
    await ref.read(bookingActionProvider.notifier).acceptBooking(
          bookingId: widget.booking.id,
          customerId: widget.booking.customerId,
          providerId: widget.booking.providerId,
          serviceName: widget.booking.serviceName ?? 'your service',
        );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _complete(UserModel? user) async {
    if (user == null || _busy) return;
    setState(() => _busy = true);
    await ref.read(bookingActionProvider.notifier).completeBooking(
          bookingId: widget.booking.id,
          customerId: widget.booking.customerId,
          providerId: widget.booking.providerId,
          serviceName: widget.booking.serviceName ?? 'your service',
        );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _showRejectDialog(UserModel? user) async {
    if (user == null) return;
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Decline booking',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Reason (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(null),
            child: Text('Cancel', style: GoogleFonts.inter(color: _kMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kCancFg),
            onPressed: () => Navigator.of(dctx).pop(ctrl.text.trim()),
            child: Text(
              'Decline',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (reason == null) return; // user cancelled
    setState(() => _busy = true);
    await ref.read(bookingActionProvider.notifier).rejectBooking(
          bookingId: widget.booking.id,
          customerId: widget.booking.customerId,
          providerId: widget.booking.providerId,
          serviceName: widget.booking.serviceName ?? 'your service',
          reason: reason.isEmpty ? null : reason,
        );
    if (mounted) setState(() => _busy = false);
  }
}

class _PrimaryActionBtn extends StatelessWidget {
  const _PrimaryActionBtn({
    required this.icon,
    required this.label,
    required this.busy,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _kPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: busy ? null : onTap,
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SecondaryActionBtn extends StatelessWidget {
  const _SecondaryActionBtn({
    required this.icon,
    required this.label,
    required this.busy,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: busy ? null : onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Customer card ----------------------------------------------------------

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.booking, required this.customer});
  final BookingModel booking;
  final AsyncValue<UserModel> customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: customer.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator(color: _kPrimary)),
        ),
        error: (_, __) => Text(
          'Could not load customer info',
          style: GoogleFonts.inter(color: _kMuted, fontSize: 13),
        ),
        data: (u) {
          final phone = u.phone;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(
                    url: booking.customerAvatarUrl ?? u.avatarUrl,
                    name: u.name.isNotEmpty ? u.name : booking.customerName,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.name.isNotEmpty
                              ? u.name
                              : (booking.customerName ?? 'Customer'),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          u.city ?? 'City not set',
                          style:
                              GoogleFonts.inter(fontSize: 12, color: _kMuted),
                        ),
                      ],
                    ),
                  ),
                  if (u.isVerified)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: _kPrimary, shape: BoxShape.circle),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 12),
                    ),
                ],
              ),
              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(height: 20),
                _ContactRow(
                  icon: Icons.phone_outlined,
                  label: 'CONTACT',
                  value: phone,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});
  final String? url;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final initial = (name?.isNotEmpty ?? false) ? name![0].toUpperCase() : '?';
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: _kBorder,
        backgroundImage: NetworkImage(url!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: _kPrimary.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: _kPrimary,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _kPrimary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -- Error view -------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _kCancFg, size: 48),
            const SizedBox(height: 12),
            Text(
              'Could not load booking',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _kMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
