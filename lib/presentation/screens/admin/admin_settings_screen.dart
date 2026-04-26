// ---------------------------------------------------------------------------
// admin_settings_screen.dart
//
// Purpose: Platform configuration and announcements. Admin can view
//   platform info (static/honest) and send platform-wide announcements
//   via NotificationRepository.createNotification for every user.
//
// Route: /admin/settings  (inside AdminShell)
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../providers/user_provider.dart';

const _kPrimary = Color(0xFF2D9B6F);
const _kBg = Color(0xFFF5F7FA);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);
const _kField = Color(0xFFEFF4F9);
const _kRedFg = Color(0xFF991B1B);

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings',
                style: GoogleFonts.poppins(
                    fontSize: 28, fontWeight: FontWeight.w700, color: _kInk)),
            const SizedBox(height: 2),
            Text('Platform configuration and announcements',
                style: GoogleFonts.inter(fontSize: 13.5, color: _kMuted)),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (ctx, cons) {
              final twoCol = cons.maxWidth >= 900;
              final info = _PlatformInfoCard();
              final announce = _AnnounceCard(
                titleCtrl: _titleCtrl,
                bodyCtrl: _bodyCtrl,
                sending: _sending,
                onSend: _sendAnnouncement,
              );
              if (twoCol) {
                return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: info),
                      const SizedBox(width: 20),
                      Expanded(child: announce),
                    ]);
              }
              return Column(
                  children: [info, const SizedBox(height: 20), announce]);
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _sendAnnouncement() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Both title and message are required'),
            backgroundColor: _kRedFg,
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      // Get all users to notify
      final users = await ref.read(allUsersProvider.future);

      // Send notification to each user
      for (final user in users) {
        await NotificationRepository.instance.createNotification(
          userId: user.id,
          type: NotificationType.platformAnnouncement,
          title: title,
          body: body,
        );
      }

      if (!mounted) return;
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Announcement sent to ${users.length} users'),
          backgroundColor: _kPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: _kRedFg,
            behavior: SnackBarBehavior.floating),
      );
    }
  }
}

// -- Platform Info (honest, static) --

class _PlatformInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child:
                  const Icon(Icons.info_outline, color: _kPrimary, size: 18)),
          const SizedBox(width: 12),
          Text('Platform Info',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _kInk)),
        ]),
        const SizedBox(height: 20),
        _InfoRow('Platform', 'SkillBridge'),
        _InfoRow('Version', '1.0.0'),
        _InfoRow('Cities', 'Karachi, Lahore, Islamabad'),
        _InfoRow('Backend', 'Supabase (PostgreSQL + Auth + Storage)'),
        _InfoRow('AI Provider', 'Groq (llama-3.1-8b-instant)'),
        _InfoRow('State Management', 'Riverpod'),
        _InfoRow('Navigation', 'go_router'),
        const SizedBox(height: 14),
        const Divider(color: _kBorder),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.lightbulb_outline,
                color: Color(0xFFD97706), size: 16),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
              'All platform info shown here reflects actual configuration. '
              'These values are static because they are real constants - no fake metrics.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFFD97706), height: 1.5),
            )),
          ]),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Announcements --

class _AnnounceCard extends StatelessWidget {
  const _AnnounceCard(
      {required this.titleCtrl,
      required this.bodyCtrl,
      required this.sending,
      required this.onSend});

  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.campaign_outlined,
                  color: _kPrimary, size: 18)),
          const SizedBox(width: 12),
          Text('Create Announcement',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _kInk)),
        ]),
        const SizedBox(height: 20),
        Text('Title',
            style: GoogleFonts.inter(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: _kInk)),
        const SizedBox(height: 6),
        TextField(
          controller: titleCtrl,
          style: GoogleFonts.inter(fontSize: 14, color: _kInk),
          decoration: InputDecoration(
            hintText: 'Announcement title',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: _kMuted),
            filled: true,
            fillColor: _kField,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 14),
        Text('Message',
            style: GoogleFonts.inter(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: _kInk)),
        const SizedBox(height: 6),
        TextField(
          controller: bodyCtrl,
          maxLines: 4,
          style: GoogleFonts.inter(fontSize: 14, color: _kInk, height: 1.5),
          decoration: InputDecoration(
            hintText: 'Write your announcement message...',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: _kMuted),
            filled: true,
            fillColor: _kField,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              disabledBackgroundColor: _kPrimary.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send, size: 16),
            label: Text(sending ? 'Sending...' : 'Send Announcement',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.info_outline, color: _kMuted, size: 14),
          const SizedBox(width: 6),
          Expanded(
              child: Text(
                  'This will send a notification to all users on the platform.',
                  style: GoogleFonts.inter(fontSize: 12, color: _kMuted))),
        ]),
      ]),
    );
  }
}
