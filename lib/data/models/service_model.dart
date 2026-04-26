
// ---------------------------------------------------------------------------
// service_model.dart
//
// Purpose: Immutable data model representing a service listing.
// Maps directly to the public.services table in Supabase.
//
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

/// Enum matching the service_category PostgreSQL enum
enum ServiceCategory {
  homeRepair,
  tutoring,
  cleaning,
  electrician,
  plumber,
  mechanic,
  beauty,
  graphicDesign,
  moving,
  other,
}

extension ServiceCategoryExtension on ServiceCategory {
  String get value {
    switch (this) {
      case ServiceCategory.homeRepair:    return 'home_repair';
      case ServiceCategory.tutoring:      return 'tutoring';
      case ServiceCategory.cleaning:      return 'cleaning';
      case ServiceCategory.electrician:   return 'electrician';
      case ServiceCategory.plumber:       return 'plumber';
      case ServiceCategory.mechanic:      return 'mechanic';
      case ServiceCategory.beauty:        return 'beauty';
      case ServiceCategory.graphicDesign: return 'graphic_design';
      case ServiceCategory.moving:        return 'moving';
      case ServiceCategory.other:         return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case ServiceCategory.homeRepair:    return 'Home Repair';
      case ServiceCategory.tutoring:      return 'Tutoring';
      case ServiceCategory.cleaning:      return 'Cleaning';
      case ServiceCategory.electrician:   return 'Electrician';
      case ServiceCategory.plumber:       return 'Plumber';
      case ServiceCategory.mechanic:      return 'Mechanic';
      case ServiceCategory.beauty:        return 'Beauty';
      case ServiceCategory.graphicDesign: return 'Graphic Design';
      case ServiceCategory.moving:        return 'Moving';
      case ServiceCategory.other:         return 'Other';
    }
  }

  static ServiceCategory fromString(String value) {
    switch (value) {
      case 'home_repair':    return ServiceCategory.homeRepair;
      case 'tutoring':       return ServiceCategory.tutoring;
      case 'cleaning':       return ServiceCategory.cleaning;
      case 'electrician':    return ServiceCategory.electrician;
      case 'plumber':        return ServiceCategory.plumber;
      case 'mechanic':       return ServiceCategory.mechanic;
      case 'beauty':         return ServiceCategory.beauty;
      case 'graphic_design': return ServiceCategory.graphicDesign;
      case 'moving':         return ServiceCategory.moving;
      default:               return ServiceCategory.other;
    }
  }
}

/// Enum matching the price_type PostgreSQL enum
enum PriceType { fixed, startingFrom }

extension PriceTypeExtension on PriceType {
  String get value => this == PriceType.fixed ? 'fixed' : 'starting_from';

  static PriceType fromString(String value) =>
      value == 'starting_from' ? PriceType.startingFrom : PriceType.fixed;
}

@immutable
class ServiceModel {
  final String id;
  final String providerId;
  final String title;
  final String description;
  final ServiceCategory category;
  final PriceType priceType;
  final double price;
  final List<String> imageUrls;
  final bool isActive;
  final List<String> availableDays;
  final double avgRating;
  final int reviewCount;
  final int bookingCount;
  final String? aiSummary;
  final DateTime? aiSummaryAt;
  final bool isDraft;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional: provider info when joined in queries
  final String? providerName;
  final String? providerAvatarUrl;
  final bool? providerIsVerified;

  const ServiceModel({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.category,
    required this.priceType,
    required this.price,
    this.imageUrls = const [],
    this.isActive = true,
    this.availableDays = const [
      'monday','tuesday','wednesday','thursday','friday','saturday'
    ],
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.bookingCount = 0,
    this.aiSummary,
    this.aiSummaryAt,
    this.isDraft = false,
    required this.createdAt,
    required this.updatedAt,
    this.providerName,
    this.providerAvatarUrl,
    this.providerIsVerified,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // Handle nested provider data from Supabase joins
    final providerData = json['users'] as Map<String, dynamic>?;

    return ServiceModel(
      id: json['id'] as String,
      providerId: json['provider_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: ServiceCategoryExtension.fromString(
          json['category'] as String? ?? 'other'),
      priceType: PriceTypeExtension.fromString(
          json['price_type'] as String? ?? 'fixed'),
      price: (json['price'] as num).toDouble(),
      imageUrls: (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isActive: json['is_active'] as bool? ?? true,
      availableDays: (json['available_days'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['monday','tuesday','wednesday','thursday','friday','saturday'],
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      bookingCount: json['booking_count'] as int? ?? 0,
      aiSummary: json['ai_summary'] as String?,
      aiSummaryAt: json['ai_summary_at'] != null
          ? DateTime.parse(json['ai_summary_at'] as String)
          : null,
      isDraft: json['is_draft'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      providerName: providerData?['name'] as String?,
      providerAvatarUrl: providerData?['avatar_url'] as String?,
      providerIsVerified: providerData?['is_verified'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'title': title,
      'description': description,
      'category': category.value,
      'price_type': priceType.value,
      'price': price,
      'image_urls': imageUrls,
      'is_active': isActive,
      'available_days': availableDays,
      'is_draft': isDraft,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? providerId,
    String? title,
    String? description,
    ServiceCategory? category,
    PriceType? priceType,
    double? price,
    List<String>? imageUrls,
    bool? isActive,
    List<String>? availableDays,
    double? avgRating,
    int? reviewCount,
    int? bookingCount,
    String? aiSummary,
    DateTime? aiSummaryAt,
    bool? isDraft,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? providerName,
    String? providerAvatarUrl,
    bool? providerIsVerified,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priceType: priceType ?? this.priceType,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      isActive: isActive ?? this.isActive,
      availableDays: availableDays ?? this.availableDays,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      bookingCount: bookingCount ?? this.bookingCount,
      aiSummary: aiSummary ?? this.aiSummary,
      aiSummaryAt: aiSummaryAt ?? this.aiSummaryAt,
      isDraft: isDraft ?? this.isDraft,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      providerName: providerName ?? this.providerName,
      providerAvatarUrl: providerAvatarUrl ?? this.providerAvatarUrl,
      providerIsVerified: providerIsVerified ?? this.providerIsVerified,
    );
  }

  /// Whether the AI summary is still fresh (less than 24 hours old)
  bool get hasValidAiSummary =>
      aiSummary != null &&
      aiSummaryAt != null &&
      DateTime.now().difference(aiSummaryAt!).inHours < 24;

  /// First image URL or null if no images
  String? get thumbnailUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServiceModel(id: $id, title: $title)';
}
