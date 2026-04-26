
// ---------------------------------------------------------------------------
// review_provider.dart
//
// Purpose: Riverpod state management for reviews and ratings.
//
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../services/notification_service.dart';
import '../../core/errors/failures.dart';

// ── Read Providers ────────────────────────────────────────────────────────

/// Reviews for a service — used on service detail screen
final serviceReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, serviceId) {
  return ReviewRepository.instance.getServiceReviews(serviceId);
});

/// Rating breakdown for a service {1: count, 2: count, ...}
final ratingBreakdownProvider =
    FutureProvider.family<Map<int, int>, String>((ref, serviceId) {
  return ReviewRepository.instance.getRatingBreakdown(serviceId);
});

/// All reviews by a customer
final customerReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, customerId) {
  return ReviewRepository.instance.getCustomerReviews(customerId);
});

/// All reviews for a provider
final providerReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, providerId) {
  return ReviewRepository.instance.getProviderReviews(providerId);
});

/// Whether a specific booking already has a review
final hasReviewProvider =
    FutureProvider.family<bool, String>((ref, bookingId) {
  return ReviewRepository.instance.hasReviewForBooking(bookingId);
});

/// Get existing review for a booking (for edit flow)
final bookingReviewProvider =
    FutureProvider.family<ReviewModel?, String>((ref, bookingId) {
  return ReviewRepository.instance.getReviewByBookingId(bookingId);
});

// ── Admin Providers ───────────────────────────────────────────────────────

/// All reviews for admin moderation
final allReviewsProvider = FutureProvider<List<ReviewModel>>((ref) {
  return ReviewRepository.instance.getAllReviews();
});

final flaggedReviewsProvider = FutureProvider<List<ReviewModel>>((ref) {
  return ReviewRepository.instance.getAllReviews(flaggedOnly: true);
});

// ── Review Actions ────────────────────────────────────────────────────────

class ReviewActionState {
  final bool isLoading;
  final Failure? error;
  final ReviewModel? result;
  final bool isSuccess;

  const ReviewActionState({
    this.isLoading = false,
    this.error,
    this.result,
    this.isSuccess = false,
  });

  ReviewActionState copyWith({
    bool? isLoading,
    Failure? error,
    ReviewModel? result,
    bool? isSuccess,
  }) {
    return ReviewActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      result: result ?? this.result,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ReviewActionNotifier extends StateNotifier<ReviewActionState> {
  ReviewActionNotifier(this._ref) : super(const ReviewActionState());

  final Ref _ref;
  final _repo = ReviewRepository.instance;
  final _notifications = NotificationService.instance;

  Future<bool> submitReview({
    required String bookingId,
    required String serviceId,
    required String customerId,
    required String providerId,
    required String serviceName,
    required int rating,
    String? comment,
  }) async {
    state = const ReviewActionState(isLoading: true);
    try {
      final review = await _repo.createReview(
        bookingId: bookingId,
        serviceId: serviceId,
        customerId: customerId,
        providerId: providerId,
        rating: rating,
        comment: comment,
      );
      // Notify provider about new review
      await _notifications.onReviewReceived(
        providerId: providerId,
        bookingId: bookingId,
        serviceName: serviceName,
      );
      // Invalidate related providers
      _ref.invalidate(serviceReviewsProvider(serviceId));
      _ref.invalidate(ratingBreakdownProvider(serviceId));
      _ref.invalidate(providerReviewsProvider(providerId));
      _ref.invalidate(hasReviewProvider(bookingId));
      state = ReviewActionState(isSuccess: true, result: review);

      try {
        await NotificationRepository.instance.createNotification(
          userId: customerId,
          type: NotificationType.platformAnnouncement,
          title: 'Review submitted',
          body: 'Your review has been posted successfully.',
        );
      } catch (_) {
        // Non-critical
      }

      return true;
    } on Failure catch (f) {
      state = ReviewActionState(error: f);
      return false;
    } catch (e) {
      state = ReviewActionState(error: ServerFailure(e.toString()));
      return false;
    }
  }

  Future<bool> editReview({
    required String reviewId,
    required String serviceId,
    required String providerId,
    required int rating,
    String? comment,
  }) async {
    state = const ReviewActionState(isLoading: true);
    try {
      final review = await _repo.editReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
      );
      _ref.invalidate(serviceReviewsProvider(serviceId));
      _ref.invalidate(ratingBreakdownProvider(serviceId));
      _ref.invalidate(providerReviewsProvider(providerId));
      state = ReviewActionState(isSuccess: true, result: review);
      return true;
    } on Failure catch (f) {
      state = ReviewActionState(error: f);
      return false;
    } catch (e) {
      state = ReviewActionState(error: ServerFailure(e.toString()));
      return false;
    }
  }

  Future<bool> deleteReview({
    required String reviewId,
    required String serviceId,
    required String providerId,
  }) async {
    state = const ReviewActionState(isLoading: true);
    try {
      await _repo.deleteReview(reviewId);
      _ref.invalidate(serviceReviewsProvider(serviceId));
      _ref.invalidate(allReviewsProvider);
      _ref.invalidate(flaggedReviewsProvider);
      state = const ReviewActionState(isSuccess: true);
      return true;
    } on Failure catch (f) {
      state = ReviewActionState(error: f);
      return false;
    } catch (e) {
      state = ReviewActionState(error: ServerFailure(e.toString()));
      return false;
    }
  }

  void clearState() => state = const ReviewActionState();
}

final reviewActionProvider =
    StateNotifierProvider<ReviewActionNotifier, ReviewActionState>((ref) {
  return ReviewActionNotifier(ref);
});
