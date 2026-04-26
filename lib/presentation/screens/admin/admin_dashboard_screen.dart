// ---------------------------------------------------------------------------
// admin_dashboard_screen.dart
//
// Purpose: Admin landing screen. Platform health at-a-glance with live
//   counts from existing providers (allUsersProvider, getAllBookingsProvider,
//   allServicesAdminProvider). Launchpad to every other admin section.
//
// Route: /admin
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/booking_model.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/user_provider.dart';
import 'admin_services_screen.dart' show allServicesAdminProvider;

// ── Design Tokens ───────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF2D9B6F);
const _kBg = Color(0xFFF5F7FA);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);

// Metric accents
const _kBlueBg = Color(0xFFDBEAFE);
const _kBlueFg = Color(0xFF1E40AF);
const _kGreenBg = Color(0xFFD1FAE5);
const _kGreenFg = Color(0xFF065F46);
const _kNavyBg = Color(0xFFE2E8F0);
const _kNavyFg = Color(0xFF334155);
const _kRedBg = Color(0xFFFEE2E2);
const _kRedFg = Color(0xFF991B1B);
const _kAmberFg = Color(0xFFD97706);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final bookingsAsync = ref.watch(getAllBookingsProvider);
    final servicesAsync = ref.watch(allServicesAdminProvider);

    return Container(
      color: _kBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopBar(),
            const SizedBox(height: 24),
            _WelcomeRow(adminName: currentUser?.name.split(' ').first ?? 'Admin'),
            const SizedBox(height: 24),
            _MetricsRow(
              usersAsync: usersAsync,
              bookingsAsync: bookingsAsync,
            ),
            const SizedBox(height: 20),
            _BodyGrid(
              usersAsync: usersAsync,
              bookingsAsync: bookingsAsync,
              servicesAsync: servicesAsync,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Platform health and activity at a glance',
                style: GoogleFonts.inter(fontSize: 13.5, color: _kMuted),
              ),
            ],
          ),
        ),
        _IconBtn(
          icon: Icons.notifications_none,
          onTap: () => context.go('/notifications'),
        ),
        const SizedBox(width: 10),
        _IconBtn(
          icon: Icons.help_outline,
          onTap: () {},
        ),
        const SizedBox(width: 14),
        _TopAvatar(name: user?.name, url: user?.avatarUrl),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, size: 18, color: _kMuted),
      ),
    );
  }
}

class _TopAvatar extends StatelessWidget {
  const _TopAvatar({this.name, this.url});
  final String? name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final initial = (name?.isNotEmpty ?? false) ? name![0].toUpperCase() : 'A';
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: _kBorder,
        backgroundImage: NetworkImage(url!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: _kPrimary.withValues(alpha: 0.14),
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: _kPrimary,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _WelcomeRow extends StatelessWidget {
  const _WelcomeRow({required this.adminName});
  final String adminName;

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final part = h < 12 ? 'Morning' : (h < 17 ? 'Afternoon' : 'Evening');
    final date = DateFormat('EEE, d MMM').format(DateTime.now());

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good $part, $adminName',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's what's happening on SkillBridge today.",
                style: GoogleFonts.inter(fontSize: 13.5, color: _kMuted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: _kPrimary),
              const SizedBox(width: 6),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.usersAsync, required this.bookingsAsync});
  final AsyncValue<List<UserModel>> usersAsync;
  final AsyncValue<List<BookingModel>> bookingsAsync;

  @override
  Widget build(BuildContext context) {
    final totalUsers = usersAsync.maybeWhen(data: (u) => u.length, orElse: () => null);
    final activeProviders = usersAsync.maybeWhen(
      data: (u) => u.where((x) => x.role == UserRole.provider && !x.isSuspended).length,
      orElse: () => null,
    );
    final totalBookings = bookingsAsync.maybeWhen(data: (b) => b.length, orElse: () => null);
    final suspended = usersAsync.maybeWhen(
      data: (u) => u.where((x) => x.isSuspended).length,
      orElse: () => null,
    );

    final w = MediaQuery.sizeOf(context).width;
    final twoPerRow = w < 1100;

    final cards = [
      _MetricCard(
        icon: Icons.people_outline,
        iconBg: _kBlueBg,
        iconFg: _kBlueFg,
        label: 'TOTAL USERS',
        value: totalUsers,
      ),
      _MetricCard(
        icon: Icons.handyman_outlined,
        iconBg: _kGreenBg,
        iconFg: _kGreenFg,
        label: 'ACTIVE PROVIDERS',
        value: activeProviders,
      ),
      _MetricCard(
        icon: Icons.event_available_outlined,
        iconBg: _kNavyBg,
        iconFg: _kNavyFg,
        label: 'TOTAL BOOKINGS',
        value: totalBookings,
      ),
      _MetricCard(
        icon: Icons.block_outlined,
        iconBg: _kRedBg,
        iconFg: _kRedFg,
        label: 'SUSPENDED',
        value: suspended,
      ),
    ];

    if (!twoPerRow) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            Expanded(child: cards[i]),
          ],
        ],
      );
    }
    return Column(
      children: [
        Row(children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 14),
          Expanded(child: cards[1]),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: cards[2]),
          const SizedBox(width: 14),
          Expanded(child: cards[3]),
        ]),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconFg, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            value == null ? '—' : NumberFormat.decimalPattern().format(value),
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kMuted,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyGrid extends StatelessWidget {
  const _BodyGrid({
    required this.usersAsync,
    required this.bookingsAsync,
    required this.servicesAsync,
  });
  final AsyncValue<List<UserModel>> usersAsync;
  final AsyncValue<List<BookingModel>> bookingsAsync;
  final AsyncValue<List<dynamic>> servicesAsync;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final twoColumn = w >= 1100;

    final left = const _QuickActionsCard();
    final right = _AtAGlanceCard(
      usersAsync: usersAsync,
      bookingsAsync: bookingsAsync,
      servicesAsync: servicesAsync,
    );

    if (twoColumn) {
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [left, const SizedBox(height: 20), right],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick actions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 16),
          _actionsGrid(context),
        ],
      ),
    );
  }

  Widget _actionsGrid(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w < 700 ? 1 : 2;

    final tiles = [
      _ActionTile(
        icon: Icons.manage_accounts_outlined,
        iconFg: _kBlueFg,
        iconBg: _kBlueBg,
        title: 'Manage Users',
        subtitle: 'View, verify, suspend accounts',
        onTap: () => context.go('/admin/users'),
      ),
      _ActionTile(
        icon: Icons.fact_check_outlined,
        iconFg: _kGreenFg,
        iconBg: _kGreenBg,
        title: 'Review Services',
        subtitle: 'Moderate listings',
        onTap: () => context.go('/admin/services'),
      ),
      _ActionTile(
        icon: Icons.list_alt_outlined,
        iconFg: _kNavyFg,
        iconBg: _kNavyBg,
        title: 'All Bookings',
        subtitle: 'Platform-wide booking log',
        onTap: () => context.go('/admin/bookings'),
      ),
      _ActionTile(
        icon: Icons.flag_outlined,
        iconFg: _kRedFg,
        iconBg: _kRedBg,
        title: 'Flagged Reviews',
        subtitle: 'Handle reported content',
        onTap: () => context.go('/admin/reviews'),
      ),
      _ActionTile(
        icon: Icons.history_outlined,
        iconFg: _kAmberFg,
        iconBg: const Color(0xFFFEF3C7),
        title: 'Activity Log',
        subtitle: 'Recent admin actions',
        onTap: () => context.go('/admin/activity'),
      ),
      _ActionTile(
        icon: Icons.tune_outlined,
        iconFg: _kNavyFg,
        iconBg: _kNavyBg,
        title: 'Platform Settings',
        subtitle: 'Announcements and config',
        onTap: () => context.go('/admin/settings'),
      ),
    ];

    return LayoutBuilder(
      builder: (ctx, cons) {
        final rows = <Widget>[];
        for (int i = 0; i < tiles.length; i += cols) {
          if (i > 0) rows.add(const SizedBox(height: 12));
          final rowChildren = <Widget>[];
          for (int c = 0; c < cols; c++) {
            final idx = i + c;
            if (c > 0) rowChildren.add(const SizedBox(width: 12));
            if (idx < tiles.length) {
              rowChildren.add(Expanded(child: tiles[idx]));
            } else {
              rowChildren.add(const Expanded(child: SizedBox()));
            }
          }
          rows.add(Row(children: rowChildren));
        }
        return Column(children: rows);
      },
    );
  }
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.icon,
    required this.iconFg,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconFg;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hover ? Colors.white : _kBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hover ? _kPrimary.withValues(alpha: 0.4) : _kBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.iconFg, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _kMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 13, color: _kMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AtAGlanceCard extends StatelessWidget {
  const _AtAGlanceCard({
    required this.usersAsync,
    required this.bookingsAsync,
    required this.servicesAsync,
  });
  final AsyncValue<List<UserModel>> usersAsync;
  final AsyncValue<List<BookingModel>> bookingsAsync;
  final AsyncValue<List<dynamic>> servicesAsync;

  @override
  Widget build(BuildContext context) {
    final rows = <_GlanceRow>[
      _GlanceRow(
        label: 'Customers',
        value: usersAsync.maybeWhen(
          data: (u) => u.where((x) => x.role == UserRole.customer).length,
          orElse: () => null,
        ),
      ),
      _GlanceRow(
        label: 'Providers',
        value: usersAsync.maybeWhen(
          data: (u) => u.where((x) => x.role == UserRole.provider).length,
          orElse: () => null,
        ),
      ),
      _GlanceRow(
        label: 'Admins',
        value: usersAsync.maybeWhen(
          data: (u) => u.where((x) => x.role == UserRole.admin).length,
          orElse: () => null,
        ),
      ),
      _GlanceRow(
        label: 'Active services',
        value: servicesAsync.maybeWhen(
          data: (s) => s.where((x) {
            try {
              return (x as dynamic).isActive == true && (x).isDraft == false;
            } catch (_) {
              return false;
            }
          }).length,
          orElse: () => null,
        ),
      ),
      _GlanceRow(
        label: 'Inactive services',
        value: servicesAsync.maybeWhen(
          data: (s) => s.where((x) {
            try {
              return (x as dynamic).isActive == false;
            } catch (_) {
              return false;
            }
          }).length,
          orElse: () => null,
        ),
      ),
      _GlanceRow(
        label: 'Pending bookings',
        value: bookingsAsync.maybeWhen(
          data: (b) => b.where((x) => x.status == BookingStatus.pending).length,
          orElse: () => null,
        ),
        warnIfNonZero: true,
      ),
      _GlanceRow(
        label: 'Confirmed bookings',
        value: bookingsAsync.maybeWhen(
          data: (b) => b.where((x) => x.status == BookingStatus.confirmed).length,
          orElse: () => null,
        ),
      ),
      _GlanceRow(
        label: 'Completed bookings',
        value: bookingsAsync.maybeWhen(
          data: (b) => b.where((x) => x.status == BookingStatus.completed).length,
          orElse: () => null,
        ),
      ),
      _GlanceRow(
        label: 'Cancelled bookings',
        value: bookingsAsync.maybeWhen(
          data: (b) => b.where((x) => x.status == BookingStatus.cancelled).length,
          orElse: () => null,
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'At a glance',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(height: 1, color: _kBorder),
          ],
        ],
      ),
    );
  }
}

class _GlanceRow extends StatelessWidget {
  const _GlanceRow({
    required this.label,
    required this.value,
    this.warnIfNonZero = false,
  });
  final String label;
  final int? value;
  final bool warnIfNonZero;

  @override
  Widget build(BuildContext context) {
    final showWarn = warnIfNonZero && (value ?? 0) > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (showWarn) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _kAmberFg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kMuted,
              ),
            ),
          ),
          Text(
            value == null ? '—' : NumberFormat.decimalPattern().format(value),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kInk,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
