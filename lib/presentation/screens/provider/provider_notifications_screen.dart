// ---------------------------------------------------------------------------
// provider_notifications_screen.dart
//
// Purpose: Provider-facing notification feed. Redesigned web UI from
//   Stitch mockups. Lists real notifications from Supabase with
//   type-based color accents, All/Unread filter tabs, Mark-all-as-read,
//   and tap-to-navigate via data.route payload.
//
// Route: /p/notifications  (OUTSIDE ProviderShell — own Scaffold)
//
// Data source: userNotificationsProvider(user.id)
// Actions: notificationActionProvider (markAsRead, markAllAsRead)
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/user_model.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/app_top_bar.dart';

// ── Design Tokens ───────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF2D9B6F);
const _kBg = Color(0xFFF5F7FA);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);

// Accent palette for notification types
const _kBlueBg = Color(0xFFDBEAFE);
const _kBlueFg = Color(0xFF1E40AF);
const _kAmberBg = Color(0xFFFEF3C7);
const _kAmberFg = Color(0xFFD97706);
const _kGreenBg = Color(0xFFD1FAE5);
const _kGreenFg = Color(0xFF065F46);
const _kRedBg = Color(0xFFFEE2E2);
const _kRedFg = Color(0xFF991B1B);
const _kSlateBg = Color(0xFFE2E8F0);
const _kSlateFg = Color(0xFF334155);

enum _Filter { all, unread }

class ProviderNotificationsScreen extends ConsumerStatefulWidget {
  const ProviderNotificationsScreen({super.key});

  @override
  ConsumerState<ProviderNotificationsScreen> createState() =>
      _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState
    extends ConsumerState<ProviderNotificationsScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= 800;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    final notifsAsync = ref.watch(userNotificationsProvider(user.id));

    return Scaffold(
      backgroundColor: _kBg,
      body: Row(
        children: [
          if (showSidebar)
            const AppSidebar(
              role: UserRole.provider,
              currentRoute: '/p/notifications',
            ),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderRow(
                          onMarkAllRead: () => ref
                              .read(notificationActionProvider.notifier)
                              .markAllAsRead(user.id),
                          onDeleteAll: () =>
                              _showDeleteAllConfirm(context, user.id, ref),
                          hasUnread: notifsAsync.maybeWhen(
                            data: (list) => list.any((n) => !n.isRead),
                            orElse: () => false,
                          ),
                          hasNotifications: notifsAsync.maybeWhen(
                            data: (list) => list.isNotEmpty,
                            orElse: () => false,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _FilterTabs(
                          current: _filter,
                          onChanged: (f) => setState(() => _filter = f),
                        ),
                        const SizedBox(height: 20),
                        notifsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child:
                                  CircularProgressIndicator(color: _kPrimary),
                            ),
                          ),
                          error: (e, _) => _ErrorBlock(message: e.toString()),
                          data: (list) {
                            final filtered = _filter == _Filter.unread
                                ? list.where((n) => !n.isRead).toList()
                                : list;
                            if (filtered.isEmpty) {
                              return _EmptyBlock(
                                message: _filter == _Filter.unread
                                    ? 'No unread notifications'
                                    : 'No notifications yet',
                              );
                            }
                            return Column(
                              children: [
                                for (final n in filtered) ...[
                                  const SizedBox(height: 0),
                                  _NotificationTile(
                                    notification: n,
                                    onTap: () => _handleTap(n, user.id),
                                    onDelete: () => ref
                                        .read(
                                            notificationActionProvider.notifier)
                                        .deleteNotification(
                                          notificationId: n.id,
                                          userId: user.id,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTap(NotificationModel n, String userId) async {
    if (!n.isRead) {
      await ref.read(notificationActionProvider.notifier).markAsRead(
            notificationId: n.id,
            userId: userId,
          );
    }
    if (!mounted) return;
    final route = n.navigationRoute;
    if (route != null && route.isNotEmpty) {
      context.go(route);
    }
  }

  void _showDeleteAllConfirm(
      BuildContext context, String userId, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete all notifications',
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('This will permanently delete all your notifications.',
            style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(notificationActionProvider.notifier)
                  .deleteAllNotifications(userId);
            },
            child: Text('Delete all',
                style: GoogleFonts.inter(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.onMarkAllRead,
    required this.onDeleteAll,
    required this.hasUnread,
    required this.hasNotifications,
  });
  final VoidCallback onMarkAllRead;
  final VoidCallback onDeleteAll;
  final bool hasUnread;
  final bool hasNotifications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: _kInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stay updated with your latest bookings and activity',
                    style: GoogleFonts.inter(fontSize: 14, color: _kMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (hasUnread) _MarkAllReadBtn(onTap: onMarkAllRead),
            if (hasNotifications) ...[
              const SizedBox(width: 10),
              _DeleteAllBtn(onTap: onDeleteAll),
            ],
          ],
        ),
      ],
    );
  }
}

class _MarkAllReadBtn extends StatelessWidget {
  const _MarkAllReadBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.done_all, size: 16, color: _kPrimary),
      label: Text('Mark all as read',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          )),
    );
  }
}

class _DeleteAllBtn extends StatelessWidget {
  const _DeleteAllBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon:
          const Icon(Icons.delete_outline, size: 16, color: Color(0xFF991B1B)),
      label: Text('Delete all',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF991B1B),
          )),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTER TABS
// ═══════════════════════════════════════════════════════════════════════════

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.current, required this.onChanged});
  final _Filter current;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabBtn(
            label: 'All',
            active: current == _Filter.all,
            onTap: () => onChanged(_Filter.all),
          ),
          const SizedBox(width: 4),
          _TabBtn(
            label: 'Unread',
            active: current == _Filter.unread,
            onTap: () => onChanged(_Filter.unread),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
        decoration: BoxDecoration(
          color: active ? _kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : _kMuted,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION TILE
// ═══════════════════════════════════════════════════════════════════════════

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final meta = _typeMeta(notification.type);
    final tappable = notification.navigationRoute != null &&
        notification.navigationRoute!.isNotEmpty;

    return InkWell(
      onTap: tappable ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: meta.fg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              // Icon
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: meta.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(meta.icon, color: meta.fg, size: 20),
                ),
              ),
              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: meta.fg,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _kInk,
                          height: 1.5,
                        ),
                      ),
                      if (tappable) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'View details',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward,
                                size: 13, color: _kPrimary),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Right meta: time + unread dot
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: Color(0xFF991B1B)),
                      splashRadius: 16,
                      tooltip: 'Delete',
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _relativeTime(notification.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _kMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!notification.isRead)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: _kPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TypeMeta _typeMeta(NotificationType t) {
    switch (t) {
      case NotificationType.bookingReceived:
        return const _TypeMeta(_kBlueBg, _kBlueFg, Icons.event_available);
      case NotificationType.bookingConfirmed:
        return const _TypeMeta(_kGreenBg, _kGreenFg, Icons.check_circle);
      case NotificationType.bookingCompleted:
        return const _TypeMeta(_kGreenBg, _kGreenFg, Icons.task_alt);
      case NotificationType.bookingRejected:
      case NotificationType.bookingCancelled:
        return const _TypeMeta(_kRedBg, _kRedFg, Icons.cancel);
      case NotificationType.reviewReceived:
        return const _TypeMeta(_kAmberBg, _kAmberFg, Icons.star);
      case NotificationType.accountSuspended:
      case NotificationType.serviceDeactivated:
        return const _TypeMeta(_kRedBg, _kRedFg, Icons.block);
      case NotificationType.verifiedBadgeGranted:
        return const _TypeMeta(_kGreenBg, _kGreenFg, Icons.verified);
      case NotificationType.platformAnnouncement:
        return const _TypeMeta(_kSlateBg, _kSlateFg, Icons.campaign);
    }
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes} MIN AGO';
    if (diff.inHours < 24) {
      return '${diff.inHours} HOUR${diff.inHours == 1 ? '' : 'S'} AGO';
    }
    if (diff.inDays == 1) return 'YESTERDAY';
    if (diff.inDays < 7) return '${diff.inDays} DAYS AGO';
    return DateFormat('MMM d').format(t).toUpperCase();
  }
}

class _TypeMeta {
  const _TypeMeta(this.bg, this.fg, this.icon);
  final Color bg;
  final Color fg;
  final IconData icon;
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY + ERROR
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.notifications_none, color: _kMuted, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You\'ll see new activity here as it happens',
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
            'Could not load notifications',
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
