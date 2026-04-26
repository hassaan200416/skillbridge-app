
// ---------------------------------------------------------------------------
// service_detail_screen.dart
//
// Purpose: Full service detail page with image gallery, provider info,
// AI review summary, client testimonials, booking card, and related services.
// Web layout: sidebar + two-column main content.
//
// ---------------------------------------------------------------------------

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/review_provider.dart';
import '../../../presentation/providers/service_provider.dart';
import '../../../presentation/widgets/common/app_error_widget.dart';
import '../../../presentation/widgets/common/app_loading.dart';
import '../../../presentation/widgets/common/app_sidebar.dart';
import '../../../presentation/widgets/common/app_top_bar.dart';
import '../../../presentation/widgets/common/rating_bar_widget.dart';
import '../../../presentation/widgets/common/user_avatar.dart';
import '../../../presentation/widgets/service/service_card.dart';
import '../../widgets/common/skillbot_widget.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  int _selectedImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AppSidebar(role: UserRole.customer, currentRoute: '/service'),
          Expanded(
            child: serviceAsync.when(
              loading: () => const Center(child: AppLoading()),
              error: (e, _) => Center(
                child: AppErrorWidget(message: e.toString()),
              ),
              data: (service) {
                final reviewsAsync =
                    ref.watch(serviceReviewsProvider(widget.serviceId));
                final aiSummaryAsync = ref.watch(aiSummaryProvider(service));
                final relatedAsync =
                    ref.watch(searchResultsProvider(SearchParams(
                  category: service.category,
                )));

                return Column(
                  children: [
                    // Top bar
                    const AppTopBar(),
                    // Content
                    Expanded(
                      child: SkillBotWidget(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    } else {
                                      context.go(RouteNames.search);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.arrow_back_ios_new,
                                          size: 14, color: Color(0xFF64748B)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Back to services',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Breadcrumb
                              _Breadcrumb(
                                category: service.category.displayName,
                                categoryValue: service.category.value,
                                title: service.title,
                              ),
                              const SizedBox(height: 20),

                              // Main two-column layout
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // LEFT column - 65%
                                  Expanded(
                                    flex: 65,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Image gallery
                                        _ImageGallery(
                                          imageUrls: service.imageUrls,
                                          selectedIndex: _selectedImageIndex,
                                          onSelect: (i) => setState(
                                              () => _selectedImageIndex = i),
                                          category: service.category,
                                        ),
                                        const SizedBox(height: 24),

                                        // Title + tags
                                        Text(
                                          service.title,
                                          style: GoogleFonts.poppins(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            _TagChip(
                                              label:
                                                  service.category.displayName,
                                              color: AppColors.primary,
                                            ),
                                            if (service.providerIsVerified ==
                                                true)
                                              const _TagChip(
                                                label: 'Verified Provider',
                                                color: AppColors.info,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),

                                        // Description
                                        Text(
                                          service.description,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            color: AppColors.grey600,
                                            height: 1.7,
                                          ),
                                        ),
                                        const SizedBox(height: 24),

                                        // Provider card
                                        _ProviderCard(
                                          service: service,
                                        ),
                                        const SizedBox(height: 28),

                                        // Reviews
                                        reviewsAsync.when(
                                          loading: () =>
                                              const SizedBox.shrink(),
                                          error: (_, __) =>
                                              const SizedBox.shrink(),
                                          data: (reviews) => _ReviewsSection(
                                            reviews: reviews,
                                            avgRating: service.avgRating,
                                            reviewCount: service.reviewCount,
                                          ),
                                        ),

                                        const SizedBox(height: 40),

                                        // Related services
                                        relatedAsync.when(
                                          loading: () =>
                                              const SizedBox.shrink(),
                                          error: (_, __) =>
                                              const SizedBox.shrink(),
                                          data: (services) {
                                            final filtered = services
                                                .where((s) =>
                                                    s.id != widget.serviceId)
                                                .take(3)
                                                .toList();
                                            if (filtered.isEmpty) {
                                              return const SizedBox.shrink();
                                            }
                                            return _RelatedServices(
                                              services: filtered,
                                              category:
                                                  service.category.displayName,
                                              categoryValue:
                                                  service.category.value,
                                            );
                                          },
                                        ),

                                        // Footer
                                        const SizedBox(height: 40),
                                        const _Footer(),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 24),

                                  // RIGHT column - 35% sticky
                                  SizedBox(
                                    width: 320,
                                    child: Column(
                                      children: [
                                        // Booking card
                                        _BookingCard(
                                          service: service,
                                          currentUser: currentUser,
                                        ),
                                        const SizedBox(height: 16),

                                        // AI summary
                                        aiSummaryAsync.when(
                                          loading: () =>
                                              const SizedBox.shrink(),
                                          error: (_, __) =>
                                              const SizedBox.shrink(),
                                          data: (summary) => summary != null
                                              ? _AISummaryCard(summary: summary)
                                              : const SizedBox.shrink(),
                                        ),

                                        const SizedBox(height: 16),

                                        // Message + Share
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () async {
                                                  final user = ref.read(
                                                      currentUserProvider);
                                                  if (user == null) return;
                                                  try {
                                                    final convo =
                                                        await ChatRepository
                                                            .instance
                                                            .getOrCreateConversation(
                                                      customerId: user.id,
                                                      providerId:
                                                          service.providerId,
                                                      serviceId: service.id,
                                                    );
                                                    if (context.mounted) {
                                                      context.go(
                                                          '/chat/${convo.id}');
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Could not start conversation: $e'),
                                                          backgroundColor:
                                                              Colors
                                                                  .red.shade700,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                icon: const Icon(
                                                    Icons.message_outlined,
                                                    size: 16),
                                                label: const Text('Message'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      AppColors.secondary,
                                                  side: const BorderSide(
                                                      color: AppColors.border),
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 12),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () {},
                                                icon: const Icon(
                                                    Icons.share_outlined,
                                                    size: 16),
                                                label: const Text('Share'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      AppColors.secondary,
                                                  side: const BorderSide(
                                                      color: AppColors.border),
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

// -- Breadcrumb ---------------------------------------------------------------

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({
    required this.category,
    required this.categoryValue,
    required this.title,
  });
  final String category;
  final String categoryValue;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go(RouteNames.search),
          child: Text('Marketplace',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 16, color: AppColors.grey400),
        ),
        GestureDetector(
          onTap: () =>
              context.go('${RouteNames.search}?category=$categoryValue'),
          child: Text(category,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 16, color: AppColors.grey400),
        ),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// -- Image Gallery ------------------------------------------------------------

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({
    required this.imageUrls,
    required this.selectedIndex,
    required this.onSelect,
    required this.category,
  });

  final List<String> imageUrls;
  final int selectedIndex;
  final void Function(int) onSelect;
  final ServiceCategory category;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main image
        Expanded(
          child: Container(
            height: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.grey100,
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrls[selectedIndex],
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        _ImagePlaceholder(category: category),
                    errorWidget: (_, __, ___) =>
                        _ImagePlaceholder(category: category),
                  )
                : _ImagePlaceholder(category: category),
          ),
        ),

        // Thumbnail strip
        if (imageUrls.length > 1) ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Column(
              children: [
                ...imageUrls
                    .take(3)
                    .toList()
                    .asMap()
                    .entries
                    .map((e) => GestureDetector(
                          onTap: () => onSelect(e.key),
                          child: Container(
                            height: 96,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedIndex == e.key
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: e.value,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )),
                if (imageUrls.length > 3)
                  Container(
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    child: Center(
                      child: Text(
                        '+${imageUrls.length - 3} Photos',
                        style: GoogleFonts.inter(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Column(
              children: List.generate(
                  3,
                  (_) => Container(
                        height: 96,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.grey200,
                        ),
                        child:
                            _ImagePlaceholder(category: category, small: true),
                      )),
            ),
          ),
        ],
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.category, this.small = false});
  final ServiceCategory category;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey100,
      child: Center(
        child: Icon(
          Icons.home_repair_service_outlined,
          size: small ? 24 : 48,
          color: AppColors.grey300,
        ),
      ),
    );
  }
}

// -- Tag Chip -----------------------------------------------------------------

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// -- Provider Card ------------------------------------------------------------

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.service});
  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          UserAvatar(
            name: service.providerName ?? 'Provider',
            imageUrl: service.providerAvatarUrl,
            size: 56,
            isVerified: service.providerIsVerified ?? false,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ELITE PROVIDER',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  service.providerName ?? 'Provider',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  'Verified Professional',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: OutlinedButton(
              onPressed: () => context.go('/provider/${service.providerId}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text('View Profile',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Reviews Section ----------------------------------------------------------

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({
    required this.reviews,
    required this.avgRating,
    required this.reviewCount,
  });

  final List reviews;
  final double avgRating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Client Testimonials',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            RatingDisplay(
              rating: avgRating,
              reviewCount: reviewCount,
              size: 18,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...reviews.take(3).map((r) => _ReviewCard(
              review: r,
            )),
      ],
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.review});
  final dynamic review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: review.customerName ?? 'Customer',
                imageUrl: review.customerAvatarUrl,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName ?? 'Customer',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(review.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              RatingDisplay(
                rating: (review.rating as int).toDouble(),
                showCount: false,
                size: 14,
              ),
              IconButton(
                onPressed: () async {
                  final user = ref.read(currentUserProvider);
                  if (user == null) return;

                  final already =
                      await ReviewRepository.instance.hasUserFlaggedReview(
                    userId: user.id,
                    reviewId: review.id,
                  );

                  if (already) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You have already flagged this review'),
                        ),
                      );
                    }
                    return;
                  }

                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Flag this review?',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        content: Text(
                            'This review will be reported for admin moderation.',
                            style: GoogleFonts.inter(fontSize: 14)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Cancel',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF64748B))),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await ReviewRepository.instance.flagReview(
                                userId: user.id,
                                reviewId: review.id,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Review flagged for moderation'),
                                    backgroundColor: Color(0xFF2D9B6F),
                                  ),
                                );
                              }
                            },
                            child: Text('Flag',
                                style: GoogleFonts.inter(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.flag_outlined,
                    size: 16, color: Color(0xFF64748B)),
                splashRadius: 16,
                tooltip: 'Flag review',
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.grey600,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -- Booking Card -------------------------------------------------------------

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.service,
    required this.currentUser,
  });

  final ServiceModel service;
  final UserModel? currentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STARTING PRICE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey400,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PKR ${service.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  service.priceType == PriceType.startingFrom
                      ? 'Starting From'
                      : 'Fixed Price',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),

          // Available days
          Text(
            'Select Availability',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: service.availableDays
                .take(4)
                .map((day) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        day.substring(0, 3).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 14),

          // Insurance note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Includes Service Quality Guarantee',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Book now button
          if (currentUser?.isCustomer == true && service.isActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/book/${service.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Book now',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),
          Center(
            child: Text(
              'No charge until service is confirmed',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.grey400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- AI Summary Card ----------------------------------------------------------

class _AISummaryCard extends StatelessWidget {
  const _AISummaryCard({required this.summary});
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.starColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 16, color: AppColors.starColor),
              const SizedBox(width: 6),
              Text(
                'AI Sentiment Summary',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome,
                  size: 20, color: AppColors.starColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.grey600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryBadge(label: '98% POSITIVE'),
              const SizedBox(width: 8),
              _SummaryBadge(label: 'TOP 1% SKILLS'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.starColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.starColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// -- Related Services ---------------------------------------------------------

class _RelatedServices extends StatelessWidget {
  const _RelatedServices({
    required this.services,
    required this.category,
    required this.categoryValue,
  });

  final List services;
  final String category;
  final String categoryValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'You may also like',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  context.go('${RouteNames.search}?category=$categoryValue'),
              child: Text(
                'Explore Category ->',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: services
              .map((s) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ServiceCard(service: s as dynamic),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// -- Footer -------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SkillBridge',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The premier destination for\ndiscovering trusted local\nservice providers.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.grey500,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              // Platform
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...['How it works', 'Service Guarantee', 'Support Center']
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                item,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.grey500,
                                ),
                              ),
                            )),
                  ],
                ),
              ),

              // Legal
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Legal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...['Terms of Service', 'Privacy Policy', 'Cookie Policy']
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                item,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.grey500,
                                ),
                              ),
                            )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '© 2024 SkillBridge. All rights reserved.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.grey400,
                ),
              ),
              const Spacer(),
              ...['Instagram', 'LinkedIn', 'Twitter'].map((s) => Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      s,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.grey500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
