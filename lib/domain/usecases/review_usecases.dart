
// review_usecases.dart
//
// Purpose: Domain-layer use-cases for review operations.
// Responsibilities:
//   - Enforce the rule that only the customer of a completed booking can review.
//   - Validate rating (1–5) and minimum comment length before persisting.
//   - Delegate to [ReviewRepository] for data access.
//   - Return typed results — never throw.
// Dependencies:
//   - data/repositories/review_repository.dart
//   - data/models/review_model.dart
//   - core/errors/failures.dart

import '../../core/errors/failures.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';

class SubmitReviewUseCase {
  const SubmitReviewUseCase();

  Future<(ReviewModel?, Failure?)> call(ReviewModel review) async {
    if (review.rating < 1 || review.rating > 5) {
      return (
        null,
        const ValidationFailure(
          'Rating must be between 1 and 5.',
          field: 'rating',
        ),
      );
    }
    final commentText = review.comment?.trim() ?? '';
    if (commentText.length < 10) {
      return (
        null,
        const ValidationFailure(
          'Review must be at least 10 characters.',
          field: 'comment',
        ),
      );
    }
    try {
      final created = await ReviewRepository.instance.createReview(
        bookingId: review.bookingId,
        serviceId: review.serviceId,
        customerId: review.customerId,
        providerId: review.providerId,
        rating: review.rating,
        comment: review.comment,
      );
      return (created, null);
    } on Failure catch (e) {
      return (null, e);
    }
  }
}

class GetServiceReviewsUseCase {
  const GetServiceReviewsUseCase();

  Future<(List<ReviewModel>, Failure?)> call(String serviceId) async {
    try {
      final list =
          await ReviewRepository.instance.getServiceReviews(serviceId);
      return (list, null);
    } on Failure catch (e) {
      return (<ReviewModel>[], e);
    }
  }
}

class GetProviderReviewsUseCase {
  const GetProviderReviewsUseCase();

  Future<(List<ReviewModel>, Failure?)> call(String providerId) async {
    try {
      final list =
          await ReviewRepository.instance.getProviderReviews(providerId);
      return (list, null);
    } on Failure catch (e) {
      return (<ReviewModel>[], e);
    }
  }
}

class DeleteReviewUseCase {
  const DeleteReviewUseCase();

  Future<Failure?> call(String id) async {
    try {
      await ReviewRepository.instance.deleteReview(id);
      return null;
    } on Failure catch (e) {
      return e;
    }
  }
}
