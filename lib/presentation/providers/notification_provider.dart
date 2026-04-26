
// ---------------------------------------------------------------------------
// notification_provider.dart
//
// Purpose: Riverpod state for in-app notification feed and unread count.
//
// ---------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/failures.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../services/supabase_service.dart';

// ── Read Providers ────────────────────────────────────────────────────────

/// Realtime notifications stream — updates instantly when new
/// notifications arrive without needing manual refresh
final userNotificationsProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  final supabase = SupabaseService.instance.client;

  final streamController = StreamController<List<NotificationModel>>();

  Future<void> fetchNotifications() async {
    try {
      final data = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final notifications = (data as List<dynamic>)
          .map((json) => NotificationModel.fromJson(
              Map<String, dynamic>.from(json as Map)))
          .toList();

      if (!streamController.isClosed) {
        streamController.add(notifications);
      }
    } catch (e) {
      debugPrint('Notifications fetch error: $e');
    }
  }

  final channel = supabase
      .channel('notifications_$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          fetchNotifications();
        },
      )
      .subscribe();

  fetchNotifications();

  ref.onDispose(() {
    channel.unsubscribe();
    streamController.close();
  });

  return streamController.stream;
});

/// Unread notification count — for bell badge
final unreadCountProvider = FutureProvider.family<int, String>((ref, userId) {
  return NotificationRepository.instance.getUnreadCount(userId);
});

/// Real-time notification stream — rebuilds bell badge on new notifications
final notificationStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return NotificationRepository.instance.watchUnreadNotifications(userId);
});

// ── Actions ───────────────────────────────────────────────────────────────

class NotificationActionNotifier extends StateNotifier<bool> {
  NotificationActionNotifier(this._ref) : super(false);

  final Ref _ref;
  final _repo = NotificationRepository.instance;

  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await _repo.markAsRead(notificationId);
      _ref.invalidate(userNotificationsProvider(userId));
      _ref.invalidate(unreadCountProvider(userId));
    } on Failure {
      // Non-critical
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      state = true;
      await _repo.markAllAsRead(userId);
      _ref.invalidate(userNotificationsProvider(userId));
      _ref.invalidate(unreadCountProvider(userId));
      state = false;
    } on Failure {
      state = false;
    }
  }

  Future<void> deleteNotification({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await _repo.deleteNotification(notificationId);
      _ref.invalidate(userNotificationsProvider(userId));
      _ref.invalidate(unreadCountProvider(userId));
    } catch (_) {}
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _repo.deleteAllNotifications(userId);
      _ref.invalidate(userNotificationsProvider(userId));
      _ref.invalidate(unreadCountProvider(userId));
    } catch (_) {}
  }
}

final notificationActionProvider =
    StateNotifierProvider<NotificationActionNotifier, bool>((ref) {
  return NotificationActionNotifier(ref);
});

// ── Announcements ─────────────────────────────────────────────────────────

/// Active announcements for a user (excluding dismissed)
final announcementsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return NotificationRepository.instance.getActiveAnnouncements(userId);
});
