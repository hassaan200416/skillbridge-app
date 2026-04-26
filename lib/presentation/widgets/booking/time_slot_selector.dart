
// time_slot_selector.dart
// Widget for displaying and selecting available time slots for a service booking.
// Fetches availability from Supabase and renders a scrollable grid of slots,
// disabling already-booked or passed slots.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/time_slot_model.dart';
import '../../providers/booking_providers.dart';

/// Displays a grid of time slots for the given [serviceId] and [selectedDate].
/// Calls [onSlotSelected] with the chosen [TimeSlotModel] whenever the user taps a slot.
class TimeSlotSelector extends ConsumerWidget {
  const TimeSlotSelector({
    super.key,
    required this.serviceId,
    required this.selectedDate,
    required this.onSlotSelected,
    this.selectedSlot,
  });

  final String serviceId;
  final DateTime selectedDate;
  final ValueChanged<TimeSlotModel?> onSlotSelected;
  final TimeSlotModel? selectedSlot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(
      availableSlotsProvider(
        AvailableSlotsParams(
          serviceId: serviceId,
          date: selectedDate,
        ),
      ),
    );

    return slotsAsync.when(
      loading: () => const _SlotsLoadingShimmer(),
      error: (error, _) => _SlotsErrorState(error: error.toString()),
      data: (slots) {
        if (slots.isEmpty) return const _NoSlotsAvailable();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Times',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.grey800,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) {
                final isSelected = selectedSlot?.startHour == slot.startHour &&
                    selectedSlot?.startMinute == slot.startMinute;
                final isDisabled = !slot.isAvailable || _isSlotInPast(slot);
                return _TimeSlotChip(
                  slot: slot,
                  isSelected: isSelected,
                  isDisabled: isDisabled,
                  onTap: isDisabled
                      ? null
                      : () => onSlotSelected(isSelected ? null : slot),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  bool _isSlotInPast(TimeSlotModel slot) {
    final now = DateTime.now();
    final slotDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      slot.startHour,
      slot.startMinute,
    );
    return slotDateTime.isBefore(now);
  }
}

class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({
    required this.slot,
    required this.isSelected,
    required this.isDisabled,
    this.onTap,
  });

  final TimeSlotModel slot;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDisabled
        ? AppColors.surfaceVariant
        : isSelected
            ? AppColors.primary
            : AppColors.surface;
    final borderColor = isDisabled
        ? AppColors.border
        : isSelected
            ? AppColors.primary
            : AppColors.border;
    final textColor = isDisabled
        ? AppColors.grey400
        : isSelected
            ? Colors.white
            : AppColors.grey800;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          slot.displayTime,
          style: AppTextStyles.bodySmall.copyWith(
            color: textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SlotsLoadingShimmer extends StatelessWidget {
  const _SlotsLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        8,
        (i) => Container(
          width: 80,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _SlotsErrorState extends StatelessWidget {
  const _SlotsErrorState({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Could not load time slots. Please try again.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSlotsAvailable extends StatelessWidget {
  const _NoSlotsAvailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Icon(Icons.schedule_outlined, size: 32, color: AppColors.grey500),
          const SizedBox(height: 8),
          Text(
            'No slots available for this date',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: 4),
          Text(
            'Try selecting a different day',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}

