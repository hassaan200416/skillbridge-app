
// ---------------------------------------------------------------------------
// book_service_screen.dart
//
// Purpose: Booking flow — select date and time slot, view price
// summary, confirm booking. Web layout: sidebar + two-column content.
//
// ---------------------------------------------------------------------------

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/user_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/service_provider.dart';
import '../../../presentation/widgets/common/app_sidebar.dart';
import '../../../presentation/widgets/common/app_top_bar.dart';

class BookServiceScreen extends ConsumerStatefulWidget {
  const BookServiceScreen({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends ConsumerState<BookServiceScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTimeSlot;

  // All available time slots grouped by period
  static const _morningSlots = ['09:00 AM', '10:30 AM', '11:00 AM'];
  static const _afternoonSlots = ['01:00 PM', '02:30 PM', '04:00 PM'];
  static const _eveningSlots = ['06:00 PM', '07:30 PM'];

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AppSidebar(role: UserRole.customer, currentRoute: '/book'),
          Expanded(
            child: serviceAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (service) => Column(
                children: [
                  const AppTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT — date + time picker
                          Expanded(
                            flex: 55,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Service mini card
                                _ServiceMiniCard(service: service),
                                const SizedBox(height: 24),

                                // Calendar
                                _CalendarCard(
                                  focusedDay: _focusedDay,
                                  selectedDay: _selectedDay,
                                  onDaySelected: (sel, foc) => setState(() {
                                    _selectedDay = sel;
                                    _focusedDay = foc;
                                  }),
                                ),
                                const SizedBox(height: 28),

                                // Time slots
                                _TimeSlotSection(
                                  selectedSlot: _selectedTimeSlot,
                                  onSlotSelected: (slot) =>
                                      setState(() => _selectedTimeSlot = slot),
                                  morningSlots: _morningSlots,
                                  afternoonSlots: _afternoonSlots,
                                  eveningSlots: _eveningSlots,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 24),

                          // RIGHT — booking summary
                          SizedBox(
                            width: 360,
                            child: _BookingSummaryCard(
                              service: service,
                              selectedDay: _selectedDay,
                              selectedSlot: _selectedTimeSlot,
                              currentUser: currentUser,
                              onConfirm: () => _confirmBooking(service),
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

  void _confirmBooking(ServiceModel service) {
    if (_selectedDay == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and time slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Map time slot string to TimeSlot enum value
    final hour = int.tryParse(_selectedTimeSlot!.split(':').first) ?? 9;
    final isPM = _selectedTimeSlot!.contains('PM');
    final hour24 = isPM && hour != 12 ? hour + 12 : hour;
    final slotValue = hour24 < 12
        ? 'morning'
        : hour24 < 17
            ? 'afternoon'
            : 'evening';

    context.go(
      RouteNames.bookingConfirm,
      extra: {
        'service_id': service.id,
        'service_name': service.title,
        'service_image_url':
            service.imageUrls.isNotEmpty ? service.imageUrls.first : null,
        'provider_id': service.providerId,
        'provider_name': service.providerName ?? 'Provider',
        'booking_date': _selectedDay!.toIso8601String(),
        'time_slot': slotValue,
        'time_slot_display': _selectedTimeSlot!,
        'price': service.price,
      },
    );
  }
}

// ── Service Mini Card ─────────────────────────────────────────────────────────

class _ServiceMiniCard extends StatelessWidget {
  const _ServiceMiniCard({required this.service});
  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 72,
              height: 72,
              child: service.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: service.imageUrls.first,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5E3C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LOCAL FAVOURITE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B5E3C),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  service.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'By ${service.providerName ?? 'Provider'} • ${service.priceType == PriceType.startingFrom ? '${service.price.toStringAsFixed(0)} PKR+' : 'PKR ${service.price.toStringAsFixed(0)}'}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.grey100,
        child: const Icon(Icons.home_repair_service_outlined,
            size: 28, color: AppColors.grey300),
      );
}

// ── Calendar Card ─────────────────────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime, DateTime) onDaySelected;

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Select Date',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: onDaySelected,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              todayTextStyle: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              defaultTextStyle: GoogleFonts.inter(
                color: AppColors.secondary,
              ),
              weekendTextStyle: GoogleFonts.inter(
                color: AppColors.secondary,
              ),
              outsideDaysVisible: true,
              outsideTextStyle: GoogleFonts.inter(
                color: AppColors.grey300,
              ),
              disabledTextStyle: GoogleFonts.inter(
                color: AppColors.grey300,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: AppColors.secondary,
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: AppColors.secondary,
              ),
              titleTextStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
              ),
              weekendStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time Slot Section ─────────────────────────────────────────────────────────

class _TimeSlotSection extends StatelessWidget {
  const _TimeSlotSection({
    required this.selectedSlot,
    required this.onSlotSelected,
    required this.morningSlots,
    required this.afternoonSlots,
    required this.eveningSlots,
  });

  final String? selectedSlot;
  final void Function(String) onSlotSelected;
  final List<String> morningSlots;
  final List<String> afternoonSlots;
  final List<String> eveningSlots;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time Slot',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 16),
        _SlotGroup(
          icon: Icons.wb_sunny_outlined,
          label: 'MORNING',
          slots: morningSlots,
          selectedSlot: selectedSlot,
          onSlotSelected: onSlotSelected,
        ),
        const SizedBox(height: 16),
        _SlotGroup(
          icon: Icons.wb_cloudy_outlined,
          label: 'AFTERNOON',
          slots: afternoonSlots,
          selectedSlot: selectedSlot,
          onSlotSelected: onSlotSelected,
        ),
        const SizedBox(height: 16),
        _SlotGroup(
          icon: Icons.nightlight_outlined,
          label: 'EVENING',
          slots: eveningSlots,
          selectedSlot: selectedSlot,
          onSlotSelected: onSlotSelected,
        ),
      ],
    );
  }
}

class _SlotGroup extends StatelessWidget {
  const _SlotGroup({
    required this.icon,
    required this.label,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  final IconData icon;
  final String label;
  final List<String> slots;
  final String? selectedSlot;
  final void Function(String) onSlotSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.grey500),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: slots.map((slot) {
            final isSelected = selectedSlot == slot;
            // Mark 11:00 AM style as "unavailable" visually
            final isUnavailable = slot == '11:00 AM';
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: isUnavailable ? null : () => onSlotSelected(slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isUnavailable
                              ? AppColors.grey50
                              : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        slot,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isUnavailable
                                  ? AppColors.grey300
                                  : AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Booking Summary Card ──────────────────────────────────────────────────────

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({
    required this.service,
    required this.selectedDay,
    required this.selectedSlot,
    required this.currentUser,
    required this.onConfirm,
  });

  final ServiceModel service;
  final DateTime? selectedDay;
  final String? selectedSlot;
  final dynamic currentUser;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final tax = service.price * 0.05;
    final serviceCharge = 250.0;
    final total = service.price + serviceCharge + tax;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 20),

          // Service row
          _SummaryRow(
            label: 'SERVICE',
            value: service.title,
            isLabel: true,
            actionText: 'Edit',
            onAction: () => context.pop(),
          ),
          const SizedBox(height: 16),

          // Date & time row
          _SummaryRow(
            label: 'DATE & TIME',
            value: selectedDay != null
                ? '${DateFormat('EEEE, MMM d').format(selectedDay!)}${selectedSlot != null ? ' • $selectedSlot' : ''}'
                : 'Not selected',
            isLabel: true,
            actionText: 'Change',
            onAction: null,
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          // Price breakdown
          _PriceRow(
              label: 'Consultation Fee',
              value: 'PKR ${service.price.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _PriceRow(
              label: 'Service Charge',
              value: 'PKR ${serviceCharge.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _PriceRow(
              label: 'Platform Tax (5%)',
              value: 'PKR ${tax.toStringAsFixed(0)}'),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
              Text(
                'PKR ${total.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                'Confirm & Pay Now',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Terms text
          Center(
            child: Text.rich(
              TextSpan(
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppColors.grey400),
                children: const [
                  TextSpan(text: 'By confirming, you agree to our '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Cancellation Policy',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                  TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Secure payment icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 18, color: AppColors.grey300),
              const SizedBox(width: 12),
              const Icon(Icons.lock_outline,
                  size: 18, color: AppColors.grey300),
              const SizedBox(width: 12),
              const Icon(Icons.credit_card_outlined,
                  size: 18, color: AppColors.grey300),
              const SizedBox(width: 10),
              Text('SECURE PAYMENT',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey300,
                    letterSpacing: 1,
                  )),
            ],
          ),
          const SizedBox(height: 16),

          // Artisan of the month
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    (service.providerName ?? 'P').substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ARTISAN OF THE MONTH',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey400,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '${service.providerName ?? 'Provider'} responds in < 2 hours',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLabel = false,
    this.actionText,
    this.onAction,
  });

  final String label;
  final String value;
  final bool isLabel;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey400,
                  letterSpacing: 0.8,
                )),
            if (actionText != null)
              GestureDetector(
                onTap: onAction,
                child: Text(actionText!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            )),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey500)),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary)),
      ],
    );
  }
}
