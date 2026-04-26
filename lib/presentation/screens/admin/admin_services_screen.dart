// ---------------------------------------------------------------------------
// admin_services_screen.dart
//
// Purpose: Admin service moderation table. Search, filter by category and
// status, view service detail, and toggle active/inactive.
//
// Route: /admin/services (inside AdminShell)
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/service_model.dart';
import '../../../data/repositories/service_repository.dart';
import '../../providers/service_provider.dart';

const _kPrimary = Color(0xFF2D9B6F);
const _kBg = Color(0xFFF5F7FA);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);
const _kField = Color(0xFFEFF4F9);
const _kGreenFg = Color(0xFF065F46);
const _kRedBg = Color(0xFFFEE2E2);
const _kRedFg = Color(0xFF991B1B);
const _kSlateFg = Color(0xFF334155);
const _kAmberFg = Color(0xFFD97706);

enum _StatusFilter { all, active, inactive, draft }

final allServicesAdminProvider =
    FutureProvider<List<ServiceModel>>((ref) async {
  return ServiceRepository.instance.searchServices(pageSize: 500);
});

class AdminServicesScreen extends ConsumerStatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  ConsumerState<AdminServicesScreen> createState() =>
      _AdminServicesScreenState();
}

class _AdminServicesScreenState extends ConsumerState<AdminServicesScreen> {
  String _search = '';
  _StatusFilter _status = _StatusFilter.all;
  ServiceCategory? _category;

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(allServicesAdminProvider);

    return Container(
      color: _kBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageHeader(),
            const SizedBox(height: 24),
            _ControlsRow(
              search: _search,
              status: _status,
              category: _category,
              onSearchChanged: (value) => setState(() => _search = value),
              onStatusChanged: (value) => setState(() => _status = value),
              onCategoryChanged: (value) => setState(() => _category = value),
              count: servicesAsync.maybeWhen(
                data: (services) => _applyFilters(services).length,
                orElse: () => null,
              ),
            ),
            const SizedBox(height: 20),
            servicesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child:
                    Center(child: CircularProgressIndicator(color: _kPrimary)),
              ),
              error: (error, _) => _ErrorBlock(message: error.toString()),
              data: (services) {
                final filtered = _applyFilters(services);
                if (filtered.isEmpty) {
                  return const _EmptyBlock();
                }
                return _ServicesTable(services: filtered);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<ServiceModel> _applyFilters(List<ServiceModel> services) {
    var list = services;
    switch (_status) {
      case _StatusFilter.active:
        list = list
            .where((service) => service.isActive && !service.isDraft)
            .toList();
        break;
      case _StatusFilter.inactive:
        list = list
            .where((service) => !service.isActive && !service.isDraft)
            .toList();
        break;
      case _StatusFilter.draft:
        list = list.where((service) => service.isDraft).toList();
        break;
      case _StatusFilter.all:
        break;
    }

    if (_category != null) {
      list = list.where((service) => service.category == _category).toList();
    }

    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();
      list = list
          .where((service) => service.title.toLowerCase().contains(query))
          .toList();
    }

    return list;
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _kInk,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Moderate platform listings and ensure quality across categories',
          style: GoogleFonts.inter(fontSize: 13.5, color: _kMuted),
        ),
      ],
    );
  }
}

class _ControlsRow extends StatelessWidget {
  const _ControlsRow({
    required this.search,
    required this.status,
    required this.category,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onCategoryChanged,
    required this.count,
  });

  final String search;
  final _StatusFilter status;
  final ServiceCategory? category;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_StatusFilter> onStatusChanged;
  final ValueChanged<ServiceCategory?> onCategoryChanged;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 1000;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchField(value: search, onChanged: onSearchChanged),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _StatusTabs(current: status, onChanged: onStatusChanged),
              _CategoryDropdown(value: category, onChanged: onCategoryChanged),
              if (count != null) _CountPill(count: count!),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 260,
          child: _SearchField(value: search, onChanged: onSearchChanged),
        ),
        const SizedBox(width: 14),
        _StatusTabs(current: status, onChanged: onStatusChanged),
        const SizedBox(width: 14),
        _CategoryDropdown(value: category, onChanged: onCategoryChanged),
        const Spacer(),
        if (count != null) _CountPill(count: count!),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 13.5, color: _kInk),
      decoration: InputDecoration(
        hintText: 'Search services...',
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
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({required this.current, required this.onChanged});

  final _StatusFilter current;
  final ValueChanged<_StatusFilter> onChanged;

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
        children: _StatusFilter.values.map((status) {
          final active = status == current;
          final label = switch (status) {
            _StatusFilter.all => 'All',
            _StatusFilter.active => 'Active',
            _StatusFilter.inactive => 'Inactive',
            _StatusFilter.draft => 'Draft',
          };

          return Padding(
            padding: const EdgeInsets.only(right: 2),
            child: InkWell(
              onTap: () => onChanged(status),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? _kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : _kMuted,
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

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});

  final ServiceCategory? value;
  final ValueChanged<ServiceCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _kField,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ServiceCategory?>(
          value: value,
          hint: Text(
            'All Categories',
            style: GoogleFonts.inter(fontSize: 13, color: _kMuted),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _kMuted),
          style: GoogleFonts.inter(fontSize: 13, color: _kInk),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
          items: [
            DropdownMenuItem<ServiceCategory?>(
              value: null,
              child: Text(
                'All Categories',
                style: GoogleFonts.inter(fontSize: 13, color: _kMuted),
              ),
            ),
            ...ServiceCategory.values.map((category) {
              final label = category.value
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map((word) => word[0].toUpperCase() + word.substring(1))
                  .join(' ');
              return DropdownMenuItem(value: category, child: Text(label));
            }),
          ],
          onChanged: onChanged,
        ),
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
        '$count services',
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _kMuted,
        ),
      ),
    );
  }
}

class _ServicesTable extends ConsumerWidget {
  const _ServicesTable({required this.services});

  final List<ServiceModel> services;

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
          const _THeader(),
          for (var index = 0; index < services.length; index++) ...[
            _TRow(service: services[index]),
            if (index < services.length - 1)
              const Divider(
                  height: 1, color: _kBorder, indent: 20, endIndent: 20),
          ],
        ],
      ),
    );
  }
}

class _THeader extends StatelessWidget {
  const _THeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: const Row(
        children: [
          Expanded(flex: 4, child: _Col('SERVICE')),
          Expanded(flex: 3, child: _Col('PROVIDER')),
          Expanded(flex: 2, child: _Col('CATEGORY', center: true)),
          Expanded(flex: 2, child: _Col('PRICE', center: true)),
          Expanded(flex: 2, child: _Col('STATUS', center: true)),
          Expanded(flex: 2, child: _Col('ACTIONS', center: true)),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col(this.label, {this.center = false});

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

class _TRow extends ConsumerStatefulWidget {
  const _TRow({required this.service});

  final ServiceModel service;

  @override
  ConsumerState<_TRow> createState() => _TRowState();
}

class _TRowState extends ConsumerState<_TRow> {
  bool _hover = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        color: _hover ? _kBg : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${service.bookingCount} Bookings',
                    style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _ProvAvatar(
                      name: service.providerName,
                      url: service.providerAvatarUrl),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      service.providerName ?? 'Provider',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kInk,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(child: _CatBadge(category: service.category)),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  children: [
                    if (service.priceType == PriceType.startingFrom)
                      Text(
                        'Starting from',
                        style: GoogleFonts.inter(fontSize: 10, color: _kMuted),
                      ),
                    Text(
                      'PKR ${NumberFormat('#,###').format(service.price)}',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(child: _ServiceStatus(service: service)),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActBtn(
                    icon: Icons.visibility_outlined,
                    tooltip: 'View service',
                    onTap: () => context.go('/admin/service/${service.id}'),
                  ),
                  const SizedBox(width: 6),
                  _ActBtn(
                    icon: service.isActive
                        ? Icons.toggle_on_outlined
                        : Icons.toggle_off_outlined,
                    tooltip: service.isActive ? 'Deactivate' : 'Activate',
                    color: service.isActive ? _kGreenFg : _kRedFg,
                    onTap: _busy ? null : () => _toggleActive(service),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(ServiceModel service) async {
    final action = service.isActive ? 'deactivate' : 'activate';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          '${action[0].toUpperCase()}${action.substring(1)} "${service.title}"?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          service.isActive
              ? 'This service will be hidden from customers.'
              : 'This service will become visible to customers.',
          style: GoogleFonts.inter(fontSize: 14, color: _kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: _kMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: service.isActive ? _kRedFg : _kPrimary,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              service.isActive ? 'Deactivate' : 'Activate',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() => _busy = true);

    await ref.read(serviceActionProvider.notifier).updateService(
          serviceId: service.id,
          providerId: service.providerId,
          isActive: !service.isActive,
        );

    ref.invalidate(allServicesAdminProvider);

    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Service ${service.isActive ? 'deactivated' : 'activated'}'),
          backgroundColor: _kPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ProvAvatar extends StatelessWidget {
  const _ProvAvatar({this.name, this.url});

  final String? name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final initial = (name?.isNotEmpty ?? false) ? name![0].toUpperCase() : '?';

    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: _kBorder,
        backgroundImage: NetworkImage(url!),
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: _kPrimary.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: _kPrimary,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _CatBadge extends StatelessWidget {
  const _CatBadge({required this.category});

  final ServiceCategory category;

  @override
  Widget build(BuildContext context) {
    final label = category.value
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kField,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _kSlateFg,
          letterSpacing: 0.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ServiceStatus extends StatelessWidget {
  const _ServiceStatus({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    final (color, label) = service.isDraft
        ? (_kAmberFg, 'Draft')
        : service.isActive
            ? (_kGreenFg, 'Active')
            : (_kRedFg, 'Inactive');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActBtn extends StatelessWidget {
  const _ActBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color ?? _kMuted),
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock();

  @override
  Widget build(BuildContext context) {
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
            child:
                const Icon(Icons.handyman_outlined, color: _kMuted, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            'No services found',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.inter(fontSize: 12.5, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Could not load services',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kRedFg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: _kRedFg),
          ),
        ],
      ),
    );
  }
}
