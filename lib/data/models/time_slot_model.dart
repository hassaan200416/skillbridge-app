
class TimeSlotModel {
  const TimeSlotModel({
    required this.startHour,
    required this.startMinute,
    this.isAvailable = true,
  });

  final int startHour;
  final int startMinute;
  final bool isAvailable;

  String get displayTime {
    final hour12 = startHour % 12 == 0 ? 12 : startHour % 12;
    final minute = startMinute.toString().padLeft(2, '0');
    final period = startHour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      startHour: (json['start_hour'] as num?)?.toInt() ??
          (json['startHour'] as num?)?.toInt() ??
          9,
      startMinute: (json['start_minute'] as num?)?.toInt() ??
          (json['startMinute'] as num?)?.toInt() ??
          0,
      isAvailable: json['is_available'] as bool? ??
          json['isAvailable'] as bool? ??
          true,
    );
  }

  Map<String, dynamic> toJson() => {
        'start_hour': startHour,
        'start_minute': startMinute,
        'is_available': isAvailable,
      };
}
