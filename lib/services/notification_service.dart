
// ---------------------------------------------------------------------------
// notification_service.dart
//
// Purpose: Coordinates sending in-app notifications when booking
// status changes. Acts as the glue between repositories.
//
// This service is called by the booking providers after status updates.
// It determines who to notify and what message to send.
//
// Architecture note: Direct DB inserts are admin-only via RLS.
// For a production app, this logic would live in a Supabase Edge Function.
// For this project, the admin-logged-in user can send — or we use
// the Supabase service role key in an Edge Function.
// We gracefully skip notification creation if RLS blocks it.
//
// ---------------------------------------------------------------------------

import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _repo = NotificationRepository.instance;

  /// Sends notification when a new booking is created
  /// Notifies: the provider
  Future<void> onBookingCreated({
    required String providerId,
    required String bookingId,
    required String serviceName,
  }) async {
    try {
      await _repo.sendBookingNotification(
        recipientId: providerId,
        type: NotificationType.bookingReceived,
        bookingId: bookingId,
        serviceName: serviceName,
      );
    } catch (_) {
      // Non-critical — booking was created regardless
    }
  }

  /// Sends notification when provider confirms a booking
  /// Notifies: the customer
  Future<void> onBookingConfirmed({
    required String customerId,
    required String bookingId,
    required String serviceName,
  }) async {
    try {
      await _repo.sendBookingNotification(
        recipientId: customerId,
        type: NotificationType.bookingConfirmed,
        bookingId: bookingId,
        serviceName: serviceName,
      );
    } catch (_) {}
  }

  /// Sends notification when provider rejects a booking
  /// Notifies: the customer
  Future<void> onBookingRejected({
    required String customerId,
    required String bookingId,
    required String serviceName,
  }) async {
    try {
      await _repo.sendBookingNotification(
        recipientId: customerId,
        type: NotificationType.bookingRejected,
        bookingId: bookingId,
        serviceName: serviceName,
      );
    } catch (_) {}
  }

  /// Sends notification when booking is marked complete
  /// Notifies: the customer (prompts them to review)
  Future<void> onBookingCompleted({
    required String customerId,
    required String bookingId,
    required String serviceName,
  }) async {
    try {
      await _repo.sendBookingNotification(
        recipientId: customerId,
        type: NotificationType.bookingCompleted,
        bookingId: bookingId,
        serviceName: serviceName,
      );
    } catch (_) {}
  }

  /// Sends notification when a booking is cancelled
  /// Notifies: the other party (whoever did NOT cancel)
  Future<void> onBookingCancelled({
    required String recipientId,
    required String bookingId,
    required String serviceName,
  }) async {
    try {
      await _repo.sendBookingNotification(
        recipientId: recipientId,
        type: NotificationType.bookingCancelled,
        bookingId: bookingId,
        serviceName: serviceName,
      );
    } catch (_) {}
  }

  /// Sends notification when provider receives a review
  Future<void> onReviewReceived({
    required String providerId,
    required String bookingId,
    required String serviceName,
  }) async {
    try {
      await _repo.sendBookingNotification(
        recipientId: providerId,
        type: NotificationType.reviewReceived,
        bookingId: bookingId,
        serviceName: serviceName,
      );
    } catch (_) {}
  }
}
