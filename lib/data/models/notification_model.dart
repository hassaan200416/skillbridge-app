
// ---------------------------------------------------------------------------
// notification_model.dart
//
// Purpose: Immutable data model for in-app notifications.
// Maps directly to the public.notifications table in Supabase.
//
// The data field contains JSON payload for navigation:
//   {"route": "/booking/123", "booking_id": "123"}
//
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

/// Enum matching the notification_type PostgreSQL enum
enum NotificationType {
  bookingReceived,
  bookingConfirmed,
  bookingRejected,
  bookingCompleted,
  bookingCancelled,
  reviewReceived,
  accountSuspended,
  serviceDeactivated,
  platformAnnouncement,
  verifiedBadgeGranted,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.bookingReceived:      return 'booking_received';
      case NotificationType.bookingConfirmed:     return 'booking_confirmed';
      case NotificationType.bookingRejected:      return 'booking_rejected';
      case NotificationType.bookingCompleted:     return 'booking_completed';
      case NotificationType.bookingCancelled:     return 'booking_cancelled';
      case NotificationType.reviewReceived:       return 'review_received';
      case NotificationType.accountSuspended:     return 'account_suspended';
      case NotificationType.serviceDeactivated:   return 'service_deactivated';
      case NotificationType.platformAnnouncement: return 'platform_announcement';
      case NotificationType.verifiedBadgeGranted: return 'verified_badge_granted';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'booking_confirmed':     return NotificationType.bookingConfirmed;
      case 'booking_rejected':      return NotificationType.bookingRejected;
      case 'booking_completed':     return NotificationType.bookingCompleted;
      case 'booking_cancelled':     return NotificationType.bookingCancelled;
      case 'review_received':       return NotificationType.reviewReceived;
      case 'account_suspended':     return NotificationType.accountSuspended;
      case 'service_deactivated':   return NotificationType.serviceDeactivated;
      case 'platform_announcement': return NotificationType.platformAnnouncement;
      case 'verified_badge_granted':return NotificationType.verifiedBadgeGranted;
      default:                      return NotificationType.bookingReceived;
    }
  }
}

@immutable
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;

  /// JSON payload — used for navigation when notification is tapped
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationTypeExtension.fromString(
          json['type'] as String? ?? 'booking_received'),
      title: json['title'] as String,
      body: json['body'] as String,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Route to navigate to when this notification is tapped
  String? get navigationRoute => data['route'] as String?;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'NotificationModel(id: $id, type: ${type.value})';
}
