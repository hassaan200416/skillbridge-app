// ---------------------------------------------------------------------------
// app_top_bar.dart
//
// Purpose: Shared top bar widget for all 3 roles. Provides:
//   - Hamburger to toggle sidebar
//   - Role-aware search bar (customer: functional, provider: decorative)
//   - Notification bell with red dot badge + popover (3-4 latest, View All)
//   - Profile avatar with dropdown (email, Profile, Sign Out)
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import 'app_sidebar.dart';

// ── Design tokens ───────────────────────────────────────────────────────
const _kPrimary = Color(0xFF2D9B6F);
const _kSecondary = Color(0xFF1A2B3C);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);
const _kBg = Color(0xFFF5F7FA);

class AppTopBar extends ConsumerWidget {
  const AppTopBar({super.key, this.title});
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final expanded = ref.watch(sidebarExpandedProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          // ── Hamburger (toggles sidebar) ──
          InkWell(
            onTap: () =>
                ref.read(sidebarExpandedProvider.notifier).state = !expanded,
            borderRadius: BorderRadius.circular(8),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.menu, size: 20, color: _kSecondary),
            ),
          ),

          const SizedBox(width: 16),

          // ── Search bar (role-aware) ──
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: switch (user?.role) {
                UserRole.customer => ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _CustomerHeaderSearch(),
                  ),
                UserRole.provider => ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _ProviderHeaderSearch(),
                  ),
                _ => const SizedBox.shrink(),
              },
            ),
          ),

          // ── Notification bell ──
          if (user != null) _NotificationBell(userId: user.id, role: user.role),

          const SizedBox(width: 8),

          // ── Profile avatar dropdown ──
          if (user != null) _ProfileDropdown(user: user),
        ],
      ),
    );
  }
}

// ── Customer header search bar (real TextField) ─────────────────────────
class _CustomerHeaderSearch extends StatefulWidget {
  @override
  State<_CustomerHeaderSearch> createState() => _CustomerHeaderSearchState();
}

class _CustomerHeaderSearchState extends State<_CustomerHeaderSearch> {
  final _controller = TextEditingController();

  String? _lastSyncedQ;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String query) {
    final trimmed = query.trim();
    // Don't clear — keep the query visible in the search bar
    FocusScope.of(context).unfocus();
    // Delay navigation to next microtask to avoid GlobalKey
    // conflict during widget tree rebuild
    Future.microtask(() {
      if (!mounted) return;
      if (trimmed.isEmpty) {
        context.go(RouteNames.search);
      } else {
        context.go('${RouteNames.search}?q=${Uri.encodeComponent(trimmed)}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final isSearchRoute = state.matchedLocation == RouteNames.search;
    final q = isSearchRoute ? state.uri.queryParameters['q']?.trim() ?? '' : '';

    if (isSearchRoute && q != _lastSyncedQ) {
      _lastSyncedQ = q;
      _controller.value = TextEditingValue(
        text: q,
        selection: TextSelection.collapsed(offset: q.length),
      );
    }

    return SizedBox(
      height: 38,
      child: TextField(
        controller: _controller,
        style: GoogleFonts.inter(fontSize: 13, color: _kInk),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search services, providers...',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: _kMuted),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 10, right: 6),
            child: Icon(Icons.auto_awesome, size: 16, color: _kPrimary),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 32, minHeight: 16),
          filled: true,
          fillColor: _kBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kPrimary, width: 1.5),
          ),
        ),
        onSubmitted: _submit,
      ),
    );
  }
}

// ── Provider header search bar (real TextField) ─────────────────────────
class _ProviderHeaderSearch extends StatefulWidget {
  @override
  State<_ProviderHeaderSearch> createState() => _ProviderHeaderSearchState();
}

class _ProviderHeaderSearchState extends State<_ProviderHeaderSearch> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String query) {
    final trimmed = query.trim();
    _controller.clear();
    FocusScope.of(context).unfocus();
    Future.microtask(() {
      if (!mounted) return;
      if (trimmed.isEmpty) {
        context.go(RouteNames.myServices);
      } else {
        context
            .go('${RouteNames.myServices}?q=${Uri.encodeComponent(trimmed)}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _controller,
        style: GoogleFonts.inter(fontSize: 13, color: _kInk),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search your services...',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: _kMuted),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 10, right: 6),
            child: Icon(Icons.search, size: 16, color: _kMuted),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 32, minHeight: 16),
          filled: true,
          fillColor: _kBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kPrimary, width: 1.5),
          ),
        ),
        onSubmitted: _submit,
      ),
    );
  }
}

// ── Notification bell with popover ──────────────────────────────────────
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell({required this.userId, required this.role});
  final String userId;
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadCountProvider(userId));
    final unread = unreadAsync.valueOrNull ?? 0;

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      constraints: const BoxConstraints(maxWidth: 360, minWidth: 320),
      onSelected: (value) {
        if (value == 'view_all') {
          _navigateToNotifications(context, role);
        } else if (value == 'mark_all') {
          ref.read(notificationActionProvider.notifier).markAllAsRead(userId);
        }
      },
      itemBuilder: (context) {
        final notifAsync = ref.read(userNotificationsProvider(userId));
        final notifications = notifAsync.valueOrNull ?? [];
        final latest = notifications.take(4).toList();

        return [
          // Header
          PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text('Notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                      )),
                  const Spacer(),
                  if (unread > 0)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        ref
                            .read(notificationActionProvider.notifier)
                            .markAllAsRead(userId);
                      },
                      child: Text('Mark all read',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kPrimary,
                          )),
                    ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),

          // Notification items
          if (latest.isEmpty)
            PopupMenuItem<String>(
              enabled: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No notifications yet',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _kMuted,
                      )),
                ),
              ),
            )
          else
            ...latest.map((n) => PopupMenuItem<String>(
                  padding: EdgeInsets.zero,
                  onTap: () {
                    // Mark read on tap
                    if (!n.isRead) {
                      ref
                          .read(notificationActionProvider.notifier)
                          .markAsRead(notificationId: n.id, userId: userId);
                    }
                    // Navigate if route exists
                    final route = n.data['route'] as String?;
                    if (route != null && route.isNotEmpty) {
                      context.go(route);
                    }
                  },
                  child: _NotifTile(notification: n),
                )),

          const PopupMenuDivider(),

          // View all
          PopupMenuItem<String>(
            value: 'view_all',
            child: Center(
              child: Text('View all notifications',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  )),
            ),
          ),
        ];
      },
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _kBg,
            ),
            child: const Icon(Icons.notifications_outlined,
                size: 20, color: _kSecondary),
          ),
          if (unread > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToNotifications(BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.customer:
        context.go(RouteNames.customerNotifications);
      case UserRole.provider:
        context.go(RouteNames.providerNotifications);
      case UserRole.admin:
        context.go('/admin/notifications');
    }
  }
}

// ── Notification tile inside popover ────────────────────────────────────
class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: notification.isRead
          ? Colors.transparent
          : _kPrimary.withValues(alpha: 0.04),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _iconColor(notification.type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _iconData(notification.type),
              size: 16,
              color: _iconColor(notification.type),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight:
                        notification.isRead ? FontWeight.w400 : FontWeight.w600,
                    color: _kInk,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: GoogleFonts.inter(fontSize: 11.5, color: _kMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relTime(notification.createdAt),
            style: GoogleFonts.inter(fontSize: 10, color: _kMuted),
          ),
          if (!notification.isRead) ...[
            const SizedBox(width: 6),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _kPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _relTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return DateFormat('MMM d').format(t);
  }

  Color _iconColor(NotificationType type) => switch (type) {
        NotificationType.bookingReceived => const Color(0xFF2563EB),
        NotificationType.bookingConfirmed ||
        NotificationType.bookingCompleted ||
        NotificationType.verifiedBadgeGranted =>
          _kPrimary,
        NotificationType.bookingRejected ||
        NotificationType.bookingCancelled ||
        NotificationType.accountSuspended ||
        NotificationType.serviceDeactivated =>
          const Color(0xFFDC2626),
        NotificationType.reviewReceived => const Color(0xFFD97706),
        NotificationType.platformAnnouncement => const Color(0xFF64748B),
      };

  IconData _iconData(NotificationType type) => switch (type) {
        NotificationType.bookingReceived => Icons.event_available,
        NotificationType.bookingConfirmed => Icons.check_circle,
        NotificationType.bookingCompleted => Icons.task_alt,
        NotificationType.bookingRejected ||
        NotificationType.bookingCancelled =>
          Icons.cancel,
        NotificationType.reviewReceived => Icons.star,
        NotificationType.accountSuspended ||
        NotificationType.serviceDeactivated =>
          Icons.block,
        NotificationType.verifiedBadgeGranted => Icons.verified,
        NotificationType.platformAnnouncement => Icons.campaign,
      };
}

// ── Profile avatar dropdown ─────────────────────────────────────────────
class _ProfileDropdown extends ConsumerWidget {
  const _ProfileDropdown({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      constraints: const BoxConstraints(minWidth: 220),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            _navigateToProfile(context, user.role);
          case 'signout':
            ref.read(authNotifierProvider.notifier).logout();
        }
      },
      itemBuilder: (_) => [
        // User info header
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _avatar(28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kInk,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.email,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: _kMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: _kSecondary),
              const SizedBox(width: 10),
              Text('Profile',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _kSecondary,
                  )),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'signout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: Color(0xFF991B1B)),
              const SizedBox(width: 10),
              Text('Sign out',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF991B1B),
                  )),
            ],
          ),
        ),
      ],
      child: _avatar(36),
    );
  }

  Widget _avatar(double size) {
    final initials = user.name.isNotEmpty
        ? user.name
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(user.avatarUrl!),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _kPrimary.withValues(alpha: 0.12),
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          color: _kPrimary,
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.customer:
        context.go(RouteNames.customerProfile);
      case UserRole.provider:
        context.go(RouteNames.providerProfileEdit);
      case UserRole.admin:
        context.go(RouteNames.adminSettings);
    }
  }
}
