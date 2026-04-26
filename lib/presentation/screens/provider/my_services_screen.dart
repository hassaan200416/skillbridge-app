
// ---------------------------------------------------------------------------
// my_services_screen.dart
//
// Purpose: Provider's service management — grid of service cards with
// edit + activate/deactivate actions, tab filter (All/Active/Inactive).
//
// ---------------------------------------------------------------------------

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/service_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/service_provider.dart';
import '../../widgets/common/provider_skillbot_widget.dart';

class MyServicesScreen extends ConsumerStatefulWidget {
  const MyServicesScreen({super.key, this.searchQuery});
  final String? searchQuery;

  @override
  ConsumerState<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends ConsumerState<MyServicesScreen> {
  String _searchFilter = '';
  String _filter = 'all'; // all | active | inactive

  @override
  void initState() {
    super.initState();
    _searchFilter = widget.searchQuery ?? '';
  }

  @override
  void didUpdateWidget(covariant MyServicesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      setState(() => _searchFilter = widget.searchQuery ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final servicesAsync = ref.watch(providerServicesProvider(user.id));

    return ProviderSkillBotWidget(
      child: servicesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (services) {
          final tabFiltered = switch (_filter) {
            'active' => services.where((s) => s.isActive).toList(),
            'inactive' => services.where((s) => !s.isActive).toList(),
            _ => services,
          };

          // Apply search filter from header search bar
          final q = _searchFilter.trim().toLowerCase();
          final filtered = q.isEmpty
              ? tabFiltered
              : tabFiltered.where((s) {
                  final title =
                      (s.title as Object?)?.toString().toLowerCase() ?? '';
                  final description =
                      (s.description as Object?)?.toString().toLowerCase() ??
                          '';
                  final category = s.category.name.toLowerCase();
                  return title.contains(q) ||
                      description.contains(q) ||
                      category.contains(q);
                }).toList();

          final activeCount = services.where((s) => s.isActive).length;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(activeCount: activeCount),
                const SizedBox(height: 20),
                _FilterTabs(
                  filter: _filter,
                  total: services.length,
                  active: activeCount,
                  inactive: services.length - activeCount,
                  onChange: (f) => setState(() => _filter = f),
                ),
                const SizedBox(height: 24),
                _ServicesGrid(
                  services: filtered,
                  providerId: user.id,
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.activeCount});
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Services',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  )),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('$activeCount active',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => context.go(RouteNames.addService),
          icon: const Icon(Icons.add, size: 16),
          label: Text('Add New Service',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

// ── Filter Tabs ───────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.filter,
    required this.total,
    required this.active,
    required this.inactive,
    required this.onChange,
  });
  final String filter;
  final int total;
  final int active;
  final int inactive;
  final void Function(String) onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          _tab('All', total, 'all'),
          const SizedBox(width: 20),
          _tab('Active', active, 'active'),
          const SizedBox(width: 20),
          _tab('Inactive', inactive, 'inactive'),
        ],
      ),
    );
  }

  Widget _tab(String label, int count, String key) {
    final selected = filter == key;
    return GestureDetector(
      onTap: () => onChange(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.grey500,
                )),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text('($count)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.grey400,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Services Grid ─────────────────────────────────────────────────────────────

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({
    required this.services,
    required this.providerId,
  });
  final List<ServiceModel> services;
  final String providerId;

  @override
  Widget build(BuildContext context) {
    final totalItems = services.length + 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisExtent: 410,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: totalItems,
      itemBuilder: (_, i) {
        if (i == services.length) {
          return _GrowBusinessCard();
        }
        return _ServiceCard(
          service: services[i],
          providerId: providerId,
        );
      },
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard({
    required this.service,
    required this.providerId,
  });
  final ServiceModel service;
  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                service.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: service.imageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.grey100,
                          child: const Icon(
                            Icons.home_repair_service_outlined,
                            size: 40,
                            color: AppColors.grey300,
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.grey100,
                          child: const Icon(
                            Icons.home_repair_service_outlined,
                            size: 40,
                            color: AppColors.grey300,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.grey100,
                        child: const Icon(
                          Icons.home_repair_service_outlined,
                          size: 40,
                          color: AppColors.grey300,
                        ),
                      ),
                if (!service.isActive)
                  Container(color: Colors.black.withValues(alpha: 0.5)),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: service.isActive
                          ? AppColors.primary
                          : AppColors.grey500,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      service.isActive ? 'ACTIVE' : 'INACTIVE',
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
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDBA74).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _categoryLabel(service.category),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC2410C),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: Text(service.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: service.isActive
                            ? AppColors.secondary
                            : AppColors.grey500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 10),
                Text('STARTING FROM',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey500,
                      letterSpacing: 0.8,
                    )),
                const SizedBox(height: 2),
                Text('PKR ${service.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: service.isActive
                          ? AppColors.secondary
                          : AppColors.grey500,
                    )),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            context.go(RouteNames.editServicePath(service.id)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.grey100,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(service.isActive ? 'Edit' : 'Activate',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                            width: 34, height: 34),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () => _toggleActive(context, ref),
                        icon: Container(
                          decoration: BoxDecoration(
                            color: service.isActive
                                ? const Color(0xFFFEE2E2)
                                : AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            service.isActive
                                ? Icons.block
                                : Icons.check_circle_outline,
                            size: 16,
                            color: service.isActive
                                ? AppColors.error
                                : AppColors.primary,
                          ),
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
    );
  }

  void _toggleActive(BuildContext context, WidgetRef ref) {
    if (service.isActive) {
      ref.read(serviceActionProvider.notifier).deactivateService(
            serviceId: service.id,
            providerId: providerId,
          );
    } else {
      context.go(RouteNames.editServicePath(service.id));
    }
  }

  String _categoryLabel(Object category) {
    final name = category.toString().split('.').last;
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class _GrowBusinessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(RouteNames.addService),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text('Grow your business',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                )),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Expand your portfolio by adding a new expert service today.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.grey500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
