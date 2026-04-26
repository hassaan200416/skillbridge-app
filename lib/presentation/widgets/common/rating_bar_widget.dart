
// ---------------------------------------------------------------------------
// rating_bar_widget.dart
//
// Purpose: Star rating display and input widget.
// Used on service cards, review forms, and profile pages.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Display-only star rating with optional count
class RatingDisplay extends StatelessWidget {
  const RatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 14,
    this.showCount = true,
  });

  final double rating;
  final int? reviewCount;
  final double size;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (_, __) => const Icon(
            Icons.star_rounded,
            color: AppColors.starColor,
          ),
          itemCount: 5,
          itemSize: size,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        if (showCount && reviewCount != null) ...[
          const SizedBox(width: 2),
          Text(
            '($reviewCount)',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// Interactive star rating input — for review forms
class RatingInput extends StatelessWidget {
  const RatingInput({
    super.key,
    required this.onRatingUpdate,
    this.initialRating = 0,
    this.size = 40,
  });

  final void Function(double) onRatingUpdate;
  final double initialRating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: initialRating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: false,
      itemCount: 5,
      itemSize: size,
      itemBuilder: (_, __) => const Icon(
        Icons.star_rounded,
        color: AppColors.starColor,
      ),
      onRatingUpdate: onRatingUpdate,
    );
  }
}
