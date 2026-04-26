
// ---------------------------------------------------------------------------
// admin_user_detail_screen.dart
//
// Purpose: Detailed admin view of a single user. Shows profile info,
//   moderation actions (verify/suspend), and activity summary with
//   real computed stats.
//
// Route: /admin/user/:id  (inside AdminShell)
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/user_model.dart';
import '../../providers/user_provider.dart';

const _kPrimary = Color(0xFF2D9B6F);
const _kSecondary = Color(0xFF1A2B3C);
const _kBg = Color(0xFFF5F7FA);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);
const _kField = Color(0xFFEFF4F9);
const _kGreenBg = Color(0xFFD1FAE5);
const _kGreenFg = Color(0xFF065F46);
const _kRedBg = Color(0xFFFEE2E2);
const _kRedFg = Color(0xFF991B1B);
const _kCustBg = Color(0xFFDBEAFE);
const _kCustFg = Color(0xFF1E40AF);
const _kProvBg = Color(0xFFD1FAE5);
const _kProvFg = Color(0xFF065F46);
const _kAdminBg = Color(0xFFE2E8F0);
const _kAdminFg = Color(0xFF334155);

final _userBookingsCountProvider =
    FutureProvider.family.autoDispose<int, String>((ref, userId) async {
  final rows = await Supabase.instance.client
      .from('bookings')
      .select('id')
      .or('customer_id.eq.$userId,provider_id.eq.$userId');
  return (rows as List).length;
});

final _userServicesCountProvider =
    FutureProvider.family.autoDispose<int, String>((ref, userId) async {
  final rows = await Supabase.instance.client
      .from('services')
      .select('id')
      .eq('provider_id', userId);
  return (rows as List).length;
});

class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));

    return Container(
      color: _kBg,
      child: userAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kPrimary)),
        error: (e, _) => Center(
          child: Text('Error: $e', style: GoogleFonts.inter(color: _kRedFg)),
        ),
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(user: user),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (ctx, cons) {
                  final twoCol = cons.maxWidth >= 900;
                  final left = _ProfileCard(user: user);
                  final right = _RightCol(user: user, userId: userId);
                  if (twoCol) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: left),
                        const SizedBox(width: 20),
                        Expanded(flex: 3, child: right),
                      ],
                    );
                  }
                  return Column(
                      children: [left, const SizedBox(height: 20), right]);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () =>
              context.canPop() ? context.pop() : context.go('/admin/users'),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: const Icon(Icons.arrow_back, size: 18, color: _kInk),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Detail',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              Text(
                'Viewing ${user.name}',
                style: GoogleFonts.inter(fontSize: 13, color: _kMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          _BigAvatar(
              name: user.name, url: user.avatarUrl, verified: user.isVerified),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (user.isVerified) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: _kPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(user.email,
              style: GoogleFonts.inter(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 10),
          _RolePill(role: user.role),
          const SizedBox(height: 20),
          const Divider(color: _kBorder),
          const SizedBox(height: 14),
          _InfoRow('City', user.city ?? 'Not set'),
          _InfoRow('Joined', DateFormat('MMMM d, yyyy').format(user.createdAt)),
          _InfoRow('Status', user.isSuspended ? 'Suspended' : 'Active',
              valueColor: user.isSuspended ? _kRedFg : _kGreenFg),
          _InfoRow('Phone', user.phone ?? 'Not provided'),
          if (user.role == UserRole.provider) ...[
            const SizedBox(height: 14),
            const Divider(color: _kBorder),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PROFESSIONAL PROFILE',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if ((user.bio ?? '').isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kField,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  user.bio!,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: _kInk, height: 1.6),
                ),
              ),
            if ((user.bio ?? '').isNotEmpty) const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _MiniStat(
                        'EXPERIENCE',
                        user.experienceYears != null
                            ? '${user.experienceYears} Years'
                            : 'Not set')),
                const SizedBox(width: 12),
                Expanded(
                    child: _MiniStat(
                        'SERVICE AREA', user.serviceArea ?? 'Not set')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BigAvatar extends StatelessWidget {
  const _BigAvatar({required this.name, this.url, required this.verified});
  final String name;
  final String? url;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final init = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Stack(
      children: [
        if (url != null && url!.isNotEmpty)
          CircleAvatar(
            radius: 40,
            backgroundColor: _kBorder,
            backgroundImage: NetworkImage(url!),
            onBackgroundImageError: (_, __) {},
          )
        else
          CircleAvatar(
            radius: 40,
            backgroundColor: _kPrimary.withValues(alpha: 0.12),
            child: Text(
              init,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: _kPrimary,
                fontSize: 32,
              ),
            ),
          ),
        if (verified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: _kPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (role) {
      UserRole.customer => (_kCustBg, _kCustFg, 'CUSTOMER'),
      UserRole.provider => (_kProvBg, _kProvFg, 'PROVIDER'),
      UserRole.admin => (_kAdminBg, _kAdminFg, 'ADMIN'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: 0.5),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500, color: _kMuted),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? _kInk),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _kField, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kMuted,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w700, color: _kInk),
          ),
        ],
      ),
    );
  }
}

class _RightCol extends ConsumerWidget {
  const _RightCol({required this.user, required this.userId});
  final UserModel user;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModCard(user: user, userId: userId),
        const SizedBox(height: 16),
        _StatsCard(user: user, userId: userId),
      ],
    );
  }
}

class _ModCard extends ConsumerStatefulWidget {
  const _ModCard({required this.user, required this.userId});
  final UserModel user;
  final String userId;

  @override
  ConsumerState<_ModCard> createState() => _ModCardState();
}

class _ModCardState extends ConsumerState<_ModCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: _kSecondary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 10),
              Text(
                'Moderation Actions',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'VERIFICATION',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 0.8),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: user.isVerified ? _kGreenBg : _kBg,
                    borderRadius: BorderRadius.circular(999)),
                child: Text(
                  user.isVerified ? 'VERIFIED' : 'NOT VERIFIED',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: user.isVerified ? _kGreenFg : _kMuted),
                ),
              ),
              const Spacer(),
              Text(
                'ACCOUNT HEALTH',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 0.8),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: user.isSuspended ? _kRedBg : _kGreenBg,
                    borderRadius: BorderRadius.circular(999)),
                child: Text(
                  user.isSuspended ? 'SUSPENDED' : 'ACTIVE',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: user.isSuspended ? _kRedFg : _kGreenFg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (user.role == UserRole.provider) ...[
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _busy ? null : () => _toggleVerified(user),
                      icon: Icon(
                          user.isVerified
                              ? Icons.remove_moderator
                              : Icons.verified,
                          size: 16,
                          color: Colors.white),
                      label: Text(
                        user.isVerified ? 'Revoke Verified' : 'Grant Verified',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: user.isSuspended ? _kPrimary : _kRedFg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _busy ? null : () => _toggleSuspend(user),
                    icon: Icon(user.isSuspended ? Icons.lock_open : Icons.block,
                        size: 16),
                    label: Text(
                      user.isSuspended ? 'Unsuspend' : 'Suspend Account',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleVerified(UserModel user) async {
    setState(() => _busy = true);
    await ref.read(adminUserProvider.notifier).setVerifiedStatus(
        targetUserId: widget.userId, isVerified: !user.isVerified);
    ref.invalidate(userProfileProvider(widget.userId));
    ref.invalidate(allUsersProvider);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _toggleSuspend(UserModel user) async {
    final action = user.isSuspended ? 'unsuspend' : 'suspend';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          '${action[0].toUpperCase()}${action.substring(1)} ${user.name}?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          user.isSuspended
              ? 'This will restore the user\'s access.'
              : 'This will block the user from accessing the platform.',
          style: GoogleFonts.inter(fontSize: 14, color: _kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: _kMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: user.isSuspended ? _kPrimary : _kRedFg),
            onPressed: () => Navigator.of(dialogContext).pop(true),
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
    await ref.read(adminUserProvider.notifier).setUserSuspension(
        targetUserId: widget.userId, suspend: !user.isSuspended);
    ref.invalidate(userProfileProvider(widget.userId));
    ref.invalidate(allUsersProvider);
    if (mounted) setState(() => _busy = false);
  }
}

class _StatsCard extends ConsumerWidget {
  const _StatsCard({required this.user, required this.userId});
  final UserModel user;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(_userBookingsCountProvider(userId));
    final servicesAsync = ref.watch(_userServicesCountProvider(userId));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Summary',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _kInk)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: user.role == UserRole.provider
                      ? 'BOOKINGS RECEIVED'
                      : 'TOTAL BOOKINGS',
                  value: bookingsAsync.maybeWhen(
                      data: (n) => '$n', orElse: () => '—'),
                ),
              ),
              if (user.role == UserRole.provider) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: 'TOTAL SERVICES',
                    value: servicesAsync.maybeWhen(
                        data: (n) => '$n', orElse: () => '—'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _kMuted,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.w700, color: _kInk)),
        ],
      ),
    );
  }
}
