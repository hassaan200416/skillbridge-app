
// ---------------------------------------------------------------------------
// review_model.dart
//
// Purpose: Immutable data model representing a service review.
// Maps directly to the public.reviews table in Supabase.
//
// Constraint: One review per booking — enforced by UNIQUE on booking_id.
// Reviews are editable for 24 hours after submission (is_editable flag).
//
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

@immutable
class ReviewModel {
  final String id;
  final String bookingId;
  final String serviceId;
  final String customerId;
  final String providerId;
  final int rating;
  final String? comment;
  final bool isEditable;
  final bool isFlagged;
  final String? flagReason;
  final int flagCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional joined data
  final String? customerName;
  final String? customerAvatarUrl;
  final String? customerEmail;
  final String? serviceName;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.serviceId,
    required this.customerId,
    required this.providerId,
    required this.rating,
    this.comment,
    this.isEditable = true,
    this.isFlagged = false,
    this.flagReason,
    this.flagCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.customerName,
    this.customerAvatarUrl,
    this.customerEmail,
    this.serviceName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final customerData = json['customer'] as Map<String, dynamic>?;

    return ReviewModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      serviceId: json['service_id'] as String,
      customerId: json['customer_id'] as String,
      providerId: json['provider_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      isEditable: json['is_editable'] as bool? ?? false,
      isFlagged: json['is_flagged'] as bool? ?? false,
      flagReason: json['flag_reason'] as String?,
      flagCount: json['flag_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      customerName: customerData?['name'] as String?,
      customerAvatarUrl: customerData?['avatar_url'] as String?,
      customerEmail: customerData?['email'] as String?,
      serviceName:
          (json['service'] as Map<String, dynamic>?)?['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'service_id': serviceId,
      'customer_id': customerId,
      'provider_id': providerId,
      'rating': rating,
      'comment': comment,
    };
  }

  ReviewModel copyWith({
    String? id,
    String? bookingId,
    String? serviceId,
    String? customerId,
    String? providerId,
    int? rating,
    String? comment,
    bool? isEditable,
    bool? isFlagged,
    String? flagReason,
    int? flagCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
    String? customerAvatarUrl,
    String? customerEmail,
    String? serviceName,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      serviceId: serviceId ?? this.serviceId,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isEditable: isEditable ?? this.isEditable,
      isFlagged: isFlagged ?? this.isFlagged,
      flagReason: flagReason ?? this.flagReason,
      flagCount: flagCount ?? this.flagCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      customerAvatarUrl: customerAvatarUrl ?? this.customerAvatarUrl,
      customerEmail: customerEmail ?? this.customerEmail,
      serviceName: serviceName ?? this.serviceName,
    );
  }

  /// Whether this review can still be edited (within 24 hours)
  bool get canEdit =>
      isEditable && DateTime.now().difference(createdAt).inHours < 24;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ReviewModel(id: $id, rating: $rating)';
}
