// Review and rating state for service feedback.
// This file loads review lists, rating breakdowns, and review-edit state for
// customer, provider, and admin screens.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../services/notification_service.dart';
import '../../core/errors/failures.dart';

// Read-only review providers.
// These keep service detail pages and profile pages up to date.

/// Reviews shown on a service detail page.
final serviceReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, serviceId) {
  return ReviewRepository.instance.getServiceReviews(serviceId);
});

/// Counts how many 1-star, 2-star, 3-star, and so on reviews exist.
final ratingBreakdownProvider =
    FutureProvider.family<Map<int, int>, String>((ref, serviceId) {
  return ReviewRepository.instance.getRatingBreakdown(serviceId);
});

/// Reviews written by one customer.
final customerReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, customerId) {
  return ReviewRepository.instance.getCustomerReviews(customerId);
});

/// Reviews received by one provider.
final providerReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, providerId) {
  return ReviewRepository.instance.getProviderReviews(providerId);
});

/// Checks whether a booking already has a review.
final hasReviewProvider = FutureProvider.family<bool, String>((ref, bookingId) {
  return ReviewRepository.instance.hasReviewForBooking(bookingId);
});

/// Loads an existing review so the user can edit it.
final bookingReviewProvider =
    FutureProvider.family<ReviewModel?, String>((ref, bookingId) {
  return ReviewRepository.instance.getReviewByBookingId(bookingId);
});

// Admin review providers.
// Used on moderation screens for broad review management.

/// Loads every review for moderation.
final allReviewsProvider = FutureProvider<List<ReviewModel>>((ref) {
  return ReviewRepository.instance.getAllReviews();
});

final flaggedReviewsProvider = FutureProvider<List<ReviewModel>>((ref) {
  return ReviewRepository.instance.getAllReviews(flaggedOnly: true);
});

// Review actions.
// These methods create, edit, or delete reviews and refresh related counts.

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
      // Tell the provider that a new review was received.
      await _notifications.onReviewReceived(
        providerId: providerId,
        bookingId: bookingId,
        serviceName: serviceName,
      );
      // Refresh all review-related screens so the new score appears quickly.
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

  // Resets loading, error, and result values.
  void clearState() => state = const ReviewActionState();
}

final reviewActionProvider =
    StateNotifierProvider<ReviewActionNotifier, ReviewActionState>((ref) {
  return ReviewActionNotifier(ref);
});
