// ---------------------------------------------------------------------------
// provider_profile_edit_screen.dart
//
// Purpose: Provider-facing Edit Profile screen. Redesigned web UI from
//   Stitch mockups. Two-column layout: left (avatar + live stats),
//   right (editable form). Live rating and jobs-done stats computed
//   from Supabase via small inline FutureProviders. Avatar upload uses
//   existing StorageService + AuthRepository.updateProfile pattern.
//
// Route: /p/profile  (OUTSIDE ProviderShell — own Scaffold)
//
// Actions:
//   - Avatar: StorageService.pickImage + authNotifier.updateProfile
//   - Form submit: authNotifierProvider.notifier.updateProfile(...)
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/route_names.dart';
import '../../../data/models/user_model.dart';
import '../../../services/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/app_top_bar.dart';

// ── Design Tokens ───────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF2D9B6F);
const _kBg = Color(0xFFF5F7FA);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);
const _kField = Color(0xFFEFF4F9);
const _kAmberBg = Color(0xFFFEF3C7);
const _kAmberFg = Color(0xFFD97706);
const _kRedFg = Color(0xFF991B1B);

// Cities (scoped to your project: Pakistan, 3 cities)
const _kCities = ['Karachi', 'Lahore', 'Islamabad'];

// ── Live stats providers (inline to this screen) ────────────────────────────

final _providerRatingProvider =
    FutureProvider.family.autoDispose<double?, String>((ref, providerId) async {
  final client = Supabase.instance.client;
  final rows = await client
      .from('reviews')
      .select('rating')
      .eq('provider_id', providerId);
  final list = (rows as List).cast<Map<String, dynamic>>();
  if (list.isEmpty) return null;
  final total = list.fold<int>(0, (sum, r) => sum + (r['rating'] as int));
  return total / list.length;
});

final _providerJobsDoneProvider =
    FutureProvider.family.autoDispose<int, String>((ref, providerId) async {
  final client = Supabase.instance.client;
  final rows = await client
      .from('bookings')
      .select('id')
      .eq('provider_id', providerId)
      .eq('status', 'completed');
  return (rows as List).length;
});

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class ProviderProfileEditScreen extends ConsumerStatefulWidget {
  const ProviderProfileEditScreen({super.key});

  @override
  ConsumerState<ProviderProfileEditScreen> createState() =>
      _ProviderProfileEditScreenState();
}

class _ProviderProfileEditScreenState
    extends ConsumerState<ProviderProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _serviceAreaCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String? _city;
  XFile? _pendingAvatar;
  Uint8List? _pendingAvatarBytes;
  bool _seeded = false;
  bool _dirty = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _serviceAreaCtrl.dispose();
    _experienceCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _seedFrom(UserModel u) {
    if (_seeded) return;
    _nameCtrl.text = u.name;
    _phoneCtrl.text = u.phone ?? '';
    _serviceAreaCtrl.text = u.serviceArea ?? '';
    _experienceCtrl.text = (u.experienceYears ?? '').toString();
    _bioCtrl.text = u.bio ?? '';
    _city = _kCities.contains(u.city) ? u.city : null;
    _seeded = true;
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

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

    _seedFrom(user);

    return Scaffold(
      backgroundColor: _kBg,
      body: Row(
        children: [
          if (showSidebar)
            const AppSidebar(
              role: UserRole.provider,
              currentRoute: RouteNames.providerProfileEdit,
            ),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    child: Form(
                      key: _formKey,
                      onChanged: _markDirty,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _HeaderRow(),
                          const SizedBox(height: 24),
                          _buildMainArea(user, width),
                          const SizedBox(height: 32),
                        ],
                      ),
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

  Widget _buildMainArea(UserModel user, double width) {
    final twoColumn = width >= 1100;
    final left = _LeftPanel(
      user: user,
      pendingAvatarBytes: _pendingAvatarBytes,
      onPickAvatar: _pickAvatar,
    );
    final right = _RightPanel(
      user: user,
      nameCtrl: _nameCtrl,
      phoneCtrl: _phoneCtrl,
      serviceAreaCtrl: _serviceAreaCtrl,
      experienceCtrl: _experienceCtrl,
      bioCtrl: _bioCtrl,
      city: _city,
      onCityChanged: (v) {
        setState(() {
          _city = v;
          _dirty = true;
        });
      },
      onDiscard: _discard,
      onSave: _save,
      dirty: _dirty || _pendingAvatar != null,
    );
    if (twoColumn) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: left),
            const SizedBox(width: 20),
            Expanded(flex: 3, child: right),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [left, const SizedBox(height: 20), right],
    );
  }

  // ── Actions ──

  Future<void> _pickAvatar() async {
    try {
      final picked = await StorageService.instance.pickImage();
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pendingAvatar = picked;
        _pendingAvatarBytes = bytes;
        _dirty = true;
      });
    } catch (e) {
      if (!mounted) return;
      _snack('Could not pick image: $e', error: true);
    }
  }

  void _discard() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() {
      _seeded = false;
      _pendingAvatar = null;
      _pendingAvatarBytes = null;
      _dirty = false;
    });
    _seedFrom(user);
    _snack('Changes discarded');
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final yrs = _experienceCtrl.text.trim().isEmpty
        ? null
        : int.tryParse(_experienceCtrl.text.trim());

    final success = await ref.read(authNotifierProvider.notifier).updateProfile(
          userId: user.id,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          city: _city,
          bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
          experienceYears: yrs,
          serviceArea: _serviceAreaCtrl.text.trim().isEmpty
              ? null
              : _serviceAreaCtrl.text.trim(),
          newAvatarImage: _pendingAvatar,
        );

    if (!mounted) return;
    if (success) {
      setState(() {
        _pendingAvatar = null;
        _pendingAvatarBytes = null;
        _dirty = false;
        _seeded = false; // reseed from updated user on next build
      });
      _snack('Profile updated');
    } else {
      final err = ref.read(authNotifierProvider).error?.message ??
          'Could not save changes';
      _snack(err, error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? _kRedFg : _kPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _BackBtn(
          onTap: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.providerHome),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage your public profile and contact details',
                style: GoogleFonts.inter(fontSize: 13, color: _kMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: const Icon(Icons.arrow_back, color: _kInk, size: 19),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LEFT PANEL: avatar card + live stats + honest tip
// ═══════════════════════════════════════════════════════════════════════════

class _LeftPanel extends ConsumerWidget {
  const _LeftPanel({
    required this.user,
    required this.pendingAvatarBytes,
    required this.onPickAvatar,
  });
  final UserModel user;
  final Uint8List? pendingAvatarBytes;
  final VoidCallback onPickAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingAsync = ref.watch(_providerRatingProvider(user.id));
    final jobsAsync = ref.watch(_providerJobsDoneProvider(user.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AvatarCard(
          user: user,
          pendingBytes: pendingAvatarBytes,
          onPick: onPickAvatar,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.star_rounded,
                iconColor: _kAmberFg,
                label: 'RATING',
                valueWidget: ratingAsync.when(
                  loading: () => const _StatSkeleton(),
                  error: (_, __) => const _StatText('—'),
                  data: (avg) =>
                      _StatText(avg == null ? '—' : avg.toStringAsFixed(1)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.check_circle_rounded,
                iconColor: _kPrimary,
                label: 'JOBS DONE',
                valueWidget: jobsAsync.when(
                  loading: () => const _StatSkeleton(),
                  error: (_, __) => const _StatText('—'),
                  data: (n) => _StatText('$n'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _HonestTipCard(),
      ],
    );
  }
}

// ── Avatar card ──

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({
    required this.user,
    required this.pendingBytes,
    required this.onPick,
  });
  final UserModel user;
  final Uint8List? pendingBytes;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Decorative gradient strip (purely visual, no data)
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kPrimary.withValues(alpha: 0.15),
                  _kPrimary.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -56),
            child: Column(
              children: [
                _AvatarWithCamera(
                  url: user.avatarUrl,
                  pendingBytes: pendingBytes,
                  name: user.name,
                  onPick: onPick,
                ),
                const SizedBox(height: 12),
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
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: _kPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 12, color: Colors.white),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.role.name[0].toUpperCase() + user.role.name.substring(1),
                  style: GoogleFonts.inter(fontSize: 13, color: _kMuted),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarWithCamera extends StatelessWidget {
  const _AvatarWithCamera({
    required this.url,
    required this.pendingBytes,
    required this.name,
    required this.onPick,
  });
  final String? url;
  final Uint8List? pendingBytes;
  final String name;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(child: _avatarImage()),
        ),
        Positioned(
          right: 0,
          bottom: 4,
          child: Material(
            color: _kPrimary,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPick,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.camera_alt, size: 15, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarImage() {
    if (pendingBytes != null) {
      return Image.memory(pendingBytes!, fit: BoxFit.cover);
    }
    if (url != null && url!.isNotEmpty) {
      return Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: _kPrimary.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontSize: 42,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      ),
    );
  }
}

// ── Stat tile + skeleton ──

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.valueWidget,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget valueWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          valueWidget,
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
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

class _StatText extends StatelessWidget {
  const _StatText(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: _kInk,
      ),
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 26,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ── Honest tip (no invented percentages) ──

class _HonestTipCard extends StatelessWidget {
  const _HonestTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kAmberBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: _kAmberFg, size: 18),
              const SizedBox(width: 8),
              Text(
                'Profile Tip',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kAmberFg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A clear photo, an accurate service area, and a detailed bio help '
            'customers pick you with confidence.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: _kAmberFg,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RIGHT PANEL: provider details form
// ═══════════════════════════════════════════════════════════════════════════

class _RightPanel extends ConsumerWidget {
  const _RightPanel({
    required this.user,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.serviceAreaCtrl,
    required this.experienceCtrl,
    required this.bioCtrl,
    required this.city,
    required this.onCityChanged,
    required this.onDiscard,
    required this.onSave,
    required this.dirty,
  });

  final UserModel user;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController serviceAreaCtrl;
  final TextEditingController experienceCtrl;
  final TextEditingController bioCtrl;
  final String? city;
  final ValueChanged<String?> onCityChanged;
  final VoidCallback onDiscard;
  final VoidCallback onSave;
  final bool dirty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final busy = authState.isLoading;
    final width = MediaQuery.sizeOf(context).width;
    final gridTwoCol = width >= 900;

    Widget pair(Widget a, Widget b) {
      if (gridTwoCol) {
        return Row(
          children: [
            Expanded(child: a),
            const SizedBox(width: 14),
            Expanded(child: b),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [a, const SizedBox(height: 14), b],
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Provider Details',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Update your public profile and contact information.',
            style: GoogleFonts.inter(fontSize: 13, color: _kMuted),
          ),
          const SizedBox(height: 20),

          // Row 1: Name + Phone
          pair(
            _LabeledField(
              label: 'Full Name',
              child: _TextFld(
                controller: nameCtrl,
                hint: 'Your full name',
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.length < 2) return 'Name must be at least 2 characters';
                  return null;
                },
              ),
            ),
            _LabeledField(
              label: 'Phone Number',
              child: _TextFld(
                controller: phoneCtrl,
                hint: '+92 300 0000000',
                keyboard: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Row 2: Email (read-only) + City
          pair(
            _LabeledField(
              label: 'Email Address',
              helper:
                  'Email is managed by your account — contact support to change.',
              child: _ReadOnlyFld(value: user.email),
            ),
            _LabeledField(
              label: 'Primary City',
              child: _CityDropdown(value: city, onChanged: onCityChanged),
            ),
          ),
          const SizedBox(height: 14),

          // Row 3: Service Area + Experience
          pair(
            _LabeledField(
              label: 'Service Area (km)',
              child: _TextFld(
                controller: serviceAreaCtrl,
                hint: 'e.g. 15',
                suffix: 'KM',
                keyboard: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),
            _LabeledField(
              label: 'Years of Experience',
              child: _TextFld(
                controller: experienceCtrl,
                hint: '0–60',
                keyboard: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  final n = int.tryParse(t);
                  if (n == null || n < 0 || n > 60) return '0–60';
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Bio
          _LabeledField(
            label: 'Professional Bio',
            child: _BioFld(controller: bioCtrl),
          ),
          const SizedBox(height: 22),

          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 16),

          // Footer actions
          Row(
            children: [
              const Icon(Icons.info_outline, color: _kPrimary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Changes are visible to customers immediately.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: _kMuted),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: (busy || !dirty) ? null : onDiscard,
                child: Text(
                  'Discard',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: dirty ? _kMuted : _kMuted.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    disabledBackgroundColor: _kPrimary.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: (busy || !dirty) ? null : onSave,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.2),
                        )
                      : Text(
                          'Update Profile',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
}

// ═══════════════════════════════════════════════════════════════════════════
// FORM PRIMITIVES
// ═══════════════════════════════════════════════════════════════════════════

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child, this.helper});
  final String label;
  final Widget child;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _kInk,
          ),
        ),
        const SizedBox(height: 6),
        child,
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: GoogleFonts.inter(fontSize: 11.5, color: _kMuted),
          ),
        ],
      ],
    );
  }
}

class _TextFld extends StatelessWidget {
  const _TextFld({
    required this.controller,
    this.hint,
    this.suffix,
    this.keyboard,
    this.validator,
    this.inputFormatters,
  });
  final TextEditingController controller;
  final String? hint;
  final String? suffix;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: _kInk),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: _kMuted),
        filled: true,
        fillColor: _kField,
        suffixText: suffix,
        suffixStyle: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: _kMuted,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kRedFg, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kRedFg, width: 1.5),
        ),
      ),
    );
  }
}

class _ReadOnlyFld extends StatelessWidget {
  const _ReadOnlyFld({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _kField,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 14, color: _kInk),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.lock_outline, size: 16, color: _kMuted),
        ],
      ),
    );
  }
}

class _CityDropdown extends StatelessWidget {
  const _CityDropdown({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kField,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            'Select city',
            style: GoogleFonts.inter(fontSize: 14, color: _kMuted),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: _kMuted),
          style: GoogleFonts.inter(fontSize: 14, color: _kInk),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
          items: _kCities
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BioFld extends StatefulWidget {
  const _BioFld({required this.controller});
  final TextEditingController controller;

  @override
  State<_BioFld> createState() => _BioFldState();
}

class _BioFldState extends State<_BioFld> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final len = widget.controller.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          controller: widget.controller,
          maxLines: 5,
          maxLength: 500,
          buildCounter: (_,
                  {required currentLength, required isFocused, maxLength}) =>
              null,
          style: GoogleFonts.inter(fontSize: 14, color: _kInk, height: 1.5),
          decoration: InputDecoration(
            hintText:
                'Share your specialties, certifications, and service philosophy...',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: _kMuted),
            filled: true,
            fillColor: _kField,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$len / 500',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: len > 500 ? _kRedFg : _kMuted,
          ),
        ),
      ],
    );
  }
}
