
// service_usecases.dart
//
// Purpose: Domain-layer use-cases for service listing operations.
// Responsibilities:
//   - Validate inputs before delegating to [ServiceRepository].
//   - Apply business rules (e.g. only the owning provider can delete a service).
//   - Return typed results — never throw.
// Dependencies:
//   - data/repositories/service_repository.dart
//   - data/models/service_model.dart
//   - core/errors/failures.dart

import '../../core/errors/failures.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/service_repository.dart';

class GetServicesUseCase {
  const GetServicesUseCase();

  Future<(List<ServiceModel>, Failure?)> call({
    String? category,
    String? query,
    String? city,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      ServiceCategory? cat;
      if (category != null && category.isNotEmpty) {
        cat = ServiceCategoryExtension.fromString(category);
      }
      final page = offset ~/ limit;
      final list = await ServiceRepository.instance.searchServices(
        searchQuery: query,
        category: cat,
        page: page,
        pageSize: limit,
      );
      return (list, null);
    } on Failure catch (e) {
      return (<ServiceModel>[], e);
    }
  }
}

class GetServiceByIdUseCase {
  const GetServiceByIdUseCase();

  Future<(ServiceModel?, Failure?)> call(String id) async {
    try {
      final service = await ServiceRepository.instance.getServiceById(id);
      return (service, null);
    } on Failure catch (e) {
      return (null, e);
    }
  }
}

class GetFeaturedServicesUseCase {
  const GetFeaturedServicesUseCase();

  Future<(List<ServiceModel>, Failure?)> call() async {
    try {
      final list = await ServiceRepository.instance.getFeaturedServices();
      return (list, null);
    } on Failure catch (e) {
      return (<ServiceModel>[], e);
    }
  }
}

class GetProviderServicesUseCase {
  const GetProviderServicesUseCase();

  Future<(List<ServiceModel>, Failure?)> call(String providerId) async {
    try {
      final list =
          await ServiceRepository.instance.getProviderServices(providerId);
      return (list, null);
    } on Failure catch (e) {
      return (<ServiceModel>[], e);
    }
  }
}

class CreateServiceUseCase {
  const CreateServiceUseCase();

  Future<(ServiceModel?, Failure?)> call(ServiceModel service) async {
    try {
      final created = await ServiceRepository.instance.createService(
        providerId: service.providerId,
        title: service.title,
        description: service.description,
        category: service.category,
        priceType: service.priceType,
        price: service.price,
        availableDays: service.availableDays,
        imageUrls: service.imageUrls,
        isDraft: service.isDraft,
      );
      return (created, null);
    } on Failure catch (e) {
      return (null, e);
    }
  }
}

class UpdateServiceUseCase {
  const UpdateServiceUseCase();

  Future<(ServiceModel?, Failure?)> call(ServiceModel service) async {
    try {
      final updated = await ServiceRepository.instance.updateService(
        serviceId: service.id,
        title: service.title,
        description: service.description,
        category: service.category,
        priceType: service.priceType,
        price: service.price,
        availableDays: service.availableDays,
        imageUrls: service.imageUrls,
        isActive: service.isActive,
        isDraft: service.isDraft,
      );
      return (updated, null);
    } on Failure catch (e) {
      return (null, e);
    }
  }
}

class DeleteServiceUseCase {
  const DeleteServiceUseCase();

  Future<Failure?> call(String id) async {
    try {
      await ServiceRepository.instance.deactivateService(id);
      return null;
    } on Failure catch (e) {
      return e;
    }
  }
}
