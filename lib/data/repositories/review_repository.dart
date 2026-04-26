
// ---------------------------------------------------------------------------
// review_repository.dart
//
// Purpose: All review and rating operations for SkillBridge.
//
// Responsibilities:
//   - Fetch reviews for a service or provider
//   - Customer: create and edit reviews (24h edit window)
//   - Admin: flag, delete, moderate reviews
//
// Constraint enforced by DB: one review per booking (UNIQUE on booking_id)
// Constraint enforced by RLS: only completed booking customers can review
//
// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthException, StorageException;
import '../../core/errors/failures.dart';
import '../../services/supabase_service.dart';
import '../models/review_model.dart';

class ReviewRepository {
  ReviewRepository._();
  static final ReviewRepository instance = ReviewRepository._();

  final _supabase = SupabaseService.instance;

  static const String _reviewJoinQuery = '''
    *,
    customer:users!customer_id(name, avatar_url, email),
    service:services!service_id(title)
  ''';

  // ── Fetch Reviews ─────────────────────────────────────────────────────────

  /// Gets all non-flagged reviews for a service, newest first
  Future<List<ReviewModel>> getServiceReviews(
    String serviceId, {
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final data = await _supabase
          .from('reviews')
          .select(_reviewJoinQuery)
          .eq('service_id', serviceId)
          .eq('is_flagged', false)
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return (data as List<dynamic>)
          .map((json) =>
              ReviewModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch reviews: $e');
    }
  }

  /// Gets all reviews received by a provider across all their services
  Future<List<ReviewModel>> getProviderReviews(
    String providerId, {
    int? ratingFilter,
    String? serviceIdFilter,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _supabase
          .from('reviews')
          .select(_reviewJoinQuery)
          .eq('provider_id', providerId)
          .eq('is_flagged', false);

      if (ratingFilter != null) {
        query = query.eq('rating', ratingFilter);
      }
      if (serviceIdFilter != null) {
        query = query.eq('service_id', serviceIdFilter);
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return (data as List<dynamic>)
          .map((json) =>
              ReviewModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch provider reviews: $e');
    }
  }

  /// Gets all reviews written by a customer
  Future<List<ReviewModel>> getCustomerReviews(
    String customerId, {
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      final data = await _supabase
          .from('reviews')
          .select(_reviewJoinQuery)
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return (data as List<dynamic>)
          .map((json) =>
              ReviewModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch customer reviews: $e');
    }
  }

  /// Checks whether a booking already has a review
  Future<bool> hasReviewForBooking(String bookingId) async {
    try {
      final data = await _supabase
          .from('reviews')
          .select('id')
          .eq('booking_id', bookingId)
          .maybeSingle();
      return data != null;
    } catch (e) {
      throw ServerFailure('Failed to check review: $e');
    }
  }

  /// Gets a single review by booking ID — null if none exists
  Future<ReviewModel?> getReviewByBookingId(String bookingId) async {
    try {
      final data = await _supabase
          .from('reviews')
          .select(_reviewJoinQuery)
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (data == null) return null;
      return ReviewModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw ServerFailure('Failed to fetch review: $e');
    }
  }

  // ── Create & Edit ─────────────────────────────────────────────────────────

  /// Creates a new review for a completed booking.
  ///
  /// RLS enforces: booking must be completed and belong to the customer.
  /// DB enforces: UNIQUE(booking_id) prevents duplicate reviews.
  Future<ReviewModel> createReview({
    required String bookingId,
    required String serviceId,
    required String customerId,
    required String providerId,
    required int rating,
    String? comment,
  }) async {
    try {
      if (rating < 1 || rating > 5) {
        throw const ValidationFailure(
          'Rating must be between 1 and 5.',
          field: 'rating',
        );
      }

      final data = await _supabase
          .from('reviews')
          .insert({
            'booking_id': bookingId,
            'service_id': serviceId,
            'customer_id': customerId,
            'provider_id': providerId,
            'rating': rating,
            'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
          })
          .select(_reviewJoinQuery)
          .single();

      return ReviewModel.fromJson(Map<String, dynamic>.from(data));
    } on ValidationFailure {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const PermissionFailure(
          'You have already reviewed this booking.',
        );
      }
      if (e.code == '42501') {
        throw const PermissionFailure(
          'You can only review completed bookings.',
        );
      }
      throw ServerFailure('Failed to submit review: ${e.message}');
    } catch (e) {
      throw ServerFailure('Failed to submit review: $e');
    }
  }

  /// Edits a review within the 24-hour window.
  /// RLS enforces: is_editable = true AND created_at within 24h.
  Future<ReviewModel> editReview({
    required String reviewId,
    required int rating,
    String? comment,
  }) async {
    try {
      if (rating < 1 || rating > 5) {
        throw const ValidationFailure(
          'Rating must be between 1 and 5.',
          field: 'rating',
        );
      }

      final data = await _supabase
          .from('reviews')
          .update({
            'rating': rating,
            'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
          })
          .eq('id', reviewId)
          .select(_reviewJoinQuery)
          .single();

      return ReviewModel.fromJson(Map<String, dynamic>.from(data));
    } on ValidationFailure {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const PermissionFailure(
          'Reviews can only be edited within 24 hours of submission.',
        );
      }
      throw ServerFailure('Failed to edit review: ${e.message}');
    } catch (e) {
      throw ServerFailure('Failed to edit review: $e');
    }
  }

  // ── Flag & Moderation ─────────────────────────────────────────────────────

  /// User reports a review as inappropriate
  Future<void> reportReview({
    required String reviewId,
    required String reason,
  }) async {
    try {
      await _supabase.rpc('increment_review_flag', params: {
        'review_id': reviewId,
        'flag_reason': reason,
      });
    } catch (_) {
      // Fallback: direct update if RPC not available
      try {
        final current = await _supabase
            .from('reviews')
            .select('flag_count')
            .eq('id', reviewId)
            .single();
        final currentCount = current['flag_count'] as int? ?? 0;
        await _supabase.from('reviews').update({
          'flag_count': currentCount + 1,
          'flag_reason': reason,
        }).eq('id', reviewId);
      } catch (e) {
        throw ServerFailure('Failed to report review: $e');
      }
    }
  }

  /// Admin: gets all reviews including flagged ones
  Future<List<ReviewModel>> getAllReviews({
    bool? flaggedOnly,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _supabase.from('reviews').select(_reviewJoinQuery);

      if (flaggedOnly == true) {
        query = query.eq('is_flagged', true);
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return (data as List<dynamic>)
          .map((json) =>
              ReviewModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch all reviews: $e');
    }
  }

  /// Admin: flags or unflags a review
  Future<void> setReviewFlagged({
    required String reviewId,
    required bool isFlagged,
    String? reason,
  }) async {
    try {
      await _supabase.from('reviews').update({
        'is_flagged': isFlagged,
        'flag_reason': isFlagged ? reason : null,
      }).eq('id', reviewId);
    } catch (e) {
      throw ServerFailure('Failed to update review flag: $e');
    }
  }

  /// Flag a review as inappropriate
  Future<void> flagReview({
    required String userId,
    required String reviewId,
    String reason = 'inappropriate',
  }) async {
    try {
      await _supabase.from('review_flags').insert({
        'user_id': userId,
        'review_id': reviewId,
        'reason': reason,
      });
    } catch (e) {
      // If already flagged (duplicate key), ignore
      if (e.toString().contains('duplicate') ||
          e.toString().contains('23505')) {
        return;
      }
      throw ServerFailure('Failed to flag review: $e');
    }
  }

  /// Check if a user has already flagged a review
  Future<bool> hasUserFlaggedReview({
    required String userId,
    required String reviewId,
  }) async {
    try {
      final data = await _supabase
          .from('review_flags')
          .select('user_id')
          .eq('user_id', userId)
          .eq('review_id', reviewId)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  /// Admin: permanently deletes a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _supabase.from('reviews').delete().eq('id', reviewId);
    } catch (e) {
      throw ServerFailure('Failed to delete review: $e');
    }
  }

  // ── Rating Stats ──────────────────────────────────────────────────────────

  /// Returns rating breakdown for a service: {1: count, 2: count, ... 5: count}
  Future<Map<int, int>> getRatingBreakdown(String serviceId) async {
    try {
      final data = await _supabase
          .from('reviews')
          .select('rating')
          .eq('service_id', serviceId)
          .eq('is_flagged', false);

      final breakdown = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final row in data as List<dynamic>) {
        final rating = row['rating'] as int? ?? 0;
        if (rating >= 1 && rating <= 5) {
          breakdown[rating] = (breakdown[rating] ?? 0) + 1;
        }
      }
      return breakdown;
    } catch (e) {
      throw ServerFailure('Failed to fetch rating breakdown: $e');
    }
  }
}
