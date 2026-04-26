
// ---------------------------------------------------------------------------
// service_repository.dart
//
// Purpose: All service listing CRUD operations and search/discovery queries.
//
// Responsibilities:
//   - Fetch services for home screen (featured, recent, by category)
//   - Search with filters (category, price, rating, text)
//   - Provider CRUD: create, edit, soft-delete services
//   - Image management via StorageService
//   - AI summary caching logic
//
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import 'package:image_picker/image_picker.dart';
import '../../core/errors/failures.dart';
import '../../services/supabase_service.dart';
import '../../services/storage_service.dart';
import '../../services/ai_service.dart';
import '../models/service_model.dart';

class ServiceRepository {
  ServiceRepository._();
  static final ServiceRepository instance = ServiceRepository._();

  final _supabase = SupabaseService.instance;
  final _storage = StorageService.instance;
  final _gemini = AiService.instance;

  // ── Home Screen Queries ───────────────────────────────────────────────────

  /// Fetches featured services: top-rated with most bookings
  Future<List<ServiceModel>> getFeaturedServices({int limit = 8}) async {
    try {
      final data = await _supabase
          .from('services')
          .select('''
            *,
            users!provider_id(name, avatar_url, is_verified)
          ''')
          .eq('is_active', true)
          .eq('is_draft', false)
          .order('avg_rating', ascending: false)
          .order('booking_count', ascending: false)
          .limit(limit);

      return (data as List<dynamic>)
          .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch featured services: $e');
    }
  }

  /// Fetches recently added services
  Future<List<ServiceModel>> getRecentServices({int limit = 10}) async {
    try {
      final data = await _supabase
          .from('services')
          .select('''
            *,
            users!provider_id(name, avatar_url, is_verified)
          ''')
          .eq('is_active', true)
          .eq('is_draft', false)
          .order('created_at', ascending: false)
          .limit(limit);

      return (data as List<dynamic>)
          .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch recent services: $e');
    }
  }

  /// Fetches services by category
  Future<List<ServiceModel>> getServicesByCategory(
    ServiceCategory category, {
    int limit = 20,
    int page = 0,
  }) async {
    try {
      final data = await _supabase
          .from('services')
          .select('''
            *,
            users!provider_id(name, avatar_url, is_verified)
          ''')
          .eq('is_active', true)
          .eq('is_draft', false)
          .eq('category', category.value)
          .order('avg_rating', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);

      return (data as List<dynamic>)
          .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch services by category: $e');
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  /// Full search with filters. Supports text search, category, price, rating.
  ///
  /// For AI search: pass the extracted parameters from AiService.
  /// For regular search: just pass searchQuery.
  Future<List<ServiceModel>> searchServices({
    String? searchQuery,
    ServiceCategory? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String sortBy = 'rating', // 'rating', 'price_asc', 'price_desc', 'newest'
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      // Build base query with provider join (dynamic: chained filters change builder type)
      dynamic query = _supabase.from('services').select('''
            *,
            users!provider_id(name, avatar_url, is_verified)
          ''').eq('is_active', true).eq('is_draft', false);

      // Apply category filter
      if (category != null) {
        query = query.eq('category', category.value);
      }

      // Apply price range filter
      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }
      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      // Apply rating filter
      if (minRating != null) {
        query = query.gte('avg_rating', minRating);
      }

      // Use ilike for text search — more reliable on Flutter web
      // than full-text search which causes SSL issues
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query
            .or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      // Apply sort
      switch (sortBy) {
        case 'price_asc':
          query = query.order('price', ascending: true);
        case 'price_desc':
          query = query.order('price', ascending: false);
        case 'newest':
          query = query.order('created_at', ascending: false);
        case 'most_booked':
          query = query.order('booking_count', ascending: false);
        default:
          query = query.order('avg_rating', ascending: false);
      }

      // Apply pagination
      query = query.range(page * pageSize, (page + 1) * pageSize - 1);

      final data = await query;
      return (data as List<dynamic>)
          .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerFailure('Search failed: $e');
    }
  }

  // ── Single Service ────────────────────────────────────────────────────────

  /// Fetches a single service by ID with full provider details
  Future<ServiceModel> getServiceById(String serviceId) async {
    try {
      final data = await _supabase.from('services').select('''
            *,
            users!provider_id(
              id, name, avatar_url, is_verified, bio,
              experience_years, service_area, city
            )
          ''').eq('id', serviceId).single();

      return ServiceModel.fromJson(Map<String, dynamic>.from(data));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const NotFoundFailure('Service not found.');
      }
      throw ServerFailure('Failed to fetch service: ${e.message}');
    } catch (e) {
      throw ServerFailure('Failed to fetch service: $e');
    }
  }

  /// Fetches all services by a provider (for provider profile page)
  Future<List<ServiceModel>> getProviderServices(
    String providerId, {
    bool includeInactive = false,
  }) async {
    try {
      dynamic query = _supabase.from('services').select('''
            *,
            users!provider_id(name, avatar_url, is_verified)
          ''').eq('provider_id', providerId);

      if (!includeInactive) {
        query = query.eq('is_active', true).eq('is_draft', false);
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch provider services: $e');
    }
  }

  // ── Provider CRUD ─────────────────────────────────────────────────────────

  /// Creates a new service listing.
  /// Uploads images first, then creates the service record.
  Future<ServiceModel> createService({
    required String providerId,
    required String title,
    required String description,
    required ServiceCategory category,
    required PriceType priceType,
    required double price,
    required List<String> availableDays,
    List<String> imageUrls = const [],
    List<XFile> imageFiles = const [],
    bool isDraft = false,
  }) async {
    try {
      // Create service record first to get the ID for image paths
      final insertData = {
        'provider_id': providerId,
        'title': title,
        'description': description,
        'category': category.value,
        'price_type': priceType.value,
        'price': price,
        'available_days': availableDays,
        'is_draft': isDraft,
        'image_urls': imageUrls,
      };

      final response =
          await _supabase.from('services').insert(insertData).select().single();

      final serviceId = response['id'] as String;

      // Upload images if provided
      if (imageFiles.isNotEmpty) {
        final uploadedUrls = await _storage.uploadServiceImages(
          userId: providerId,
          serviceId: serviceId,
          imageFiles: imageFiles,
        );

        // Update service with uploaded image URLs
        await _supabase.from('services').update({
          'image_urls': uploadedUrls,
        }).eq('id', serviceId);
      }

      return await getServiceById(serviceId);
    } catch (e) {
      throw ServerFailure('Failed to create service: $e');
    }
  }

  /// Updates an existing service listing
  Future<ServiceModel> updateService({
    required String serviceId,
    String? title,
    String? description,
    ServiceCategory? category,
    PriceType? priceType,
    double? price,
    List<String>? availableDays,
    List<String>? imageUrls,
    bool? isActive,
    bool? isDraft,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category.value;
      if (priceType != null) updates['price_type'] = priceType.value;
      if (price != null) updates['price'] = price;
      if (availableDays != null) updates['available_days'] = availableDays;
      if (imageUrls != null) updates['image_urls'] = imageUrls;
      if (isActive != null) updates['is_active'] = isActive;
      if (isDraft != null) updates['is_draft'] = isDraft;

      await _supabase.from('services').update(updates).eq('id', serviceId);

      return await getServiceById(serviceId);
    } catch (e) {
      throw ServerFailure('Failed to update service: $e');
    }
  }

  /// Soft-deletes a service by setting is_active = false
  /// Hard delete is not allowed — preserves booking history
  Future<void> deactivateService(String serviceId) async {
    try {
      await _supabase
          .from('services')
          .update({'is_active': false}).eq('id', serviceId);
    } catch (e) {
      throw ServerFailure('Failed to deactivate service: $e');
    }
  }

  // ── AI Summary ────────────────────────────────────────────────────────────

  /// Gets AI summary for a service. Uses cached version if still fresh.
  /// Generates and caches a new one if stale or missing.
  Future<String?> getOrRefreshAiSummary(ServiceModel service) async {
    try {
      if (service.reviewCount < 3) {
        debugPrint(
          'AI summary: skip service=${service.id} (reviewCount=${service.reviewCount} < 3)',
        );
        return null;
      }

      if (service.aiSummary != null && service.aiSummaryAt != null) {
        final age = DateTime.now().difference(service.aiSummaryAt!);
        if (age.inHours < 24) {
          debugPrint(
            'AI summary: cache hit service=${service.id} age=${age.inHours}h',
          );
          return service.aiSummary;
        }
        debugPrint(
          'AI summary: cache stale service=${service.id} age=${age.inHours}h, refreshing',
        );
      }

      final reviewsData = await _supabase
          .from('reviews')
          .select('rating, comment')
          .eq('service_id', service.id)
          .limit(10);

      final reviews = (reviewsData as List<dynamic>)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();

      debugPrint(
        'AI summary: fetched ${reviews.length} review row(s) for service=${service.id}',
      );

      if (reviews.isEmpty) {
        debugPrint('AI summary: no review rows, abort');
        return null;
      }

      final reviewTexts = reviews
          .where((r) =>
              r['comment'] != null &&
              (r['comment'] as String).trim().isNotEmpty)
          .map((r) => '${r['rating']}/5 stars: ${r['comment']}')
          .join('\n');

      if (reviewTexts.isEmpty) {
        debugPrint(
          'AI summary: no non-empty comments after filter, abort service=${service.id}',
        );
        return null;
      }

      debugPrint(
        'AI summary: calling Groq for "${service.title}" (${reviewTexts.length} chars)',
      );

      final summary = await _gemini.generateReviewSummary(
        serviceName: service.title,
        reviewTexts: reviewTexts,
      );

      if (summary == null) {
        debugPrint('AI summary: Groq returned null service=${service.id}');
        return null;
      }

      // Matches ServiceModel / DB column ai_summary_at (not ai_summary_generated_at)
      await _supabase.from('services').update({
        'ai_summary': summary,
        'ai_summary_at': DateTime.now().toIso8601String(),
      }).eq('id', service.id);

      debugPrint(
        'AI summary: cached ok service=${service.id} len=${summary.length}',
      );
      return summary;
    } catch (e, st) {
      debugPrint('AI summary error: $e');
      debugPrint('$st');
      return null;
    }
  }

  // ── Saved Services ────────────────────────────────────────────────────────

  /// Gets all saved/wishlisted service IDs for a customer
  Future<List<String>> getSavedServiceIds(String customerId) async {
    try {
      final data = await _supabase
          .from('saved_services')
          .select('service_id')
          .eq('customer_id', customerId);

      return (data as List<dynamic>)
          .map((row) => row['service_id'] as String)
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch saved services: $e');
    }
  }

  /// Toggles a service in the customer's wishlist.
  /// Returns true if service was added, false if removed.
  Future<bool> toggleSavedService({
    required String customerId,
    required String serviceId,
  }) async {
    try {
      // Check if already saved
      final existing = await _supabase
          .from('saved_services')
          .select()
          .eq('customer_id', customerId)
          .eq('service_id', serviceId)
          .maybeSingle();

      if (existing != null) {
        // Remove from saved
        await _supabase
            .from('saved_services')
            .delete()
            .eq('customer_id', customerId)
            .eq('service_id', serviceId);
        return false;
      } else {
        // Add to saved
        await _supabase.from('saved_services').insert({
          'customer_id': customerId,
          'service_id': serviceId,
        });
        return true;
      }
    } catch (e) {
      throw ServerFailure('Failed to toggle saved service: $e');
    }
  }

  /// Gets full service details for all saved services
  Future<List<ServiceModel>> getSavedServices(String customerId) async {
    try {
      final data = await _supabase
          .from('saved_services')
          .select('''
            service_id,
            services(
              *,
              users!provider_id(name, avatar_url, is_verified)
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((row) {
            final serviceJson = row['services'] as Map<String, dynamic>?;
            if (serviceJson == null) return null;
            return ServiceModel.fromJson(serviceJson);
          })
          .whereType<ServiceModel>()
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch saved services: $e');
    }
  }
}

