
// ---------------------------------------------------------------------------
// category_chip.dart
//
// Purpose: Category badge shown on service cards and filter chips.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/service_model.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
    this.compact = false,
  });

  final ServiceCategory category;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getCategoryEmoji(category),
              style: TextStyle(fontSize: compact ? 10 : 12),
            ),
            const SizedBox(width: 4),
            Text(
              category.displayName,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.white : AppColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryEmoji(ServiceCategory cat) {
    switch (cat) {
      case ServiceCategory.homeRepair: return '🔧';
      case ServiceCategory.tutoring: return '📚';
      case ServiceCategory.cleaning: return '🧹';
      case ServiceCategory.electrician: return '⚡';
      case ServiceCategory.plumber: return '🚿';
      case ServiceCategory.mechanic: return '🔩';
      case ServiceCategory.beauty: return '💅';
      case ServiceCategory.graphicDesign: return '🎨';
      case ServiceCategory.moving: return '📦';
      case ServiceCategory.other: return '✨';
    }
  }
}

