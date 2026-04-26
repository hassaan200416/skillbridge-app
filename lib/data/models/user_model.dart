
// ---------------------------------------------------------------------------
// user_model.dart
//
// Purpose: Immutable data model representing a SkillBridge user.
// Maps directly to the public.users table in Supabase.
//
// Responsibilities:
//   - Serialize/deserialize from Supabase JSON responses
//   - Provide copyWith() for immutable state updates in Riverpod
//   - Carry both customer and provider-specific fields
//
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

/// Enum matching the user_role PostgreSQL enum
enum UserRole { customer, provider, admin }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.customer: return 'customer';
      case UserRole.provider: return 'provider';
      case UserRole.admin:    return 'admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'provider': return UserRole.provider;
      case 'admin':    return UserRole.admin;
      default:         return UserRole.customer;
    }
  }
}

@immutable
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final String? city;

  // Provider-specific fields
  final String? bio;
  final int? experienceYears;
  final String? serviceArea;
  final List<String> portfolioUrls;

  // Trust and moderation
  final bool isVerified;
  final bool isSuspended;
  final String? suspensionReason;

  // Profile completion
  final bool isProfileComplete;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.city,
    this.bio,
    this.experienceYears,
    this.serviceArea,
    this.portfolioUrls = const [],
    this.isVerified = false,
    this.isSuspended = false,
    this.suspensionReason,
    this.isProfileComplete = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a UserModel from a Supabase JSON response map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRoleExtension.fromString(json['role'] as String? ?? 'customer'),
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      city: json['city'] as String?,
      bio: json['bio'] as String?,
      experienceYears: json['experience_years'] as int?,
      serviceArea: json['service_area'] as String?,
      portfolioUrls: (json['portfolio_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isVerified: json['is_verified'] as bool? ?? false,
      isSuspended: json['is_suspended'] as bool? ?? false,
      suspensionReason: json['suspension_reason'] as String?,
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts UserModel to JSON for Supabase insert/update
  /// Note: id, created_at, updated_at are excluded — managed by Supabase
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role.value,
      'phone': phone,
      'avatar_url': avatarUrl,
      'city': city,
      'bio': bio,
      'experience_years': experienceYears,
      'service_area': serviceArea,
      'portfolio_urls': portfolioUrls,
      'is_verified': isVerified,
      'is_suspended': isSuspended,
      'suspension_reason': suspensionReason,
      'is_profile_complete': isProfileComplete,
    };
  }

  /// Creates a copy with specific fields changed — used in Riverpod state updates
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phone,
    String? avatarUrl,
    String? city,
    String? bio,
    int? experienceYears,
    String? serviceArea,
    List<String>? portfolioUrls,
    bool? isVerified,
    bool? isSuspended,
    String? suspensionReason,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      experienceYears: experienceYears ?? this.experienceYears,
      serviceArea: serviceArea ?? this.serviceArea,
      portfolioUrls: portfolioUrls ?? this.portfolioUrls,
      isVerified: isVerified ?? this.isVerified,
      isSuspended: isSuspended ?? this.isSuspended,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Whether this user is a provider
  bool get isProvider => role == UserRole.provider;

  /// Whether this user is an admin
  bool get isAdmin => role == UserRole.admin;

  /// Whether this user is a customer
  bool get isCustomer => role == UserRole.customer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserModel(id: $id, name: $name, role: ${role.value})';
}
