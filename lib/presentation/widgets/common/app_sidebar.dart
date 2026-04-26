// ---------------------------------------------------------------------------
// app_sidebar.dart
//
// Purpose: Unified sidebar for all 3 roles. Supports expand/collapse.
// Collapsed = 64px icon rail. Expanded = 240px with labels.
// Logo + hamburger in sidebar header. Logout at bottom.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

const _kExpandedWidth = 240.0;
const _kCollapsedWidth = 80.0;
const _kPrimary = Color(0xFF2D9B6F);
const _kSecondary = Color(0xFF1A2B3C);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kActiveBg = Color(0xFFECFDF5);
const _kHover = Color(0xFFF1F5F9);
const _kDuration = Duration(milliseconds: 200);

final sidebarExpandedProvider = StateProvider<bool>((ref) => true);

class AppSidebar extends ConsumerWidget {
  const AppSidebar({
    super.key,
    required this.role,
    required this.currentRoute,
  });

  final UserRole role;
  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(sidebarExpandedProvider);
    final width = expanded ? _kExpandedWidth : _kCollapsedWidth;

    return AnimatedContainer(
      duration: _kDuration,
      width: width,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: _kBorder)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // -- Header: logo + hamburger --
          SizedBox(
            height: 59,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // During width animation, keep compact header until there is
                // enough room to render the full expanded row safely.
                final canShowExpanded = expanded && constraints.maxWidth >= 180;
                return canShowExpanded
                    ? _expandedHeader(ref)
                    : _collapsedHeader(ref);
              },
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorder),

          // -- Nav items --
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 12 : 8,
                vertical: 8,
              ),
              children: _navItems.map((item) {
                final isActive = _isRouteActive(item.route, currentRoute);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _NavTile(
                    icon: item.icon,
                    label: item.label,
                    isActive: isActive,
                    expanded: expanded,
                    onTap: () => context.go(item.route),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1, thickness: 1, color: _kBorder),

          // -- Logout --
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 12 : 8,
              vertical: 12,
            ),
            child: _NavTile(
              icon: Icons.logout,
              label: 'Sign out',
              isActive: false,
              expanded: expanded,
              isLogout: true,
              onTap: () => _confirmLogout(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  // -- Expanded header: logo | text --
  Widget _expandedHeader(WidgetRef ref) {
    final subtitle = switch (role) {
      UserRole.customer => 'Marketplace',
      UserRole.provider => 'Provider Portal',
      UserRole.admin => 'Admin Console',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _logoIcon(32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SkillBridge',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: _kMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Collapsed header: logo only --
  Widget _collapsedHeader(WidgetRef ref) {
    return Center(child: _logoIcon(34));
  }

  Widget _logoIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(
        Icons.handshake_outlined,
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign out',
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: _kMuted, fontWeight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: Text('Sign out',
                style: GoogleFonts.inter(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  bool _isRouteActive(String route, String current) {
    // Exact match first
    if (route == current) return true;
    // Home/dashboard routes — exact match only (prevent /admin
    // from matching /admin/users, /admin/activity, etc.)
    if (route == RouteNames.adminDashboard) return current == '/admin';
    if (route == RouteNames.customerHome) return current == '/home';
    if (route == RouteNames.providerHome) return current == '/provider-home';
    // For other routes, prefix match (e.g., /admin/users matches
    // /admin/users and /admin/users/xxx)
    if (route.length > 1 && current.startsWith(route)) return true;
    return false;
  }

  List<_NavItemData> get _navItems {
    switch (role) {
      case UserRole.customer:
        return [
          _NavItemData(
              Icons.dashboard_outlined, 'Dashboard', RouteNames.customerHome),
          _NavItemData(Icons.search_outlined, 'Search', RouteNames.search),
          _NavItemData(Icons.calendar_today_outlined, 'My Bookings',
              RouteNames.myBookings),
          _NavItemData(Icons.favorite_outline, 'Wishlist', RouteNames.wishlist),
          _NavItemData(Icons.chat_bubble_outline, 'Chats', '/chats'),
          _NavItemData(
              Icons.campaign_outlined, 'Announcements', '/announcements'),
          _NavItemData(Icons.notifications_outlined, 'Notifications',
              RouteNames.customerNotifications),
        ];
      case UserRole.provider:
        return [
          _NavItemData(
              Icons.dashboard_outlined, 'Dashboard', RouteNames.providerHome),
          _NavItemData(
              Icons.handyman_outlined, 'My Services', RouteNames.myServices),
          _NavItemData(Icons.event_available_outlined, 'Bookings',
              RouteNames.incomingBookings),
          _NavItemData(Icons.trending_up_outlined, 'Analytics',
              RouteNames.providerAnalytics),
          _NavItemData(
              Icons.star_outline, 'Reviews', RouteNames.providerReviews),
          _NavItemData(Icons.chat_bubble_outline, 'Chats', '/p/chats'),
          _NavItemData(
              Icons.campaign_outlined, 'Announcements', '/p/announcements'),
          _NavItemData(Icons.notifications_outlined, 'Notifications',
              RouteNames.providerNotifications),
        ];
      case UserRole.admin:
        return [
          _NavItemData(
              Icons.dashboard_outlined, 'Dashboard', RouteNames.adminDashboard),
          _NavItemData(Icons.people_outline, 'Users', RouteNames.adminUsers),
          _NavItemData(
              Icons.handyman_outlined, 'Services', RouteNames.adminServices),
          _NavItemData(Icons.event_available_outlined, 'Bookings',
              RouteNames.adminBookings),
          _NavItemData(
              Icons.reviews_outlined, 'Reviews', RouteNames.adminReviews),
          _NavItemData(
              Icons.bar_chart_outlined, 'Analytics', RouteNames.adminActivity),
          _NavItemData(Icons.notifications_outlined, 'Notifications',
              '/admin/notifications'),
          _NavItemData(
              Icons.settings_outlined, 'Settings', RouteNames.adminSettings),
        ];
    }
  }
}

class _NavItemData {
  const _NavItemData(this.icon, this.label, this.route);
  final IconData icon;
  final String label;
  final String route;
}

// -- Unified nav tile: handles both expanded and collapsed, plus logout style --
class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.expanded,
    required this.onTap,
    this.isLogout = false,
  });
  final IconData icon;
  final String label;
  final bool isActive;
  final bool expanded;
  final VoidCallback onTap;
  final bool isLogout;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;

    if (widget.isLogout) {
      fg = const Color(0xFF991B1B);
      bg = _hovering ? const Color(0xFFFEE2E2) : Colors.transparent;
    } else if (widget.isActive) {
      fg = _kPrimary;
      bg = _kActiveBg;
    } else {
      fg = _kSecondary;
      bg = _hovering ? _kHover : Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: _kDuration,
          padding: EdgeInsets.symmetric(
            horizontal: widget.expanded ? 12 : 0,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: widget.isActive && !widget.isLogout
                ? Border.all(color: _kPrimary.withValues(alpha: 0.2))
                : null,
          ),
          child: widget.expanded
              ? Row(
                  children: [
                    Icon(widget.icon, size: 20, color: fg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: widget.isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: fg,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Tooltip(
                    message: widget.label,
                    child: Icon(widget.icon, size: 22, color: fg),
                  ),
                ),
        ),
      ),
    );
  }
}
