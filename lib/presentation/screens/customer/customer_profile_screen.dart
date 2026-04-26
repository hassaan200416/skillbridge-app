// ---------------------------------------------------------------------------
// customer_profile_screen.dart
//
// Purpose: Customer profile edit screen. Two-column layout matching
// provider profile: avatar card + stats on left, editable form on right.
// Supports avatar upload via StorageService.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/booking_model.dart';
import '../../../data/models/user_model.dart';
import '../../../services/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

// ── Design Tokens ───────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF2D9B6F);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);
const _kField = Color(0xFFEFF4F9);
const _kRedFg = Color(0xFF991B1B);

const _kCities = ['Karachi', 'Lahore', 'Islamabad'];

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _city;
  XFile? _pendingAvatar;
  Uint8List? _pendingAvatarBytes;
  bool _seeded = false;
  bool _dirty = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _seedFrom(UserModel u) {
    if (_seeded) return;
    _nameCtrl.text = u.name;
    _phoneCtrl.text = u.phone ?? '';
    _city = _kCities.contains(u.city) ? u.city : null;
    _seeded = true;
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    _seedFrom(user);
    final bookingsAsync = ref.watch(customerBookingsProvider(user.id));
    final width = MediaQuery.sizeOf(context).width;
    final twoColumn = width >= 1000;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Form(
        key: _formKey,
        onChanged: _markDirty,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('My Profile',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                )),
            const SizedBox(height: 2),
            Text('Manage your personal details',
                style: GoogleFonts.inter(fontSize: 13, color: _kMuted)),
            const SizedBox(height: 24),

            // Two-column layout
            if (twoColumn)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 2,
                        child: _LeftPanel(
                          user: user,
                          pendingAvatarBytes: _pendingAvatarBytes,
                          onPickAvatar: _pickAvatar,
                          bookingsAsync: bookingsAsync,
                        )),
                    const SizedBox(width: 20),
                    Expanded(
                        flex: 3,
                        child: _RightPanel(
                          user: user,
                          nameCtrl: _nameCtrl,
                          phoneCtrl: _phoneCtrl,
                          city: _city,
                          onCityChanged: (v) => setState(() {
                            _city = v;
                            _dirty = true;
                          }),
                          onDiscard: _discard,
                          onSave: _save,
                          dirty: _dirty || _pendingAvatar != null,
                        )),
                  ],
                ),
              )
            else
              Column(
                children: [
                  _LeftPanel(
                    user: user,
                    pendingAvatarBytes: _pendingAvatarBytes,
                    onPickAvatar: _pickAvatar,
                    bookingsAsync: bookingsAsync,
                  ),
                  const SizedBox(height: 20),
                  _RightPanel(
                    user: user,
                    nameCtrl: _nameCtrl,
                    phoneCtrl: _phoneCtrl,
                    city: _city,
                    onCityChanged: (v) => setState(() {
                      _city = v;
                      _dirty = true;
                    }),
                    onDiscard: _discard,
                    onSave: _save,
                    dirty: _dirty || _pendingAvatar != null,
                  ),
                ],
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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

    final success = await ref.read(authNotifierProvider.notifier).updateProfile(
          userId: user.id,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          city: _city,
          newAvatarImage: _pendingAvatar,
        );

    if (!mounted) return;
    if (success) {
      setState(() {
        _pendingAvatar = null;
        _pendingAvatarBytes = null;
        _dirty = false;
        _seeded = false;
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

// ── Left Panel: avatar + stats ──────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    required this.user,
    required this.pendingAvatarBytes,
    required this.onPickAvatar,
    required this.bookingsAsync,
  });
  final UserModel user;
  final Uint8List? pendingAvatarBytes;
  final VoidCallback onPickAvatar;
  final AsyncValue<List<BookingModel>> bookingsAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Avatar card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
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
                offset: const Offset(0, -48),
                child: Column(
                  children: [
                    _AvatarWithCamera(
                      url: user.avatarUrl,
                      pendingBytes: pendingAvatarBytes,
                      name: user.name,
                      onPick: onPickAvatar,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Customer',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Stats
        bookingsAsync.when(
          loading: () => const SizedBox(height: 80),
          error: (_, __) => const SizedBox(height: 80),
          data: (bookings) {
            final completed = bookings
                .where((b) => b.status == BookingStatus.completed)
                .length;
            final pending =
                bookings.where((b) => b.status == BookingStatus.pending).length;
            return Row(
              children: [
                Expanded(
                    child: _StatTile(
                  icon: Icons.event_note,
                  iconColor: const Color(0xFF0369A1),
                  label: 'BOOKINGS',
                  value: '${bookings.length}',
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatTile(
                  icon: Icons.check_circle_rounded,
                  iconColor: _kPrimary,
                  label: 'COMPLETED',
                  value: '$completed',
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatTile(
                  icon: Icons.schedule,
                  iconColor: const Color(0xFFD97706),
                  label: 'PENDING',
                  value: '$pending',
                )),
              ],
            );
          },
        ),

        const SizedBox(height: 14),

        // Tip card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Text('Profile Tip',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD97706),
                      )),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'A profile photo and accurate contact details help providers '
                'reach you faster and build trust.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFFD97706),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Avatar with camera button ───────────────────────────────────────────────

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
          width: 100,
          height: 100,
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
          child: ClipOval(child: _image()),
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
                padding: EdgeInsets.all(7),
                child: Icon(Icons.camera_alt, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _image() {
    if (pendingBytes != null) {
      return Image.memory(pendingBytes!, fit: BoxFit.cover);
    }
    if (url != null && url!.isNotEmpty) {
      return Image.network(url!,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback());
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
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      ),
    );
  }
}

// ── Stat tile ───────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Text(value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _kInk,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: _kMuted,
                letterSpacing: 0.8,
              )),
        ],
      ),
    );
  }
}

// ── Right Panel: form ───────────────────────────────────────────────────────

class _RightPanel extends ConsumerWidget {
  const _RightPanel({
    required this.user,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.city,
    required this.onCityChanged,
    required this.onDiscard,
    required this.onSave,
    required this.dirty,
  });
  final UserModel user;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
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
        return Row(children: [
          Expanded(child: a),
          const SizedBox(width: 14),
          Expanded(child: b),
        ]);
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
          Text('Personal Details',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _kInk,
              )),
          const SizedBox(height: 4),
          Text('Update your personal information.',
              style: GoogleFonts.inter(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 20),

          // Name + Phone
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

          // Email (read-only) + City
          pair(
            _LabeledField(
              label: 'Email Address',
              helper: 'Email is managed by your account.',
              child: _ReadOnlyFld(value: user.email),
            ),
            _LabeledField(
              label: 'City',
              helper: ' ',
              child: _CityDropdown(value: city, onChanged: onCityChanged),
            ),
          ),
          const SizedBox(height: 22),

          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              const Icon(Icons.info_outline, color: _kPrimary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Changes are saved immediately.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: _kMuted),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: (busy || !dirty) ? null : onDiscard,
                child: Text('Discard',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dirty ? _kMuted : _kMuted.withValues(alpha: 0.5),
                    )),
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
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (busy || !dirty) ? null : onSave,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.2),
                        )
                      : Text('Update Profile',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Form primitives ─────────────────────────────────────────────────────────

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
        Text(label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _kInk,
            )),
        const SizedBox(height: 6),
        child,
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(helper!,
              style: GoogleFonts.inter(fontSize: 11.5, color: _kMuted)),
        ],
      ],
    );
  }
}

class _TextFld extends StatelessWidget {
  const _TextFld({
    required this.controller,
    this.hint,
    this.keyboard,
    this.validator,
    this.inputFormatters,
  });
  final TextEditingController controller;
  final String? hint;
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
            child: Text(value,
                style: GoogleFonts.inter(fontSize: 14, color: _kInk),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
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
          hint: Text('Select city',
              style: GoogleFonts.inter(fontSize: 14, color: _kMuted)),
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
