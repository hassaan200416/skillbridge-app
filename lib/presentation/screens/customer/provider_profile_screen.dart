
// ---------------------------------------------------------------------------
// provider_profile_screen.dart
//
// Purpose: Public provider profile viewed by customers. Shows bio,
// experience, service area, rating, and all active services.
// Cuts chat/map/warranty features that aren't backed by the DB.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/user_model.dart';
import '../../../presentation/providers/review_provider.dart';
import '../../../presentation/providers/service_provider.dart';
import '../../../presentation/providers/user_provider.dart';
import '../../../presentation/widgets/common/app_sidebar.dart';
import '../../../presentation/widgets/common/app_top_bar.dart';

class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({super.key, required this.providerId});
  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final servicesAsync = ref.watch(providerServicesProvider(providerId));
    final reviewsAsync = ref.watch(providerReviewsProvider(providerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AppSidebar(role: UserRole.customer, currentRoute: '/provider'),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (users) {
                final provider =
                    users.where((u) => u.id == providerId).firstOrNull;

                if (provider == null) {
                  return const Center(child: Text('Provider not found'));
                }

                return Column(
                  children: [
                    const AppTopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeroHeader(provider: provider),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // LEFT
                                  Expanded(
                                    flex: 65,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _AboutSection(provider: provider),
                                        const SizedBox(height: 20),
                                        _StatsSection(
                                          provider: provider,
                                          servicesAsync: servicesAsync,
                                          reviewsAsync: reviewsAsync,
                                        ),
                                        const SizedBox(height: 28),
                                        _ServicesSection(
                                            servicesAsync: servicesAsync),
                                        if (provider.city != null ||
                                            provider.serviceArea != null) ...[
                                          const SizedBox(height: 28),
                                          _LocationSection(provider: provider),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),

                                  // RIGHT
                                  SizedBox(
                                    width: 320,
                                    child: _BookingCard(
                                      provider: provider,
                                      servicesAsync: servicesAsync,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.provider});
  final UserModel provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, Color(0xFF0A1628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child: provider.avatarUrl != null
                  ? Image.network(
                      provider.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(),
                    )
                  : _avatarFallback(),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (provider.isVerified) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('VERIFIED',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  provider.name,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (provider.bio != null && provider.bio!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    provider.bio!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: AppColors.primary.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: Text(
          provider.name.isNotEmpty ? provider.name[0].toUpperCase() : 'P',
          style: GoogleFonts.poppins(
            fontSize: 44,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );
}

// ── About Section ────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.provider});
  final UserModel provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 3,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text('About the Provider',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            provider.bio ?? 'This provider has not added a bio yet.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.grey600,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Section ────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.provider,
    required this.servicesAsync,
    required this.reviewsAsync,
  });
  final UserModel provider;
  final AsyncValue<List<ServiceModel>> servicesAsync;
  final AsyncValue<List<dynamic>> reviewsAsync;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'EXPERIENCE',
            value: provider.experienceYears != null
                ? '${provider.experienceYears}+ Years'
                : 'New',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: servicesAsync.when(
            loading: () => const _StatCard(label: 'SERVICES', value: '—'),
            error: (_, __) => const _StatCard(label: 'SERVICES', value: '—'),
            data: (services) => _StatCard(
              label: 'SERVICES',
              value: '${services.where((s) => s.isActive).length}',
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: reviewsAsync.when(
            loading: () => const _StatCard(label: 'REVIEWS', value: '—'),
            error: (_, __) => const _StatCard(label: 'REVIEWS', value: '—'),
            data: (reviews) => _StatCard(
              label: 'REVIEWS',
              value: '${reviews.length}',
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.grey500,
                letterSpacing: 1,
              )),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              )),
        ],
      ),
    );
  }
}

// ── Services Section ─────────────────────────────────────────────────────────

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.servicesAsync});
  final AsyncValue<List<ServiceModel>> servicesAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 3,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Text('Services Offered',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                )),
          ],
        ),
        const SizedBox(height: 14),
        servicesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (services) {
            final active = services.where((s) => s.isActive).toList();
            if (active.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Center(
                  child: Text('No active services',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.grey500,
                      )),
                ),
              );
            }
            return LayoutBuilder(builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 700 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  childAspectRatio: 2.4,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: active.length,
                itemBuilder: (_, i) => _ServiceListCard(service: active[i]),
              );
            });
          },
        ),
      ],
    );
  }
}

class _ServiceListCard extends StatelessWidget {
  const _ServiceListCard({required this.service});
  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/service/${service.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.handyman_outlined,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(service.title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Expanded(
              child: Text(service.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.grey500,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 4),
            Text(
                'PKR ${service.price.toStringAsFixed(0)}${service.priceType == PriceType.startingFrom ? '+' : ''}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Location Section ─────────────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.provider});
  final UserModel provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 3,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text('Location & Service Area',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          if (provider.city != null) ...[
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(provider.city!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondary,
                    )),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (provider.serviceArea != null &&
              provider.serviceArea!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.map_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Serves: ${provider.serviceArea!}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.grey600,
                        height: 1.5,
                      )),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Booking Card (right sidebar) ─────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.provider,
    required this.servicesAsync,
  });
  final UserModel provider;
  final AsyncValue<List<ServiceModel>> servicesAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Book a Service',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              )),
          const SizedBox(height: 6),
          Text(
              'Browse the services below and tap "Book Now" to make an appointment.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.grey500,
                height: 1.5,
              )),
          const SizedBox(height: 20),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          // Experience
          _KV(
              label: 'Experience',
              value: provider.experienceYears != null
                  ? '${provider.experienceYears} years'
                  : 'New'),
          const SizedBox(height: 10),

          // City
          if (provider.city != null) ...[
            _KV(label: 'City', value: provider.city!),
            const SizedBox(height: 10),
          ],

          // Service area
          if (provider.serviceArea != null &&
              provider.serviceArea!.isNotEmpty) ...[
            _KV(label: 'Service Area', value: provider.serviceArea!),
            const SizedBox(height: 10),
          ],

          // Status
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Accepting Bookings',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.grey500,
            )),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              )),
        ),
      ],
    );
  }
}
