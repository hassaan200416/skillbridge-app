// Service repository for browsing, search, CRUD, and saved services.
// This repository is the main data layer for service discovery and provider
// listings. It also handles image upload coordination and AI review summary
// caching so the UI does not need to manage those workflows itself.

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
      // Build the query step by step because each filter changes the builder type.
      dynamic query = _supabase.from('services').select('''
            *,
            users!provider_id(name, avatar_url, is_verified)
          ''').eq('is_active', true).eq('is_draft', false);

      // Keep only one category when the user or AI has picked one.
      if (category != null) {
        query = query.eq('category', category.value);
      }

      // Narrow results to the requested price range.
      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }
      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      // Keep only services above the minimum rating.
      if (minRating != null) {
        query = query.gte('avg_rating', minRating);
      }

      // Use ilike for text search because it works consistently on web.
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query
            .or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      // Switch the sort order based on the screen request.
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

      // Page through the filtered results.
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
      // Create the service record first so we have an ID for image paths.
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

      // Upload images after the service exists so each file can use its ID.
      if (imageFiles.isNotEmpty) {
        final uploadedUrls = await _storage.uploadServiceImages(
          userId: providerId,
          serviceId: serviceId,
          imageFiles: imageFiles,
        );

        // Save the uploaded URLs back into the service record.
        await _supabase.from('services').update({
          'image_urls': uploadedUrls,
        }).eq('id', serviceId);
      }

      return await getServiceById(serviceId);
    } catch (e) {
      throw ServerFailure('Failed to create service: $e');
    }
  }

  /// Updates an existing service listing.
  /// Pass [imageUrls] for existing remote URLs to keep.
  /// Pass [imageFiles] for newly picked local files to upload and append.
  Future<ServiceModel> updateService({
    required String serviceId,
    required String providerId,
    String? title,
    String? description,
    ServiceCategory? category,
    PriceType? priceType,
    double? price,
    List<String>? availableDays,
    List<String>? imageUrls,
    List<XFile>? imageFiles,
    bool? isActive,
    bool? isDraft,
  }) async {
    try {
      // Merge existing URLs with newly uploaded files.
      List<String>? finalImageUrls = imageUrls;
      if (imageFiles != null && imageFiles.isNotEmpty) {
        final uploadedUrls = await _storage.uploadServiceImages(
          userId: providerId,
          serviceId: serviceId,
          imageFiles: imageFiles,
        );
        finalImageUrls = [...(imageUrls ?? []), ...uploadedUrls];
      }

      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category.value;
      if (priceType != null) updates['price_type'] = priceType.value;
      if (price != null) updates['price'] = price;
      if (availableDays != null) updates['available_days'] = availableDays;
      if (finalImageUrls != null) updates['image_urls'] = finalImageUrls;
      if (isActive != null) updates['is_active'] = isActive;
      if (isDraft != null) updates['is_draft'] = isDraft;

      await _supabase.from('services').update(updates).eq('id', serviceId);

      return await getServiceById(serviceId);
    } catch (e) {
      throw ServerFailure('Failed to update service: $e');
    }
  }

  /// Soft-deletes a service by setting is_active = false.
  /// Hard delete is not allowed because bookings and reviews must stay linked.
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
      // Do not spend an AI call unless the service has enough reviews.
      if (service.reviewCount < 3) {
        debugPrint(
          'AI summary: skip service=${service.id} (reviewCount=${service.reviewCount} < 3)',
        );
        return null;
      }

      // Reuse a recent summary so we do not regenerate it too often.
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

      // Pull only the latest review comments needed for the summary.
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

      // Turn review rows into plain text the AI can summarize.
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

      // Persist the summary and its refresh time back to the service row.
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
      // See whether the service is already saved before toggling.
      final existing = await _supabase
          .from('saved_services')
          .select()
          .eq('customer_id', customerId)
          .eq('service_id', serviceId)
          .maybeSingle();

      if (existing != null) {
        // Remove the saved row if it already exists.
        await _supabase
            .from('saved_services')
            .delete()
            .eq('customer_id', customerId)
            .eq('service_id', serviceId);
        return false;
      } else {
        // Otherwise create a new saved row.
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
