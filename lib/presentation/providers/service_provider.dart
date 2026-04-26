
// ---------------------------------------------------------------------------
// service_provider.dart
//
// Purpose: Riverpod state management for service listings.
// Drives home screen, search, service detail, provider dashboard.
//
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/service_repository.dart';
import '../../core/errors/failures.dart';

// ── Home Screen Providers ─────────────────────────────────────────────────

/// Featured services for home screen carousel
final featuredServicesProvider = FutureProvider<List<ServiceModel>>((ref) {
  return ServiceRepository.instance.getFeaturedServices();
});

/// Recently added services for home screen
final recentServicesProvider = FutureProvider<List<ServiceModel>>((ref) {
  return ServiceRepository.instance.getRecentServices();
});

/// Services by category
final servicesByCategoryProvider =
    FutureProvider.family<List<ServiceModel>, ServiceCategory>((ref, category) {
  return ServiceRepository.instance.getServicesByCategory(category);
});

// ── Single Service ────────────────────────────────────────────────────────

/// Single service detail — used on service detail screen
final serviceDetailProvider =
    FutureProvider.family<ServiceModel, String>((ref, serviceId) {
  return ServiceRepository.instance.getServiceById(serviceId);
});

/// AI summary for a service — fetched separately to not block main content
final aiSummaryProvider =
    FutureProvider.family<String?, ServiceModel>((ref, service) {
  return ServiceRepository.instance.getOrRefreshAiSummary(service);
});

// ── Provider Services ─────────────────────────────────────────────────────

/// All services for a provider — used on provider dashboard
final providerServicesProvider =
    FutureProvider.family<List<ServiceModel>, String>((ref, providerId) {
  return ServiceRepository.instance.getProviderServices(
    providerId,
    includeInactive: true,
  );
});

// ── Saved Services ────────────────────────────────────────────────────────

/// Saved service IDs for the current customer — used to show heart icon state
final savedServiceIdsProvider =
    FutureProvider.family<List<String>, String>((ref, customerId) {
  return ServiceRepository.instance.getSavedServiceIds(customerId);
});

/// Full saved services list for wishlist screen
final savedServicesProvider =
    FutureProvider.family<List<ServiceModel>, String>((ref, customerId) {
  return ServiceRepository.instance.getSavedServices(customerId);
});

// ── Search ────────────────────────────────────────────────────────────────

/// Search parameters state — drives the search screen
class SearchParams {
  final String query;
  final ServiceCategory? category;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String sortBy;

  const SearchParams({
    this.query = '',
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.sortBy = 'rating',
  });

  SearchParams copyWith({
    String? query,
    ServiceCategory? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
  }) {
    return SearchParams(
      query: query ?? this.query,
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

/// Holds current search parameters — updated by search screen
final searchParamsProvider = StateProvider<SearchParams>((ref) {
  return const SearchParams();
});

/// Executes search based on current SearchParams
final searchResultsProvider =
    FutureProvider.family<List<ServiceModel>, SearchParams>((ref, params) {
  return ServiceRepository.instance.searchServices(
    searchQuery: params.query.isEmpty ? null : params.query,
    category: params.category,
    minPrice: params.minPrice,
    maxPrice: params.maxPrice,
    minRating: params.minRating,
    sortBy: params.sortBy,
  );
});

// ── Service CRUD Actions ──────────────────────────────────────────────────

class ServiceActionState {
  final bool isLoading;
  final Failure? error;
  final ServiceModel? result;
  final bool isSuccess;

  const ServiceActionState({
    this.isLoading = false,
    this.error,
    this.result,
    this.isSuccess = false,
  });

  ServiceActionState copyWith({
    bool? isLoading,
    Failure? error,
    ServiceModel? result,
    bool? isSuccess,
  }) {
    return ServiceActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      result: result ?? this.result,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ServiceActionNotifier extends StateNotifier<ServiceActionState> {
  ServiceActionNotifier(this._ref) : super(const ServiceActionState());

  final Ref _ref;
  final _repo = ServiceRepository.instance;

  Future<bool> createService({
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
    state = const ServiceActionState(isLoading: true);
    try {
      final service = await _repo.createService(
        providerId: providerId,
        title: title,
        description: description,
        category: category,
        priceType: priceType,
        price: price,
        availableDays: availableDays,
        imageUrls: imageUrls,
        imageFiles: imageFiles,
        isDraft: isDraft,
      );
      // Invalidate provider services cache
      _ref.invalidate(providerServicesProvider(providerId));
      state = ServiceActionState(isSuccess: true, result: service);

      if (!isDraft) {
        try {
          await NotificationRepository.instance.createNotification(
            userId: providerId,
            type: NotificationType.platformAnnouncement,
            title: 'Service published!',
            body: '"$title" is now live and visible to customers.',
          );
        } catch (_) {
          // Non-critical
        }
      }

      return true;
    } on Failure catch (f) {
      state = ServiceActionState(error: f);
      return false;
    } catch (e) {
      state = ServiceActionState(error: ServerFailure(e.toString()));
      return false;
    }
  }

  Future<bool> updateService({
    required String serviceId,
    required String providerId,
    String? title,
    String? description,
    ServiceCategory? category,
    PriceType? priceType,
    double? price,
    List<String>? availableDays,
    List<String>? imageUrls,
    bool? isActive,
  }) async {
    state = const ServiceActionState(isLoading: true);
    try {
      final service = await _repo.updateService(
        serviceId: serviceId,
        title: title,
        description: description,
        category: category,
        priceType: priceType,
        price: price,
        availableDays: availableDays,
        imageUrls: imageUrls,
        isActive: isActive,
      );
      _ref.invalidate(providerServicesProvider(providerId));
      _ref.invalidate(serviceDetailProvider(serviceId));
      state = ServiceActionState(isSuccess: true, result: service);
      return true;
    } on Failure catch (f) {
      state = ServiceActionState(error: f);
      return false;
    } catch (e) {
      state = ServiceActionState(error: ServerFailure(e.toString()));
      return false;
    }
  }

  Future<bool> deactivateService({
    required String serviceId,
    required String providerId,
  }) async {
    state = const ServiceActionState(isLoading: true);
    try {
      await _repo.deactivateService(serviceId);
      _ref.invalidate(providerServicesProvider(providerId));
      state = const ServiceActionState(isSuccess: true);
      return true;
    } on Failure catch (f) {
      state = ServiceActionState(error: f);
      return false;
    } catch (e) {
      state = ServiceActionState(error: ServerFailure(e.toString()));
      return false;
    }
  }

  Future<bool> toggleSaved({
    required String customerId,
    required String serviceId,
  }) async {
    try {
      await _repo.toggleSavedService(
        customerId: customerId,
        serviceId: serviceId,
      );
      _ref.invalidate(savedServiceIdsProvider(customerId));
      _ref.invalidate(savedServicesProvider(customerId));
      return true;
    } on Failure catch (f) {
      state = ServiceActionState(error: f);
      return false;
    } catch (e) {
      state = ServiceActionState(error: ServerFailure(e.toString()));
      return false;
    }
  }

  void clearState() => state = const ServiceActionState();
}

final serviceActionProvider =
    StateNotifierProvider<ServiceActionNotifier, ServiceActionState>((ref) {
  return ServiceActionNotifier(ref);
});
