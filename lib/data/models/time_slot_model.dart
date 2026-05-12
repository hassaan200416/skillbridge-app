// Booking time slot model.
// Stores a start time and whether that slot is still available for booking.
// The booking UI uses this for slot labels, while repositories use it for
// reading and writing availability data from Supabase.

class TimeSlotModel {
  // Creates one bookable time slot.
  const TimeSlotModel({
    required this.startHour,
    required this.startMinute,
    this.isAvailable = true,
  });

  final int startHour;
  final int startMinute;
  // True when users can still select this slot.
  final bool isAvailable;

  // Human-readable time label shown in the booking UI.
  String get displayTime {
    final hour12 = startHour % 12 == 0 ? 12 : startHour % 12;
    final minute = startMinute.toString().padLeft(2, '0');
    final period = startHour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    // Accepts both snake_case and camelCase data so old and new records load.
    return TimeSlotModel(
      startHour: (json['start_hour'] as num?)?.toInt() ??
          (json['startHour'] as num?)?.toInt() ??
          9,
      startMinute: (json['start_minute'] as num?)?.toInt() ??
          (json['startMinute'] as num?)?.toInt() ??
          0,
      isAvailable:
          json['is_available'] as bool? ?? json['isAvailable'] as bool? ?? true,
    );
  }

  // Serializes the slot using the database field names.
  Map<String, dynamic> toJson() => {
        'start_hour': startHour,
        'start_minute': startMinute,
        'is_available': isAvailable,
      };
}
