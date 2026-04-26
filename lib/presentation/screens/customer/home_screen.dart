// ---------------------------------------------------------------------------
// home_screen.dart
//
// Purpose: Customer dashboard - main discovery screen.
// Web layout: sidebar navigation + main scrollable content.
// Features: hero search, category grid, featured services,
// recently added services, AI search integration.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/service_provider.dart';
import '../../../presentation/widgets/common/app_error_widget.dart';
import '../../../presentation/widgets/common/app_loading.dart';
import '../../../presentation/widgets/service/service_card.dart';
import '../../widgets/common/skillbot_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final featured = ref.watch(featuredServicesProvider);
    final recent = ref.watch(recentServicesProvider);
    return SkillBotWidget(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(featuredServicesProvider);
          ref.invalidate(recentServicesProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBanner(
                userName: currentUser?.name.split(' ').first ?? 'there',
              ),
              const SizedBox(height: 32),
              _SectionHeader(
                title: 'Browse by Category',
                subtitle: 'Find services for every need',
                actionLabel: 'View all categories →',
                onAction: () => context.go(RouteNames.search),
              ),
              const SizedBox(height: 16),
              const _CategoryGrid(),
              const SizedBox(height: 32),
              _SectionHeader(
                title: 'Featured Services',
                subtitle: 'Hand-picked providers with exceptional ratings',
                actionLabel: 'See all →',
                onAction: () => context.go(RouteNames.search),
              ),
              const SizedBox(height: 16),
              featured.when(
                loading: () => const _FeaturedShimmer(),
                error: (e, _) => AppErrorWidget(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(featuredServicesProvider),
                ),
                data: (services) => services.isEmpty
                    ? const SizedBox.shrink()
                    : _FeaturedRow(services: services),
              ),
              const SizedBox(height: 32),
              _SectionHeader(
                title: 'Recently Added',
                subtitle: 'New providers joining SkillBridge',
                actionLabel: 'See all →',
                onAction: () => context.go(RouteNames.search),
              ),
              const SizedBox(height: 16),
              recent.when(
                loading: () => const _RecentShimmer(isWebLayout: true),
                error: (e, _) => AppErrorWidget(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(recentServicesProvider),
                ),
                data: (services) => services.isEmpty
                    ? const SizedBox.shrink()
                    : _RecentGrid(services: services),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatefulWidget {
  const _HeroBanner({required this.userName});
  final String userName;

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2B3C), Color(0xFF2D9B6F)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${widget.userName}.',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What will you discover today?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover local expertise for your home or business.\nYour next project starts with a single search.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.white.withValues(alpha: 0.75),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Material(
                          type: MaterialType.transparency,
                          child: TextField(
                            controller: _controller,
                            cursorColor: AppColors.white,
                            style: GoogleFonts.inter(
                              color: AppColors.white,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Find the perfect artisan...',
                              hintStyle: GoogleFonts.inter(
                                color: AppColors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (val) {
                              final q = val.trim();
                              if (q.isNotEmpty) {
                                context.go(
                                  '/search?q=${Uri.encodeComponent(q)}',
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 96,
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () {
                            final q = _controller.text.trim();
                            if (q.isNotEmpty) {
                              context.go('/search?q=${Uri.encodeComponent(q)}');
                            } else {
                              context.go('/search');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F3C33),
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Explore',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final _categories = const [
    ('🔧', 'Home Repair', 'home_repair'),
    ('📚', 'Tutoring', 'tutoring'),
    ('🧹', 'Cleaning', 'cleaning'),
    ('⚡', 'Electrician', 'electrician'),
    ('🚿', 'Plumber', 'plumber'),
    ('🔩', 'Mechanic', 'mechanic'),
    ('💅', 'Beauty', 'beauty'),
    ('🎨', 'Graphic Design', 'graphic_design'),
    ('📦', 'Moving', 'moving'),
    ('✨', 'Other', 'other'),
  ];

  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 10 : 5;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final cat = _categories[i];
            return _CategoryCard(
              emoji: cat.$1,
              label: cat.$2,
              value: cat.$3,
            );
          },
        );
      },
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.emoji,
    required this.label,
    required this.value,
  });

  final String emoji;
  final String label;
  final String value;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(
          '/search?category=${widget.value}',
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? AppColors.primary : AppColors.divider,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedRow extends StatelessWidget {
  const _FeaturedRow({required this.services});
  final List services;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 24) / 3;
        return SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) => SizedBox(
              width: itemWidth,
              child: ServiceCard(service: services[i] as dynamic),
            ),
          ),
        );
      },
    );
  }
}

class _FeaturedShimmer extends StatelessWidget {
  const _FeaturedShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => const SizedBox(
          width: 280,
          child: ServiceCardShimmer(),
        ),
      ),
    );
  }
}

class _RecentGrid extends StatelessWidget {
  const _RecentGrid({required this.services});
  final List services;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 360,
            mainAxisExtent: 300,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: services.length > 8 ? 8 : services.length,
          itemBuilder: (_, i) => ServiceCard(service: services[i] as dynamic),
        );
      },
    );
  }
}

class _RecentShimmer extends StatelessWidget {
  const _RecentShimmer({required this.isWebLayout});
  final bool isWebLayout;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisExtent: 300,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: isWebLayout ? 4 : 2,
      itemBuilder: (_, __) => const ServiceCardShimmer(),
    );
  }
}
