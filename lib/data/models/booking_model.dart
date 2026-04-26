
// ---------------------------------------------------------------------------
// booking_model.dart
//
// Purpose: Immutable data model representing a service booking.
// Maps directly to the public.bookings table in Supabase.
//
// Note: price_at_booking is immutable after creation — it is a snapshot
// of the service price at booking time, not the current service price.
//
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

/// Enum matching the booking_status PostgreSQL enum
enum BookingStatus { pending, confirmed, completed, cancelled, disputed }

extension BookingStatusExtension on BookingStatus {
  String get value {
    switch (this) {
      case BookingStatus.pending:   return 'pending';
      case BookingStatus.confirmed: return 'confirmed';
      case BookingStatus.completed: return 'completed';
      case BookingStatus.cancelled: return 'cancelled';
      case BookingStatus.disputed:  return 'disputed';
    }
  }

  static BookingStatus fromString(String value) {
    switch (value) {
      case 'confirmed': return BookingStatus.confirmed;
      case 'completed': return BookingStatus.completed;
      case 'cancelled': return BookingStatus.cancelled;
      case 'disputed':  return BookingStatus.disputed;
      default:          return BookingStatus.pending;
    }
  }

  /// Whether this status allows cancellation by customer
  bool get isCancellable => this == BookingStatus.pending;

  /// Whether this status allows writing a review
  bool get isReviewable => this == BookingStatus.completed;
}

/// Enum for time slots
enum TimeSlot { morning, afternoon, evening }

extension TimeSlotExtension on TimeSlot {
  String get value {
    switch (this) {
      case TimeSlot.morning:   return 'morning';
      case TimeSlot.afternoon: return 'afternoon';
      case TimeSlot.evening:   return 'evening';
    }
  }

  String get displayName {
    switch (this) {
      case TimeSlot.morning:   return 'Morning (8AM–12PM)';
      case TimeSlot.afternoon: return 'Afternoon (12PM–5PM)';
      case TimeSlot.evening:   return 'Evening (5PM–9PM)';
    }
  }

  static TimeSlot fromString(String value) {
    switch (value) {
      case 'afternoon': return TimeSlot.afternoon;
      case 'evening':   return TimeSlot.evening;
      default:          return TimeSlot.morning;
    }
  }
}

@immutable
class BookingModel {
  final String id;
  final String serviceId;
  final String customerId;
  final String providerId;
  final DateTime bookingDate;
  final TimeSlot timeSlot;
  final String? note;
  final BookingStatus status;
  final String? rejectionReason;

  /// Immutable price snapshot — never changes after booking is created
  final double priceAtBooking;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional joined data from Supabase queries
  final String? serviceName;
  final String? serviceImageUrl;
  final String? customerName;
  final String? customerAvatarUrl;
  final String? providerName;
  final String? providerAvatarUrl;

  const BookingModel({
    required this.id,
    required this.serviceId,
    required this.customerId,
    required this.providerId,
    required this.bookingDate,
    required this.timeSlot,
    this.note,
    required this.status,
    this.rejectionReason,
    required this.priceAtBooking,
    required this.createdAt,
    required this.updatedAt,
    this.serviceName,
    this.serviceImageUrl,
    this.customerName,
    this.customerAvatarUrl,
    this.providerName,
    this.providerAvatarUrl,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Handle nested joins from Supabase
    final serviceData = json['services'] as Map<String, dynamic>?;
    final customerData = json['customer'] as Map<String, dynamic>?;
    final providerData = json['provider'] as Map<String, dynamic>?;

    return BookingModel(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      customerId: json['customer_id'] as String,
      providerId: json['provider_id'] as String,
      bookingDate: DateTime.parse(json['booking_date'] as String),
      timeSlot: TimeSlotExtension.fromString(
          json['time_slot'] as String? ?? 'morning'),
      note: json['note'] as String?,
      status: BookingStatusExtension.fromString(
          json['status'] as String? ?? 'pending'),
      rejectionReason: json['rejection_reason'] as String?,
      priceAtBooking: (json['price_at_booking'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      serviceName: serviceData?['title'] as String?,
      serviceImageUrl: (serviceData?['image_urls'] as List<dynamic>?)
              ?.firstOrNull as String?,
      customerName: customerData?['name'] as String?,
      customerAvatarUrl: customerData?['avatar_url'] as String?,
      providerName: providerData?['name'] as String?,
      providerAvatarUrl: providerData?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_id': serviceId,
      'customer_id': customerId,
      'provider_id': providerId,
      'booking_date': bookingDate.toIso8601String().split('T').first,
      'time_slot': timeSlot.value,
      'note': note,
      'status': status.value,
      'price_at_booking': priceAtBooking,
    };
  }

  BookingModel copyWith({
    String? id,
    String? serviceId,
    String? customerId,
    String? providerId,
    DateTime? bookingDate,
    TimeSlot? timeSlot,
    String? note,
    BookingStatus? status,
    String? rejectionReason,
    double? priceAtBooking,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serviceName,
    String? serviceImageUrl,
    String? customerName,
    String? customerAvatarUrl,
    String? providerName,
    String? providerAvatarUrl,
  }) {
    return BookingModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      note: note ?? this.note,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      priceAtBooking: priceAtBooking ?? this.priceAtBooking,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serviceName: serviceName ?? this.serviceName,
      serviceImageUrl: serviceImageUrl ?? this.serviceImageUrl,
      customerName: customerName ?? this.customerName,
      customerAvatarUrl: customerAvatarUrl ?? this.customerAvatarUrl,
      providerName: providerName ?? this.providerName,
      providerAvatarUrl: providerAvatarUrl ?? this.providerAvatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BookingModel(id: $id, status: ${status.value})';
}
