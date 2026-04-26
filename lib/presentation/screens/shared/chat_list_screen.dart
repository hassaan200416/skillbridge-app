// ---------------------------------------------------------------------------
// chat_list_screen.dart
//
// Purpose: Lists all chat conversations for customer/provider.
// Inside shell — no Scaffold wrapper.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/chat_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

const _kPrimary = Color(0xFF2D9B6F);
const _kSecondary = Color(0xFF1A2B3C);
const _kMuted = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kInk = Color(0xFF0F172A);

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final convosAsync = ref.watch(conversationsProvider(user.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: _kPrimary, size: 28),
              const SizedBox(width: 10),
              Text(
                'Messages',
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
            'Your conversations with service providers and customers.',
            style: GoogleFonts.inter(fontSize: 14, color: _kMuted),
          ),
          const SizedBox(height: 24),
          convosAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: CircularProgressIndicator(color: _kPrimary),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Text(
                  'Failed to load conversations',
                  style: GoogleFonts.inter(color: _kMuted),
                ),
              ),
            ),
            data: (convos) {
              if (convos.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _kMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a conversation from a service page.',
                          style:
                              GoogleFonts.inter(fontSize: 14, color: _kMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: convos
                    .map((c) => _ConvoTile(
                          conversation: c,
                          currentUserId: user.id,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConvoTile extends StatelessWidget {
  const _ConvoTile({
    required this.conversation,
    required this.currentUserId,
  });

  final ConversationModel conversation;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final name = conversation.otherPartyName(currentUserId);
    final avatar = conversation.otherPartyAvatar(currentUserId);
    final lastMsg = conversation.lastMessage ?? 'No messages yet';
    final time = conversation.lastMessageAt;
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/chat/${conversation.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _kPrimary.withValues(alpha: 0.12),
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        initials,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMsg,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _kMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (time != null)
                Text(
                  _relTime(time),
                  style: GoogleFonts.inter(fontSize: 11, color: _kMuted),
                ),
              const SizedBox(width: 4),
              _DeleteConvoBtn(
                conversationId: conversation.id,
                currentUserId: currentUserId,
              ),
              const Icon(Icons.chevron_right, size: 20, color: _kMuted),
            ],
          ),
        ),
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
}

class _DeleteConvoBtn extends ConsumerWidget {
  const _DeleteConvoBtn({
    required this.conversationId,
    required this.currentUserId,
  });

  final String conversationId;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Delete conversation',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            content: Text(
                'This will permanently delete this conversation and all messages.',
                style: GoogleFonts.inter(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.inter(color: _kMuted)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ChatRepository.instance
                        .deleteConversation(conversationId);
                    ref.invalidate(conversationsProvider(currentUserId));
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Failed to delete: $e'),
                        backgroundColor: Colors.red.shade700,
                      ));
                    }
                  }
                },
                child: Text('Delete',
                    style: GoogleFonts.inter(
                        color: Colors.red, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
      icon:
          const Icon(Icons.delete_outline, size: 18, color: Color(0xFF991B1B)),
      splashRadius: 18,
      tooltip: 'Delete conversation',
    );
  }
}
