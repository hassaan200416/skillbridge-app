// ---------------------------------------------------------------------------
// chat_detail_screen.dart
//
// Purpose: Chat conversation view with message bubbles and input.
// Standalone screen with own Scaffold + AppSidebar + AppTopBar.
//
// ---------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/chat_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/app_top_bar.dart';

const _kPrimary = Color(0xFF2D9B6F);
const _kSecondary = Color(0xFF1A2B3C);
const _kMuted = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kInk = Color(0xFF0F172A);
const _kBg = Color(0xFFF5F7FA);

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<MessageModel> _messages = [];
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToRealtime();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs =
          await ChatRepository.instance.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() => _messages = msgs);
      _scrollToBottom();

      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ChatRepository.instance.markMessagesAsRead(
          conversationId: widget.conversationId,
          currentUserId: user.id,
        );
      }
    } catch (_) {}
  }

  void _subscribeToRealtime() {
    _subscription = ChatRepository.instance
        .watchMessages(widget.conversationId)
        .listen((data) {
      if (!mounted) return;
      setState(() {
        _messages = data
            .map((json) =>
                MessageModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      });
      _scrollToBottom();

      final user = ref.read(currentUserProvider);
      if (user != null) {
        ChatRepository.instance.markMessagesAsRead(
          conversationId: widget.conversationId,
          currentUserId: user.id,
        );
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _sending) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _sending = true);
    _msgController.clear();

    try {
      await ChatRepository.instance.sendMessage(
        conversationId: widget.conversationId,
        senderId: user.id,
        content: text,
      );
      ref.invalidate(conversationsProvider(user.id));
      ref.invalidate(messagesProvider(widget.conversationId));
    } catch (_) {}

    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final showSidebar = screenWidth >= 800;

    return Scaffold(
      backgroundColor: _kBg,
      body: Row(
        children: [
          if (showSidebar)
            AppSidebar(
              role: user.role,
              currentRoute: '/chat/${widget.conversationId}',
            ),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(),
                Consumer(
                  builder: (context, ref, _) {
                    final convoAsync = ref.watch(
                        conversationDetailProvider(widget.conversationId));
                    final otherName = convoAsync.whenOrNull(
                          data: (c) => c?.otherPartyName(user.id),
                        ) ??
                        'Chat';
                    final otherAvatar = convoAsync.whenOrNull(
                      data: (c) => c?.otherPartyAvatar(user.id),
                    );
                    final initials = otherName.isNotEmpty
                        ? otherName
                            .split(' ')
                            .map((w) => w.isNotEmpty ? w[0] : '')
                            .take(2)
                            .join()
                            .toUpperCase()
                        : '?';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: _kBorder)),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              final chatRoute = user.role == UserRole.customer
                                  ? '/chats'
                                  : '/p/chats';
                              context.go(chatRoute);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.arrow_back,
                                  size: 20, color: _kSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: _kPrimary.withValues(alpha: 0.12),
                            backgroundImage: otherAvatar != null
                                ? NetworkImage(otherAvatar)
                                : null,
                            child: otherAvatar == null
                                ? Text(
                                    initials,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              otherName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _kSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Delete conversation',
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                  content: Text(
                                      'This will permanently delete this conversation and all messages.',
                                      style: GoogleFonts.inter(fontSize: 14)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text('Cancel',
                                          style: GoogleFonts.inter(
                                              color: _kMuted)),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        try {
                                          await ChatRepository.instance
                                              .deleteConversation(
                                                  widget.conversationId);
                                          ref.invalidate(
                                              conversationsProvider(user.id));
                                          if (context.mounted) {
                                            final chatRoute =
                                                user.role == UserRole.customer
                                                    ? '/chats'
                                                    : '/p/chats';
                                            context.go(chatRoute);
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content:
                                                  Text('Failed to delete: $e'),
                                              backgroundColor:
                                                  Colors.red.shade700,
                                            ));
                                          }
                                        }
                                      },
                                      child: Text('Delete',
                                          style: GoogleFonts.inter(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_outline,
                                size: 20, color: Color(0xFF991B1B)),
                            tooltip: 'Delete conversation',
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'No messages yet',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _kMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Send a message to start the conversation.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _kMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => _MessageBubble(
                            message: _messages[i],
                            isMe: _messages[i].senderId == user.id,
                          ),
                        ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          style: GoogleFonts.inter(fontSize: 14, color: _kInk),
                          maxLines: 3,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle:
                                GoogleFonts.inter(fontSize: 14, color: _kMuted),
                            filled: true,
                            fillColor: _kBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _kBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _kBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: _kPrimary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: _sending ? null : _send,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send,
                                  size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final MessageModel message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (isMe) const Spacer(flex: 2),
          Flexible(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? _kPrimary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.content,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isMe ? Colors.white : _kInk,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(message.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color:
                          isMe ? Colors.white.withValues(alpha: 0.7) : _kMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isMe) const Spacer(flex: 2),
        ],
      ),
    );
  }
}
