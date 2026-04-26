// ---------------------------------------------------------------------------
// announcements_screen.dart
//
// Purpose: Displays platform announcements for customer/provider.
// Users can dismiss announcements from their view.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  static const _kPrimary = Color(0xFF2D9B6F);
  static const _kSecondary = Color(0xFF1A2B3C);
  static const _kMuted = Color(0xFF64748B);
  static const _kBorder = Color(0xFFE2E8F0);
  static const _kInk = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final announcementsAsync = ref.watch(announcementsProvider(user.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: _kPrimary, size: 28),
              const SizedBox(width: 10),
              Text(
                'Announcements',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _kSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Platform updates and important notices from SkillBridge.',
            style: GoogleFonts.inter(fontSize: 14, color: _kMuted),
          ),
          const SizedBox(height: 24),
          announcementsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: CircularProgressIndicator(color: _kPrimary),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Text('Failed to load announcements',
                    style: GoogleFonts.inter(color: _kMuted)),
              ),
            ),
            data: (announcements) {
              if (announcements.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No announcements',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _kMuted,
                            )),
                        const SizedBox(height: 8),
                        Text("You're all caught up!",
                            style: GoogleFonts.inter(
                                fontSize: 14, color: _kMuted)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: announcements.map((a) {
                  final title = a['title'] as String? ?? 'Announcement';
                  final body =
                      a['message'] as String? ?? a['body'] as String? ?? '';
                  final createdAt =
                      DateTime.tryParse(a['created_at'] as String? ?? '') ??
                          DateTime.now();
                  final id = a['id'] as String;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.campaign,
                                    size: 20, color: Color(0xFFFF9800)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _kInk,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMMM d, yyyy · h:mm a')
                                          .format(createdAt),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: _kMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Dismiss button
                              IconButton(
                                onPressed: () async {
                                  await NotificationRepository.instance
                                      .dismissAnnouncement(
                                    userId: user.id,
                                    announcementId: id,
                                  );
                                  ref.invalidate(
                                      announcementsProvider(user.id));
                                },
                                icon: const Icon(Icons.close,
                                    size: 18, color: _kMuted),
                                tooltip: 'Dismiss',
                                splashRadius: 18,
                              ),
                            ],
                          ),
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              body,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _kSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
