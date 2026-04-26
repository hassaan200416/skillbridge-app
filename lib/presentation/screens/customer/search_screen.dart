// ---------------------------------------------------------------------------
// search_screen.dart
//
// Purpose: Service discovery with AI-powered search, category filter
// chips, and 4-column service grid. Web layout: sidebar + main content.
//
// ---------------------------------------------------------------------------

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/service_model.dart';
import '../../../presentation/providers/service_provider.dart';
import '../../../services/ai_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialCategory, this.initialQuery});
  final String? initialCategory;
  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  bool _isAiSearching = false;
  bool _showAiBanner = false;
  int _displayLimit = 8;

  @override
  void initState() {
    super.initState();
    // If we have an initial query, set loading immediately
    // to prevent the build from showing default/all results
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _isAiSearching = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery != null &&
          widget.initialQuery!.trim().isNotEmpty) {
        // Pre-fill from header search bar and trigger AI search
        _searchController.text = widget.initialQuery!;
        _performAiSearch(widget.initialQuery!);
      } else if (widget.initialCategory != null) {
        final category =
            ServiceCategoryExtension.fromString(widget.initialCategory!);
        ref.read(searchParamsProvider.notifier).state =
            SearchParams(category: category);
      } else {
        // Default: load all services sorted by rating
        ref.read(searchParamsProvider.notifier).state =
            const SearchParams(sortBy: 'rating');
      }
    });
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If query parameter changed (user searched again from header),
    // trigger a new AI search
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != null &&
        widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performAiSearch(widget.initialQuery!);
    }
    // If category parameter changed
    if (widget.initialCategory != oldWidget.initialCategory &&
        widget.initialCategory != null) {
      final category =
          ServiceCategoryExtension.fromString(widget.initialCategory!);
      ref.read(searchParamsProvider.notifier).state =
          SearchParams(category: category);
      setState(() {
        _showAiBanner = false;
        _displayLimit = 8;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performAiSearch(String query) async {
    if (query.trim().isEmpty) return;
    if (mounted) {
      setState(() {
        _isAiSearching = true;
        _showAiBanner = false;
      });
    }
    try {
      final extraction =
          await AiService.instance.extractSearchParameters(query);
      if (mounted) {
        // If AI detected a category, use category filter only
        // (don't combine with text query — ILIKE phrase matching
        // is too strict and returns no results)
        // Only use text query if no category was detected
        ServiceCategory? detectedCategory = extraction.category != null
            ? ServiceCategoryExtension.fromString(extraction.category!)
            : null;

        // Fallback: if AI didn't detect a category, try matching
        // the original query against category names locally
        detectedCategory ??= _tryMatchCategory(query);

        ref.read(searchParamsProvider.notifier).state = SearchParams(
          query: detectedCategory != null ? '' : extraction.cleanQuery,
          category: detectedCategory,
          maxPrice: extraction.maxPrice,
        );
        setState(() {
          _showAiBanner = true;
          _displayLimit = 8;
        });
      }
    } catch (_) {
      if (mounted) {
        ref.read(searchParamsProvider.notifier).state =
            SearchParams(query: query);
      }
    } finally {
      if (mounted) {
        setState(() => _isAiSearching = false);
      }
    }
  }

  /// Local fallback: try to match query text against category names
  ServiceCategory? _tryMatchCategory(String query) {
    final q = query.toLowerCase();
    const categoryKeywords = {
      'plumber': ServiceCategory.plumber,
      'plumbing': ServiceCategory.plumber,
      'pipe': ServiceCategory.plumber,
      'cleaning': ServiceCategory.cleaning,
      'clean': ServiceCategory.cleaning,
      'maid': ServiceCategory.cleaning,
      'electrician': ServiceCategory.electrician,
      'electrical': ServiceCategory.electrician,
      'wiring': ServiceCategory.electrician,
      'ac repair': ServiceCategory.electrician,
      'tutor': ServiceCategory.tutoring,
      'tutoring': ServiceCategory.tutoring,
      'tuition': ServiceCategory.tutoring,
      'teaching': ServiceCategory.tutoring,
      'math': ServiceCategory.tutoring,
      'beauty': ServiceCategory.beauty,
      'makeup': ServiceCategory.beauty,
      'bridal': ServiceCategory.beauty,
      'salon': ServiceCategory.beauty,
      'mechanic': ServiceCategory.mechanic,
      'car': ServiceCategory.mechanic,
      'vehicle': ServiceCategory.mechanic,
      'oil change': ServiceCategory.mechanic,
      'home repair': ServiceCategory.homeRepair,
      'renovation': ServiceCategory.homeRepair,
      'repair': ServiceCategory.homeRepair,
      'design': ServiceCategory.graphicDesign,
      'logo': ServiceCategory.graphicDesign,
      'graphic': ServiceCategory.graphicDesign,
      'moving': ServiceCategory.moving,
      'shifting': ServiceCategory.moving,
      'movers': ServiceCategory.moving,
    };

    for (final entry in categoryKeywords.entries) {
      if (q.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final params = ref.watch(searchParamsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI banner
          if (_showAiBanner) ...[
            _AiBanner(
              query: _searchController.text,
              onRefine: () {
                _searchController.clear();
                ref.read(searchParamsProvider.notifier).state =
                    const SearchParams();
                setState(() => _showAiBanner = false);
              },
            ),
            const SizedBox(height: 20),
          ],
          // Search bar removed — header AppTopBar has the only search bar
          // Category chips
          _CategoryChips(
            selectedCategory: params.category,
            onSelect: (cat) {
              // Clear text query when selecting a category chip
              ref.read(searchParamsProvider.notifier).state = SearchParams(
                query: '',
                category: cat,
                sortBy: params.sortBy,
              );
              setState(() {
                _displayLimit = 8;
                _showAiBanner = false;
              });
            },
          ),
          const SizedBox(height: 28),
          // Results (show loading while AI search is processing)
          if (_isAiSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('AI is analyzing your search...'),
                  ],
                ),
              ),
            )
          else
            _ResultsSection(
              params: params,
              displayLimit: _displayLimit,
              onLoadMore: () => setState(() => _displayLimit += 8),
            ),
        ],
      ),
    );
  }
}

// ── AI Banner ─────────────────────────────────────────────────────────────────

class _AiBanner extends StatelessWidget {
  const _AiBanner({required this.query, required this.onRefine});
  final String query;
  final VoidCallback onRefine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-Powered Curation Active',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4A2C00),
                  ),
                ),
                Text(
                  'Results personalized based on your search: "$query"',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF7A4A00),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onRefine,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D2D2D),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
              maximumSize: const Size(220, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('Refine Intent',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Category Chips ────────────────────────────────────────────────────────────

class _CategoryChips extends StatefulWidget {
  const _CategoryChips({
    required this.selectedCategory,
    required this.onSelect,
  });

  final ServiceCategory? selectedCategory;
  final void Function(ServiceCategory?) onSelect;

  @override
  State<_CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<_CategoryChips> {
  final _scrollController = ScrollController();

  static final _categories = [
    null,
    ServiceCategory.homeRepair,
    ServiceCategory.cleaning,
    ServiceCategory.electrician,
    ServiceCategory.plumber,
    ServiceCategory.tutoring,
    ServiceCategory.beauty,
    ServiceCategory.graphicDesign,
    ServiceCategory.mechanic,
    ServiceCategory.moving,
    ServiceCategory.other,
  ];

  static const _labels = [
    'All Services',
    'Home Repair',
    'Cleaning',
    'Electrician',
    'Plumber',
    'Tutoring',
    'Beauty',
    'Design',
    'Mechanic',
    'Moving',
    'Other',
  ];

  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - 200).clamp(0.0, double.infinity),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ArrowButton(
          icon: Icons.chevron_left,
          onTap: _scrollLeft,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              children: List.generate(_categories.length, (i) {
                final isSelected = _categories[i] == widget.selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => widget.onSelect(_categories[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        _labels[i],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _ArrowButton(
          icon: Icons.chevron_right,
          onTap: _scrollRight,
        ),
        const SizedBox(width: 10),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.tune, size: 16),
            label: Text('Filters',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.secondary),
      ),
    );
  }
}

// ── Results Section ───────────────────────────────────────────────────────────

class _ResultsSection extends ConsumerWidget {
  const _ResultsSection({
    required this.params,
    required this.displayLimit,
    required this.onLoadMore,
  });

  final SearchParams params;
  final int displayLimit;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider(params));

    return resultsAsync.when(
      loading: () => const Center(
          child: Padding(
        padding: EdgeInsets.only(top: 80),
        child: CircularProgressIndicator(color: AppColors.primary),
      )),
      error: (e, _) => Center(
          child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Text('Error loading services',
            style: TextStyle(color: AppColors.grey500)),
      )),
      data: (allServices) {
        if (allServices.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  const Icon(Icons.search_off,
                      size: 64, color: AppColors.grey300),
                  const SizedBox(height: 16),
                  Text('No services found',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey500)),
                  const SizedBox(height: 8),
                  Text('Try a different search or category',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.grey400)),
                ],
              ),
            ),
          );
        }

        final displayed = allServices.take(displayLimit).toList();
        final hasMore = allServices.length > displayLimit;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading + count
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 760;

                final heading = Text(
                  'Discover Master Craftsmen',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );

                final count = Text(
                  '${allServices.length} services found in your area',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.grey500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: isCompact ? TextAlign.left : TextAlign.right,
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [heading, const SizedBox(height: 4), count],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 16),
                    Flexible(child: count),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // 4-column grid
            LayoutBuilder(builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                      ? 3
                      : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: displayed.length,
                itemBuilder: (_, i) => _ServiceGridCard(service: displayed[i]),
              );
            }),

            // Load more
            if (hasMore) ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 240,
                      child: ElevatedButton(
                        onPressed: onLoadMore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text('Explore More Artisans',
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Showing ${displayed.length} of ${allServices.length} results',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.grey400),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}

// ── Service Grid Card ─────────────────────────────────────────────────────────

class _ServiceGridCard extends StatelessWidget {
  const _ServiceGridCard({required this.service});
  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    // Assign badge based on rating or verification
    String? badge;
    Color? badgeColor;
    if (service.avgRating >= 4.8) {
      badge = 'EXPERT';
      badgeColor = AppColors.primary;
    } else if (service.avgRating >= 4.5) {
      badge = 'LOCAL FAVORITE';
      badgeColor = const Color(0xFF8B5E3C);
    }

    return GestureDetector(
      onTap: () => context.go('/service/${service.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: (service.imageUrls.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: service.imageUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AppColors.grey100,
                                child: const Icon(
                                    Icons.home_repair_service_outlined,
                                    size: 40,
                                    color: AppColors.grey300)),
                            errorWidget: (_, __, ___) => Container(
                                color: AppColors.grey100,
                                child: const Icon(
                                    Icons.home_repair_service_outlined,
                                    size: 40,
                                    color: AppColors.grey300)),
                          )
                        : Container(
                            color: AppColors.grey100,
                            child: const Icon(
                                Icons.home_repair_service_outlined,
                                size: 40,
                                color: AppColors.grey300),
                          ),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.grey500,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price type label
                    Text(
                      service.priceType == PriceType.startingFrom
                          ? 'Starting at'
                          : 'Fixed Price',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.grey400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Price + rating row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.priceType == PriceType.startingFrom
                              ? 'PKR ${service.price.toStringAsFixed(0)}+'
                              : 'PKR ${service.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: AppColors.starColor),
                            const SizedBox(width: 3),
                            Text(
                              service.avgRating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
