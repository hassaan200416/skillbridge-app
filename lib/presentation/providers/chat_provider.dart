// Chat providers for conversations, messages, and unread counts.
// These providers keep the chat UI simple by hiding the repository calls and
// giving screens direct access to the conversation list, one conversation,
// message history, and unread badge count.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_model.dart';
import '../../data/repositories/chat_repository.dart';

/// All conversations for a user.
final conversationsProvider =
    FutureProvider.family<List<ConversationModel>, String>((ref, userId) {
  return ChatRepository.instance.getConversations(userId);
});

/// Messages for one conversation.
final messagesProvider =
    FutureProvider.family<List<MessageModel>, String>((ref, conversationId) {
  return ChatRepository.instance.getMessages(conversationId);
});

/// Unread chat count used by the bell badge.
final unreadChatCountProvider =
    FutureProvider.family<int, String>((ref, userId) {
  return ChatRepository.instance.getUnreadCount(userId);
});

/// A single conversation loaded by ID.
final conversationDetailProvider =
    FutureProvider.family<ConversationModel?, String>((ref, conversationId) {
  return ChatRepository.instance.getConversationById(conversationId);
});
