
// ---------------------------------------------------------------------------
// booking_confirm_screen.dart
//
// Purpose: Review + confirm booking. On confirm, creates the booking
// via bookingActionProvider and transitions inline to a success state.
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
import '../../../data/models/user_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/booking_provider.dart';
import '../../../presentation/widgets/common/app_sidebar.dart';
import '../../../presentation/widgets/common/app_top_bar.dart';

class BookingConfirmScreen extends ConsumerStatefulWidget {
  const BookingConfirmScreen({super.key, required this.bookingData});
  final Map<String, dynamic> bookingData;

  @override
  ConsumerState<BookingConfirmScreen> createState() =>
      _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends ConsumerState<BookingConfirmScreen> {
  bool _confirmed = false;
  String? _createdBookingId;

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingActionProvider);

    ref.listen(bookingActionProvider, (prev, next) {
      if (next.isSuccess && next.result != null && !_confirmed) {
        setState(() {
          _confirmed = true;
          _createdBookingId = next.result!.id;
        });
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final bookingDate =
        DateTime.parse(widget.bookingData['booking_date'] as String);
    final timeSlot =
        TimeSlotExtension.fromString(widget.bookingData['time_slot'] as String);
    final price = (widget.bookingData['price'] as num).toDouble();
    final serviceName =
        widget.bookingData['service_name'] as String? ?? 'Service';
    final providerName =
        widget.bookingData['provider_name'] as String? ?? 'Provider';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AppSidebar(
              role: UserRole.customer, currentRoute: '/book/confirm'),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            // Success checkmark
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check,
                                  size: 44, color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _confirmed
                                  ? 'Booking Request Sent!'
                                  : 'Confirm Your Booking',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                _confirmed
                                    ? 'Your request has been sent to the provider.'
                                    : 'Review details below and confirm to send the request.',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: AppColors.grey500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Summary card
                            _SummaryCard(
                              serviceName: serviceName,
                              providerName: providerName,
                              bookingDate: bookingDate,
                              timeSlot: timeSlot,
                              price: price,
                            ),

                            const SizedBox(height: 20),

                            // Info alert
                            _InfoAlert(confirmed: _confirmed),

                            const SizedBox(height: 28),

                            // Action buttons
                            if (!_confirmed)
                              _ConfirmButton(
                                isLoading: bookingState.isLoading,
                                onConfirm: () =>
                                    _submit(bookingDate, timeSlot, price),
                              )
                            else
                              _PostSuccessButtons(),

                            const SizedBox(height: 20),

                            if (_confirmed && _createdBookingId != null)
                              Text(
                                'Order ID: #${_createdBookingId!.substring(0, 8).toUpperCase()} • Need help? Contact Support',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: AppColors.grey400),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submit(DateTime date, TimeSlot slot, double price) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    ref.read(bookingActionProvider.notifier).createBooking(
          serviceId: widget.bookingData['service_id'] as String,
          customerId: user.id,
          providerId: widget.bookingData['provider_id'] as String,
          bookingDate: date,
          timeSlot: slot,
          servicePrice: price,
          serviceName:
              widget.bookingData['service_name'] as String? ?? 'Service',
        );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.serviceName,
    required this.providerName,
    required this.bookingDate,
    required this.timeSlot,
    required this.price,
  });

  final String serviceName;
  final String providerName;
  final DateTime bookingDate;
  final TimeSlot timeSlot;
  final double price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESERVATION DETAILS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey400,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      serviceName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey400,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'PKR ${price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          // Date & Time row
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'DATE',
                  value: DateFormat('EEEE, MMM d, yyyy').format(bookingDate),
                ),
              ),
              Expanded(
                child: _DetailItem(
                  icon: Icons.access_time,
                  label: 'TIME SLOT',
                  value: timeSlot.displayName,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Provider row
          _DetailItem(
            icon: Icons.person_outline,
            label: 'PROVIDER',
            value: providerName,
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.grey500),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.grey500,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

// ── Info Alert ────────────────────────────────────────────────────────────────

class _InfoAlert extends StatelessWidget {
  const _InfoAlert({required this.confirmed});
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF3182CE), width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF3182CE).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline,
                size: 16, color: Color(0xFF1E40AF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  confirmed
                      ? 'Awaiting Provider Confirmation'
                      : 'Pending Confirmation',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The provider typically responds within 24 hours. You will receive a notification once they confirm or suggest an alternative slot.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF1E40AF),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confirm Button (pre-confirmation) ─────────────────────────────────────────

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.isLoading,
    required this.onConfirm,
  });
  final bool isLoading;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Confirm & Send Request',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Post-Success Buttons ──────────────────────────────────────────────────────

class _PostSuccessButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go(RouteNames.myBookings),
            icon: const Icon(Icons.list_alt, size: 18),
            label: Text('View My Bookings',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.go(RouteNames.customerHome),
            icon: const Icon(Icons.home_outlined, size: 18),
            label: Text('Return Home',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

