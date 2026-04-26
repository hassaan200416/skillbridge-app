
// ---------------------------------------------------------------------------
// service_card.dart
//
// Purpose: Service listing card used on home screen, search results,
// and provider dashboard. The most reused widget in the app.
//
// ---------------------------------------------------------------------------

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/service_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/service_provider.dart';
import '../common/user_avatar.dart';
import '../common/rating_bar_widget.dart';
import 'category_chip.dart';

class ServiceCard extends ConsumerWidget {
  const ServiceCard({
    super.key,
    required this.service,
    this.onTap,
    this.showSaveButton = true,
  });

  final ServiceModel service;
  final VoidCallback? onTap;
  final bool showSaveButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return GestureDetector(
      onTap: onTap ?? () => context.go('/service/${service.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                _ServiceImage(imageUrl: service.thumbnailUrl),
                // Category chip
                Positioned(
                  top: 10,
                  left: 10,
                  child: CategoryChip(category: service.category),
                ),
                // Save button
                if (showSaveButton && currentUser?.isCustomer == true)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _SaveButton(
                      serviceId: service.id,
                      customerId: currentUser!.id,
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    service.title,
                    style: AppTextStyles.headingSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description snippet
                  if (service.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        service.description,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey500,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Provider info
                  Row(
                    children: [
                      UserAvatar(
                        name: service.providerName ?? 'Provider',
                        imageUrl: service.providerAvatarUrl,
                        size: 20,
                        isVerified: service.providerIsVerified ?? false,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          service.providerName ?? 'Provider',
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating, bookings, and price row
                  Row(
                    children: [
                      if (service.reviewCount > 0) ...[
                        RatingDisplay(
                          rating: service.avgRating,
                          reviewCount: service.reviewCount,
                          size: 12,
                        ),
                      ] else ...[
                        Text('New',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.info,
                            )),
                      ],
                      if (service.bookingCount > 0) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.event_available,
                            size: 12, color: AppColors.grey400),
                        const SizedBox(width: 3),
                        Text(
                          '${service.bookingCount} booked',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (service.priceType == PriceType.startingFrom)
                            Text(AppStrings.startingFrom,
                                style: AppTextStyles.caption),
                          Text(
                            'PKR ${service.price.toStringAsFixed(0)}',
                            style: AppTextStyles.priceSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceImage extends StatelessWidget {
  const _ServiceImage({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => _Placeholder(),
        errorWidget: (_, __, ___) => _Placeholder(),
      );
    }
    return _Placeholder();
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      color: AppColors.grey100,
      child: const Icon(
        Icons.home_repair_service_outlined,
        size: 40,
        color: AppColors.grey300,
      ),
    );
  }
}

class _SaveButton extends ConsumerWidget {
  const _SaveButton({
    required this.serviceId,
    required this.customerId,
  });

  final String serviceId;
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedServiceIdsProvider(customerId));
    final isSaved = savedIds.valueOrNull?.contains(serviceId) ?? false;

    return GestureDetector(
      onTap: () {
        ref.read(serviceActionProvider.notifier).toggleSaved(
              customerId: customerId,
              serviceId: serviceId,
            );
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSaved ? Icons.favorite_rounded : Icons.favorite_outline,
          size: 18,
          color: isSaved ? Colors.red : AppColors.grey400,
        ),
      ),
    );
  }
}
