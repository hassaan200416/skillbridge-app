// ---------------------------------------------------------------------------
// admin_users_screen.dart
//
// Purpose: Admin user management table. Search, filter by role,
//   view detail, toggle verified badge, suspend/unsuspend accounts.
//   All data from allUsersProvider — no new queries.
//
// Route: /admin/users  (inside AdminShell)
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/user_model.dart';
import '../../providers/user_provider.dart';

// ── Design Tokens ───────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF2D9B6F);
const _kBg = Color(0xFFF5F7FA);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);
const _kField = Color(0xFFEFF4F9);

// Role badge colors
const _kCustBg = Color(0xFFDBEAFE);
const _kCustFg = Color(0xFF1E40AF);
const _kProvBg = Color(0xFFD1FAE5);
const _kProvFg = Color(0xFF065F46);
const _kAdminBg = Color(0xFFE2E8F0);
const _kAdminFg = Color(0xFF334155);

// Status
const _kGreenFg = Color(0xFF065F46);
const _kRedBg = Color(0xFFFEE2E2);
const _kRedFg = Color(0xFF991B1B);

enum _RoleFilter { all, customer, provider, admin }

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _search = '';
  _RoleFilter _role = _RoleFilter.all;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Container(
      color: _kBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(),
            const SizedBox(height: 24),
            _ControlsRow(
              search: _search,
              role: _role,
              onSearchChanged: (v) => setState(() => _search = v),
              onRoleChanged: (r) => setState(() => _role = r),
              totalCount: usersAsync.maybeWhen(
                data: (u) => u.length,
                orElse: () => null,
              ),
            ),
            const SizedBox(height: 20),
            usersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(color: _kPrimary),
                ),
              ),
              error: (e, _) => _ErrorBlock(message: e.toString()),
              data: (users) {
                final filtered = _applyFilters(users);
                if (filtered.isEmpty) return const _EmptyBlock();
                return _UsersTable(users: filtered);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<UserModel> _applyFilters(List<UserModel> users) {
    var list = users;
    if (_role != _RoleFilter.all) {
      final roleMatch = switch (_role) {
        _RoleFilter.customer => UserRole.customer,
        _RoleFilter.provider => UserRole.provider,
        _RoleFilter.admin => UserRole.admin,
        _ => null,
      };
      if (roleMatch != null) {
        list = list.where((u) => u.role == roleMatch).toList();
      }
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Management',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _kInk,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Manage all platform accounts',
          style: GoogleFonts.inter(fontSize: 13.5, color: _kMuted),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTROLS ROW: search + role tabs + count pill
// ═══════════════════════════════════════════════════════════════════════════

class _ControlsRow extends StatelessWidget {
  const _ControlsRow({
    required this.search,
    required this.role,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.totalCount,
  });
  final String search;
  final _RoleFilter role;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_RoleFilter> onRoleChanged;
  final int? totalCount;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchField(value: search, onChanged: onSearchChanged),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _RoleTabs(current: role, onChanged: onRoleChanged)),
              const SizedBox(width: 10),
              if (totalCount != null) _CountPill(count: totalCount!),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 280,
          child: _SearchField(value: search, onChanged: onSearchChanged),
        ),
        const SizedBox(width: 14),
        Expanded(child: _RoleTabs(current: role, onChanged: onRoleChanged)),
        const SizedBox(width: 14),
        if (totalCount != null) _CountPill(count: totalCount!),
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
        hintText: 'Search by name or email...',
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

class _RoleTabs extends StatelessWidget {
  const _RoleTabs({required this.current, required this.onChanged});
  final _RoleFilter current;
  final ValueChanged<_RoleFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _RoleFilter.values.map((r) {
          final active = r == current;
          final label = switch (r) {
            _RoleFilter.all => 'All Users',
            _RoleFilter.customer => 'Customers',
            _RoleFilter.provider => 'Providers',
            _RoleFilter.admin => 'Admins',
          };
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => onChanged(r),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? _kPrimary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? _kPrimary : _kMuted,
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
        '$count users',
        style: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _kMuted,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USERS TABLE
// ═══════════════════════════════════════════════════════════════════════════

class _UsersTable extends ConsumerWidget {
  const _UsersTable({required this.users});
  final List<UserModel> users;

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
          _TableHeader(),
          for (int i = 0; i < users.length; i++) ...[
            _TableRow(user: users[i]),
            if (i < users.length - 1)
              const Divider(
                  height: 1, color: _kBorder, indent: 20, endIndent: 20),
          ],
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 4, child: _ColLabel('USER')),
          Expanded(flex: 2, child: _ColLabel('ROLE', center: true)),
          Expanded(flex: 2, child: _ColLabel('JOINED', center: true)),
          Expanded(flex: 2, child: _ColLabel('STATUS', center: true)),
          Expanded(flex: 2, child: _ColLabel('ACTIONS', center: true)),
        ],
      ),
    );
  }
}

class _ColLabel extends StatelessWidget {
  const _ColLabel(this.label, {this.center = false});
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

class _TableRow extends ConsumerStatefulWidget {
  const _TableRow({required this.user});
  final UserModel user;

  @override
  ConsumerState<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends ConsumerState<_TableRow> {
  bool _hover = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        color: _hover ? _kBg : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // USER
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  _UserAvatar(
                      name: u.name, url: u.avatarUrl, verified: u.isVerified),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kInk,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          u.email,
                          style:
                              GoogleFonts.inter(fontSize: 12, color: _kMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ROLE
            Expanded(
              flex: 2,
              child: Center(child: _RoleBadge(role: u.role)),
            ),
            // JOINED
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  DateFormat('dd MMM yyyy').format(u.createdAt),
                  style: GoogleFonts.inter(fontSize: 13, color: _kInk),
                ),
              ),
            ),
            // STATUS
            Expanded(
              flex: 2,
              child: Center(child: _StatusDot(suspended: u.isSuspended)),
            ),
            // ACTIONS
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionIcon(
                    icon: Icons.visibility_outlined,
                    tooltip: 'View details',
                    onTap: () => context.go('/admin/user/${u.id}'),
                  ),
                  if (u.role == UserRole.provider) ...[
                    const SizedBox(width: 6),
                    _ActionIcon(
                      icon: u.isVerified
                          ? Icons.verified
                          : Icons.verified_outlined,
                      tooltip:
                          u.isVerified ? 'Revoke verified' : 'Grant verified',
                      color: u.isVerified ? _kPrimary : null,
                      onTap: _busy ? null : () => _toggleVerified(u),
                    ),
                  ],
                  const SizedBox(width: 6),
                  _ActionIcon(
                    icon: u.isSuspended ? Icons.lock_open : Icons.block,
                    tooltip: u.isSuspended ? 'Unsuspend' : 'Suspend',
                    bgColor: u.isSuspended ? _kRedBg : null,
                    color: u.isSuspended ? _kRedFg : null,
                    onTap: _busy ? null : () => _toggleSuspend(u),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleVerified(UserModel u) async {
    setState(() => _busy = true);
    await ref.read(adminUserProvider.notifier).setVerifiedStatus(
          targetUserId: u.id,
          isVerified: !u.isVerified,
        );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _toggleSuspend(UserModel u) async {
    final action = u.isSuspended ? 'unsuspend' : 'suspend';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          '${action[0].toUpperCase()}${action.substring(1)} ${u.name}?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          u.isSuspended
              ? 'This will restore the user\'s access to the platform.'
              : 'This will block the user from accessing the platform.',
          style: GoogleFonts.inter(fontSize: 14, color: _kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: _kMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: u.isSuspended ? _kPrimary : _kRedFg,
            ),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(
              u.isSuspended ? 'Unsuspend' : 'Suspend',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    final success =
        await ref.read(adminUserProvider.notifier).setUserSuspension(
              targetUserId: u.id,
              suspend: !u.isSuspended,
            );
    if (mounted) {
      setState(() => _busy = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('User ${u.isSuspended ? 'unsuspended' : 'suspended'}'),
            backgroundColor: _kPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TABLE PRIMITIVES
// ═══════════════════════════════════════════════════════════════════════════

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name, this.url, required this.verified});
  final String name;
  final String? url;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Stack(
      children: [
        if (url != null && url!.isNotEmpty)
          CircleAvatar(
            radius: 18,
            backgroundColor: _kBorder,
            backgroundImage: NetworkImage(url!),
            onBackgroundImageError: (_, __) {},
          )
        else
          CircleAvatar(
            radius: 18,
            backgroundColor: _kPrimary.withValues(alpha: 0.12),
            child: Text(
              initial,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: _kPrimary,
                fontSize: 13,
              ),
            ),
          ),
        if (verified)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 8, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (role) {
      UserRole.customer => (_kCustBg, _kCustFg, 'CUSTOMER'),
      UserRole.provider => (_kProvBg, _kProvFg, 'PROVIDER'),
      UserRole.admin => (_kAdminBg, _kAdminFg, 'ADMIN'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.suspended});
  final bool suspended;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: suspended ? _kRedFg : _kGreenFg,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          suspended ? 'Suspended' : 'Active',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: suspended ? _kRedFg : _kGreenFg,
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
    this.bgColor,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;
  final Color? bgColor;

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
            color: bgColor ?? _kBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color ?? _kMuted),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY + ERROR
// ═══════════════════════════════════════════════════════════════════════════

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
            child: const Icon(Icons.people_outline, color: _kMuted, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            'No users found',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search or filter',
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
            'Could not load users',
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
