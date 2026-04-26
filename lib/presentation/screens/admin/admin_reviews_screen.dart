// ---------------------------------------------------------------------------
// admin_reviews_screen.dart
//
// Purpose: Review moderation table. Search, filter by rating/flagged,
//   delete flagged reviews. Shows reviewer name+email, service name,
//   rating stars, comment, date, flagged status.
//
// Route: /admin/reviews  (inside AdminShell)
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/review_model.dart';
import '../../providers/review_provider.dart';

const _kPrimary = Color(0xFF2D9B6F);
const _kBg = Color(0xFFF5F7FA);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);
const _kField = Color(0xFFEFF4F9);
const _kAmberFg = Color(0xFFD97706);
const _kGreenFg = Color(0xFF065F46);
const _kGreenBg = Color(0xFFD1FAE5);
const _kRedFg = Color(0xFF991B1B);
const _kRedBg = Color(0xFFFEE2E2);

enum _FlagFilter { all, flaggedOnly }

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  String _search = '';
  int? _ratingFilter;
  _FlagFilter _flag = _FlagFilter.all;

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(allReviewsProvider);

    return Container(
      color: _kBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reviews',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Moderate user reviews and ratings',
              style: GoogleFonts.inter(fontSize: 13.5, color: _kMuted),
            ),
            const SizedBox(height: 24),
            _Controls(
              search: _search,
              ratingFilter: _ratingFilter,
              flagFilter: _flag,
              onSearchChanged: (value) => setState(() => _search = value),
              onRatingChanged: (value) => setState(() => _ratingFilter = value),
              onFlagChanged: (value) => setState(() => _flag = value),
              count: reviewsAsync.maybeWhen(
                data: (reviews) => _apply(reviews).length,
                orElse: () => null,
              ),
            ),
            const SizedBox(height: 20),
            reviewsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child:
                    Center(child: CircularProgressIndicator(color: _kPrimary)),
              ),
              error: (e, _) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kRedBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: _kRedFg, size: 32),
                    const SizedBox(height: 10),
                    Text(
                      'Could not load reviews',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kRedFg,
                      ),
                    ),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: _kRedFg),
                    ),
                  ],
                ),
              ),
              data: (reviews) {
                final filtered = _apply(reviews);
                if (filtered.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 56),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.star_outline,
                              color: _kMuted, size: 26),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No reviews found',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try adjusting your filters',
                          style:
                              GoogleFonts.inter(fontSize: 12.5, color: _kMuted),
                        ),
                      ],
                    ),
                  );
                }
                return _ReviewsTable(reviews: filtered);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<ReviewModel> _apply(List<ReviewModel> list) {
    var out = list;
    if (_flag == _FlagFilter.flaggedOnly) {
      out = out.where((review) => review.isFlagged).toList();
    }
    if (_ratingFilter != null) {
      out = out.where((review) => review.rating == _ratingFilter).toList();
    }
    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();
      out = out.where((review) {
        final reviewer = review.customerName ?? '';
        final service = review.serviceName ?? '';
        final comment = review.comment ?? '';
        return reviewer.toLowerCase().contains(query) ||
            service.toLowerCase().contains(query) ||
            comment.toLowerCase().contains(query);
      }).toList();
    }
    return out;
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.search,
    required this.ratingFilter,
    required this.flagFilter,
    required this.onSearchChanged,
    required this.onRatingChanged,
    required this.onFlagChanged,
    required this.count,
  });

  final String search;
  final int? ratingFilter;
  final _FlagFilter flagFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onRatingChanged;
  final ValueChanged<_FlagFilter> onFlagChanged;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1000;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: onSearchChanged,
            style: GoogleFonts.inter(fontSize: 13.5, color: _kInk),
            decoration: _searchDecoration(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _RatingDrop(value: ratingFilter, onChanged: onRatingChanged),
              _FlagTabs(current: flagFilter, onChanged: onFlagChanged),
              if (count != null) _CountPill(count: count!),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            onChanged: onSearchChanged,
            style: GoogleFonts.inter(fontSize: 13.5, color: _kInk),
            decoration: _searchDecoration(),
          ),
        ),
        const SizedBox(width: 14),
        _RatingDrop(value: ratingFilter, onChanged: onRatingChanged),
        const SizedBox(width: 14),
        _FlagTabs(current: flagFilter, onChanged: onFlagChanged),
        const Spacer(),
        if (count != null) _CountPill(count: count!),
      ],
    );
  }

  InputDecoration _searchDecoration() => InputDecoration(
        hintText: 'Search reviews...',
        hintStyle: GoogleFonts.inter(fontSize: 13.5, color: _kMuted),
        prefixIcon: const Icon(Icons.search, size: 18, color: _kMuted),
        filled: true,
        fillColor: _kField,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
      );
}

class _RatingDrop extends StatelessWidget {
  const _RatingDrop({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _kField,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          hint: Text(
            'All Ratings',
            style: GoogleFonts.inter(fontSize: 13, color: _kMuted),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _kMuted),
          style: GoogleFonts.inter(fontSize: 13, color: _kInk),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'All Ratings',
                style: GoogleFonts.inter(fontSize: 13, color: _kMuted),
              ),
            ),
            for (var i = 5; i >= 1; i--)
              DropdownMenuItem(
                value: i,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var s = 0; s < 5; s++)
                      Icon(
                        s < i ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 14,
                        color: s < i ? _kAmberFg : _kBorder,
                      ),
                  ],
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FlagTabs extends StatelessWidget {
  const _FlagTabs({required this.current, required this.onChanged});

  final _FlagFilter current;
  final ValueChanged<_FlagFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _FlagFilter.values.map((flagFilter) {
          final isActive = flagFilter == current;
          final label = flagFilter == _FlagFilter.all ? 'All' : 'Flagged Only';
          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: InkWell(
              onTap: () => onChanged(flagFilter),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? _kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : _kMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _kField,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count reviews',
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _kMuted,
        ),
      ),
    );
  }
}

class _ReviewsTable extends ConsumerWidget {
  const _ReviewsTable({required this.reviews});

  final List<ReviewModel> reviews;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: _kBg,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(flex: 3, child: _Header('REVIEWER')),
                Expanded(flex: 2, child: _Header('SERVICE')),
                Expanded(flex: 2, child: _Header('RATING')),
                Expanded(flex: 3, child: _Header('COMMENT')),
                Expanded(flex: 2, child: _Header('DATE', center: true)),
                Expanded(flex: 2, child: _Header('STATUS', center: true)),
                Expanded(flex: 1, child: _Header('', center: true)),
              ],
            ),
          ),
          for (var index = 0; index < reviews.length; index++) ...[
            _ReviewRow(review: reviews[index]),
            if (index < reviews.length - 1)
              const Divider(
                  height: 1, color: _kBorder, indent: 20, endIndent: 20),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label, {this.center = false});

  final String label;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _kMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ReviewRow extends ConsumerStatefulWidget {
  const _ReviewRow({required this.review});

  final ReviewModel review;

  @override
  ConsumerState<_ReviewRow> createState() => _ReviewRowState();
}

class _ReviewRowState extends ConsumerState<_ReviewRow> {
  bool _hover = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        decoration: BoxDecoration(
          color: _hover ? _kBg : Colors.transparent,
          border: Border(
            left: BorderSide(
                color: review.isFlagged ? _kRedFg : Colors.transparent,
                width: 3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _Avatar(
                      name: review.customerName, url: review.customerAvatarUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.customerName ?? 'Customer',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kInk,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((review.customerEmail ?? '').isNotEmpty)
                          Text(
                            review.customerEmail!,
                            style:
                                GoogleFonts.inter(fontSize: 11, color: _kMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                review.serviceName ?? 'Service',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kInk,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var star = 0; star < 5; star++)
                    Icon(
                      star < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 15,
                      color: star < review.rating ? _kAmberFg : _kBorder,
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                review.comment ?? '—',
                style:
                    GoogleFonts.inter(fontSize: 13, color: _kInk, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  DateFormat('dd MMM yyyy').format(review.createdAt),
                  style: GoogleFonts.inter(fontSize: 13, color: _kMuted),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: review.isFlagged
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _kRedBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'FLAGGED',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _kRedFg,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _kGreenBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _kGreenFg,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Tooltip(
                  message: review.isFlagged
                      ? 'Delete review'
                      : 'Only flagged reviews can be deleted',
                  child: InkWell(
                    onTap: review.isFlagged && !_busy
                        ? () => _deleteReview(review)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: review.isFlagged ? _kRedBg : _kBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: review.isFlagged
                            ? _kRedFg
                            : _kMuted.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReview(ReviewModel review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete this review?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This action cannot be undone. The review by ${review.customerName ?? 'this customer'} will be permanently removed.',
          style: GoogleFonts.inter(fontSize: 14, color: _kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: _kMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kRedFg),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    await ref.read(reviewActionProvider.notifier).deleteReview(
          reviewId: review.id,
          serviceId: review.serviceId,
          providerId: review.providerId,
        );
    ref.invalidate(allReviewsProvider);
    if (mounted) {
      setState(() => _busy = false);
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.name, this.url});

  final String? name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final initial = (name?.isNotEmpty ?? false) ? name![0].toUpperCase() : '?';
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: _kBorder,
        backgroundImage: NetworkImage(url!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: _kPrimary.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: _kPrimary,
          fontSize: 12,
        ),
      ),
    );
  }
}
