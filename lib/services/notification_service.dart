// Notification sending helper for booking and review events.
// This service turns booking and review changes into the correct in-app
// notification records. Screens never call the repository directly for these
// flows; they call this service so the business rules stay in one place.
//
// If notification creation fails, the booking or review action still succeeds.
// That keeps notifications helpful without making them a hard dependency.

import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _repo = NotificationRepository.instance;

  /// Tells the provider that a customer has created a new booking request.
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

  /// Tells the customer that the provider confirmed the booking.
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

  /// Tells the customer that the provider rejected the booking.
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

  /// Tells the customer that the booking is complete and ready for review.
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

  /// Tells the other party that a booking was cancelled.
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

  /// Tells the provider that a customer left a review.
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
