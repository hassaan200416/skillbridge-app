// ---------------------------------------------------------------------------
// admin_service_detail_screen.dart
//
// Purpose: Read-only service detail view for admin. Stays inside AdminShell
//   so admin never leaves the admin interface. Shows service info, provider
//   info, and an activate/deactivate toggle.
//
// Route: /admin/service/:id  (inside AdminShell)
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/service_model.dart';
import '../../providers/service_provider.dart';
import 'admin_services_screen.dart' show allServicesAdminProvider;

const _kPrimary = Color(0xFF2D9B6F);
const _kBg = Color(0xFFF5F7FA);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);
const _kField = Color(0xFFEFF4F9);
const _kGreenBg = Color(0xFFD1FAE5);
const _kGreenFg = Color(0xFF065F46);
const _kRedBg = Color(0xFFFEE2E2);
const _kRedFg = Color(0xFF991B1B);
const _kAmberFg = Color(0xFFD97706);

class AdminServiceDetailScreen extends ConsumerStatefulWidget {
  const AdminServiceDetailScreen({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<AdminServiceDetailScreen> createState() =>
      _AdminServiceDetailScreenState();
}

class _AdminServiceDetailScreenState
    extends ConsumerState<AdminServiceDetailScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceId));

    return Container(
      color: _kBg,
      child: serviceAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kPrimary)),
        error: (e, _) => Center(
          child: Text('Error: $e', style: GoogleFonts.inter(color: _kRedFg)),
        ),
        data: (service) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/admin/services'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBorder),
                      ),
                      child:
                          const Icon(Icons.arrow_back, size: 18, color: _kInk),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Detail',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _kInk,
                          ),
                        ),
                        Text(
                          'Admin view — read only',
                          style:
                              GoogleFonts.inter(fontSize: 13, color: _kMuted),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(service: service),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (ctx, cons) {
                  final twoCol = cons.maxWidth >= 800;
                  final left = _InfoCard(service: service);
                  final right = _ActionsCard(
                    service: service,
                    busy: _busy,
                    onToggle: () => _toggleActive(service),
                  );
                  if (twoCol) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: left),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: right),
                      ],
                    );
                  }
                  return Column(
                    children: [left, const SizedBox(height: 20), right],
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleActive(ServiceModel s) async {
    final action = s.isActive ? 'deactivate' : 'activate';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          '${action[0].toUpperCase()}${action.substring(1)} "${s.title}"?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          s.isActive
              ? 'This service will be hidden from customers.'
              : 'This service will become visible to customers.',
          style: GoogleFonts.inter(fontSize: 14, color: _kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: _kMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: s.isActive ? _kRedFg : _kPrimary,
            ),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(
              action[0].toUpperCase() + action.substring(1),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    await ref.read(serviceActionProvider.notifier).updateService(
          serviceId: s.id,
          providerId: s.providerId,
          isActive: !s.isActive,
        );
    ref.invalidate(allServicesAdminProvider);
    ref.invalidate(serviceDetailProvider(widget.serviceId));
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service ${s.isActive ? 'deactivated' : 'activated'}'),
          backgroundColor: _kPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.service});
  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = service.isDraft
        ? (const Color(0xFFFEF3C7), _kAmberFg, 'DRAFT')
        : service.isActive
            ? (_kGreenBg, _kGreenFg, 'ACTIVE')
            : (_kRedBg, _kRedFg, 'INACTIVE');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.service});
  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    final catLabel = service.category.value
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (service.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 6,
                child: Image.network(
                  service.imageUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _kField,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: _kMuted, size: 40),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 140,
              decoration: BoxDecoration(
                  color: _kField, borderRadius: BorderRadius.circular(12)),
              child: const Center(
                  child:
                      Icon(Icons.handyman_outlined, color: _kMuted, size: 40)),
            ),
          const SizedBox(height: 20),
          Text(
            service.title,
            style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w700, color: _kInk),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _Chip(catLabel),
              if (service.providerIsVerified == true)
                _Chip('Verified Provider', color: _kGreenFg, bg: _kGreenBg),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            service.description,
            style: GoogleFonts.inter(fontSize: 14, color: _kInk, height: 1.6),
          ),
          const SizedBox(height: 20),
          const Divider(color: _kBorder),
          const SizedBox(height: 14),
          _DetailRow('Provider', service.providerName ?? 'Unknown'),
          _DetailRow('Category', catLabel),
          _DetailRow(
            'Price',
            '${service.priceType == PriceType.startingFrom ? 'Starting from ' : ''}PKR ${NumberFormat('#,###').format(service.price)}',
          ),
          _DetailRow('Bookings', '${service.bookingCount}'),
          _DetailRow(
            'Rating',
            service.reviewCount > 0
                ? '${service.avgRating.toStringAsFixed(1)} (${service.reviewCount} reviews)'
                : 'No reviews yet',
          ),
          _DetailRow(
            'Available',
            service.availableDays
                .map((d) => d[0].toUpperCase() + d.substring(1, 3))
                .join(', '),
          ),
          _DetailRow(
              'Created', DateFormat('dd MMM yyyy').format(service.createdAt)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.color, this.bg});
  final String label;
  final Color? color;
  final Color? bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg ?? _kField, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color ?? const Color(0xFF334155),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500, color: _kMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _kInk),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard(
      {required this.service, required this.busy, required this.onToggle});
  final ServiceModel service;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: const Color(0xFF1A2B3C),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Moderation',
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            service.isActive
                ? 'This service is currently visible to customers. You can deactivate it if it violates platform guidelines.'
                : 'This service is hidden from customers. Activate it to make it visible again.',
            style: GoogleFonts.inter(
                fontSize: 13, color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: service.isActive ? _kRedFg : _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: busy ? null : onToggle,
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            service.isActive ? Icons.block : Icons.check_circle,
                            size: 18,
                            color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          service.isActive
                              ? 'Deactivate Service'
                              : 'Activate Service',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.go('/admin/user/${service.providerId}'),
              child: Text(
                'View Provider Profile',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
