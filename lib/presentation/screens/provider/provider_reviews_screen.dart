
// ---------------------------------------------------------------------------
// provider_reviews_screen.dart
//
// Purpose: Provider reviews screen — overall rating, breakdown bars,
// filterable review list. Routed OUTSIDE ProviderShell, needs own
// Scaffold + ProviderSidebar.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/review_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/review_provider.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/app_top_bar.dart';

class ProviderReviewsScreen extends ConsumerStatefulWidget {
  const ProviderReviewsScreen({super.key});

  @override
  ConsumerState<ProviderReviewsScreen> createState() =>
      _ProviderReviewsScreenState();
}

class _ProviderReviewsScreenState extends ConsumerState<ProviderReviewsScreen> {
  int? _ratingFilter;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final reviewsAsync = ref.watch(providerReviewsProvider(user.id));
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showSidebar = screenWidth >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (showSidebar)
            const AppSidebar(
              role: UserRole.provider,
              currentRoute: '/p/reviews',
            ),
          Expanded(
            child: Material(
              color: AppColors.background,
              child: Column(
                children: [
                  const AppTopBar(),
                  Expanded(
                    child: reviewsAsync.when(
                      loading: () => const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (reviews) {
                        final filtered = _ratingFilter == null
                            ? reviews
                            : reviews
                                .where((r) => r.rating == _ratingFilter)
                                .toList();
                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Header(reviews: reviews),
                              const SizedBox(height: 24),
                              _FilterChips(
                                selected: _ratingFilter,
                                onChange: (v) =>
                                    setState(() => _ratingFilter = v),
                              ),
                              const SizedBox(height: 20),
                              _ReviewsList(reviews: filtered),
                              const SizedBox(height: 40),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.reviews});
  final List<ReviewModel> reviews;

  @override
  Widget build(BuildContext context) {
    final total = reviews.length;
    double avg = 0;
    if (total > 0) {
      avg = reviews.fold<int>(0, (s, r) => s + r.rating) / total;
    }

    // Breakdown
    final breakdown = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      breakdown[r.rating] = (breakdown[r.rating] ?? 0) + 1;
    }

    final screenW = MediaQuery.sizeOf(context).width;
    final wide = screenW >= 1000;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 35,
                  child: _titleBlock(avg, total),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 25,
                  child: _ratingCircle(avg, total),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 40,
                  child: _breakdownBars(breakdown, total),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titleBlock(avg, total),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ratingCircle(avg, total)),
                    const SizedBox(width: 20),
                    Expanded(child: _breakdownBars(breakdown, total)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _titleBlock(double avg, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PERFORMANCE OVERVIEW',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 1.5,
            )),
        const SizedBox(height: 6),
        Text('Reviews',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            )),
        const SizedBox(height: 6),
        Text('Feedback from the SkillBridge community about your work.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.grey500,
              height: 1.5,
            )),
      ],
    );
  }

  Widget _ratingCircle(double avg, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(avg.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return Icon(
                i < avg.round() ? Icons.star : Icons.star_border,
                color: const Color(0xFFF6AD55),
                size: 20,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text('Based on $total customer review${total == 1 ? '' : 's'}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.grey500,
              )),
        ],
      ),
    );
  }

  Widget _breakdownBars(Map<int, int> breakdown, int total) {
    return Column(
      children: [5, 4, 3, 2, 1].map((star) {
        final count = breakdown[star] ?? 0;
        final pct = total > 0 ? count / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                child: Text('$star',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey600,
                    )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: AppColors.grey100,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 36,
                child: Text('${(pct * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.grey500,
                    )),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Filter Chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onChange,
  });
  final int? selected;
  final void Function(int?) onChange;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('All Reviews', null),
          const SizedBox(width: 8),
          ...List.generate(5, (i) {
            final star = 5 - i;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _chip('$star ★', star),
            );
          }),
        ],
      ),
    );
  }

  Widget _chip(String label, int? value) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onChange(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.secondary,
            )),
      ),
    );
  }
}

// ── Reviews List ──────────────────────────────────────────────────────────────

class _ReviewsList extends StatelessWidget {
  const _ReviewsList({required this.reviews});
  final List<ReviewModel> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            const Icon(Icons.star_outline, size: 48, color: AppColors.grey300),
            const SizedBox(height: 14),
            Text('No reviews yet',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey500,
                )),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 800;
      if (wide) {
        // 2-column masonry-like grid
        final left = <ReviewModel>[];
        final right = <ReviewModel>[];
        for (int i = 0; i < reviews.length; i++) {
          if (i % 2 == 0) {
            left.add(reviews[i]);
          } else {
            right.add(reviews[i]);
          }
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Column(
              children: left.map((r) => _ReviewCard(review: r)).toList(),
            )),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
              children: right.map((r) => _ReviewCard(review: r)).toList(),
            )),
          ],
        );
      }
      return Column(
        children: reviews.map((r) => _ReviewCard(review: r)).toList(),
      );
    });
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final initials = (review.customerName ?? 'C')
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .take(2)
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.grey200,
                child: Text(initials,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey600,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.customerName ?? 'Customer',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        )),
                    Text(DateFormat('MMM d, y').format(review.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grey500,
                        )),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFF6AD55),
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '"${review.comment}"',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.secondary,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
