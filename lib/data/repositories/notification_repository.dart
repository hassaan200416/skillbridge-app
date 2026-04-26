
// ---------------------------------------------------------------------------
// notification_repository.dart
//
// Purpose: In-app notification management for SkillBridge.
//
// Responsibilities:
//   - Fetch user notifications with pagination
//   - Mark notifications as read (single or all)
//   - Real-time subscription for new notifications
//   - Create notifications (admin/system only via RLS)
//
// Note: Flutter app cannot directly insert notifications for other users
// due to RLS. Notifications are created by database triggers or admin.
// The notification_service.dart handles this at the service layer.
//
// ---------------------------------------------------------------------------

import '../../core/errors/failures.dart';
import '../../services/supabase_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository._();
  static final NotificationRepository instance = NotificationRepository._();

  final _supabase = SupabaseService.instance;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  /// Gets notifications for a user, newest first
  Future<List<NotificationModel>> getUserNotifications(
    String userId, {
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return (data as List<dynamic>)
          .map((json) => NotificationModel.fromJson(
              Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch notifications: $e');
    }
  }

  /// Gets count of unread notifications for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      final data = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (data as List<dynamic>).length;
    } catch (_) {
      // Non-critical — return 0 on failure
      return 0;
    }
  }

  // ── Mark as Read ──────────────────────────────────────────────────────────

  /// Marks a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      throw ServerFailure('Failed to mark notification as read: $e');
    }
  }

  /// Marks all notifications for a user as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw ServerFailure('Failed to mark all notifications as read: $e');
    }
  }
  // ── Delete ────────────────────────────────────────────────────────────────

  /// Deletes a single notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      throw ServerFailure('Failed to delete notification: $e');
    }
  }

  /// Deletes all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _supabase.from('notifications').delete().eq('user_id', userId);
    } catch (e) {
      throw ServerFailure('Failed to delete all notifications: $e');
    }
  }
  // ── Create (System/Admin only) ────────────────────────────────────────────

  /// Creates a notification for a user.
  ///
  /// RLS allows this only for admin users.
  /// For non-admin creates, use Supabase Edge Functions or triggers.
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': type.value,
        'title': title,
        'body': body,
        'data': data,
      });
    } catch (e) {
      throw ServerFailure('Failed to create notification: $e');
    }
  }

  /// Creates booking-related notifications for both parties.
  ///
  /// Called by the service layer after booking status changes.
  /// Admin users can do this — for regular users this goes via
  /// Supabase triggers on the bookings table.
  Future<void> sendBookingNotification({
    required String recipientId,
    required NotificationType type,
    required String bookingId,
    required String serviceName,
  }) async {
    final (title, body) = _getNotificationContent(type, serviceName);
    await createNotification(
      userId: recipientId,
      type: type,
      title: title,
      body: body,
      data: {
        'booking_id': bookingId,
        'route': '/booking/$bookingId',
      },
    );
  }

  // ── Real-time ─────────────────────────────────────────────────────────────

  /// Real-time stream of unread notifications for a user.
  /// UI subscribes to this to show the notification bell badge.
  Stream<List<Map<String, dynamic>>> watchUnreadNotifications(
    String userId,
  ) {
    return _supabase.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  // ── Announcements ─────────────────────────────────────────────────────────

  /// Fetches active announcements not dismissed by this user
  Future<List<Map<String, dynamic>>> getActiveAnnouncements(
      String userId) async {
    try {
      // Get all dismissed announcement IDs for this user
      final dismissedData = await _supabase
          .from('dismissed_announcements')
          .select('announcement_id')
          .eq('user_id', userId);
      final dismissedIds = (dismissedData as List<dynamic>)
          .map((row) => row['announcement_id'] as String)
          .toSet();

      // Get all active announcements
      final data = await _supabase
          .from('announcements')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final all = (data as List<dynamic>)
          .map((json) => Map<String, dynamic>.from(json as Map))
          .toList();

      // Filter out dismissed ones
      return all.where((a) => !dismissedIds.contains(a['id'])).toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch announcements: $e');
    }
  }

  /// Dismiss an announcement for a user
  Future<void> dismissAnnouncement({
    required String userId,
    required String announcementId,
  }) async {
    try {
      await _supabase.from('dismissed_announcements').insert({
        'user_id': userId,
        'announcement_id': announcementId,
      });
    } catch (e) {
      throw ServerFailure('Failed to dismiss announcement: $e');
    }
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  /// Returns (title, body) for each notification type
  (String, String) _getNotificationContent(
    NotificationType type,
    String serviceName,
  ) {
    switch (type) {
      case NotificationType.bookingReceived:
        return (
          'New booking request',
          'You have a new booking for $serviceName'
        );
      case NotificationType.bookingConfirmed:
        return (
          'Booking confirmed',
          'Your booking for $serviceName has been confirmed'
        );
      case NotificationType.bookingRejected:
        return (
          'Booking rejected',
          'Your booking for $serviceName was not accepted'
        );
      case NotificationType.bookingCompleted:
        return (
          'Service completed',
          '$serviceName has been marked as completed'
        );
      case NotificationType.bookingCancelled:
        return (
          'Booking cancelled',
          'A booking for $serviceName was cancelled'
        );
      case NotificationType.reviewReceived:
        return ('New review', 'You received a new review for $serviceName');
      case NotificationType.accountSuspended:
        return ('Account suspended', 'Your account has been suspended');
      case NotificationType.serviceDeactivated:
        return (
          'Service deactivated',
          'Your service "$serviceName" has been deactivated'
        );
      case NotificationType.platformAnnouncement:
        return ('Announcement', serviceName);
      case NotificationType.verifiedBadgeGranted:
        return ('Verified!', 'Your account has been granted a verified badge');
    }
  }
}
