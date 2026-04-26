// ---------------------------------------------------------------------------
// chat_provider.dart
//
// Purpose: Riverpod providers for chat feature.
//
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_model.dart';
import '../../data/repositories/chat_repository.dart';

/// All conversations for a user
final conversationsProvider =
    FutureProvider.family<List<ConversationModel>, String>((ref, userId) {
  return ChatRepository.instance.getConversations(userId);
});

/// Messages for a conversation
final messagesProvider =
    FutureProvider.family<List<MessageModel>, String>((ref, conversationId) {
  return ChatRepository.instance.getMessages(conversationId);
});

/// Unread chat count for bell badge
final unreadChatCountProvider =
    FutureProvider.family<int, String>((ref, userId) {
  return ChatRepository.instance.getUnreadCount(userId);
});

/// Single conversation by ID
final conversationDetailProvider =
    FutureProvider.family<ConversationModel?, String>((ref, conversationId) {
  return ChatRepository.instance.getConversationById(conversationId);
});
