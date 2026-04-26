// ---------------------------------------------------------------------------
// chat_repository.dart
//
// Purpose: Chat system CRUD — conversations and messages.
//
// ---------------------------------------------------------------------------

import '../../core/errors/failures.dart';
import '../../services/supabase_service.dart';
import '../models/chat_model.dart';

class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  final _supabase = SupabaseService.instance;

  // ── Conversations ─────────────────────────────────────────────────────

  /// Get all conversations for a user (customer or provider)
  Future<List<ConversationModel>> getConversations(String userId) async {
    try {
      final data = await _supabase
          .from('conversations')
          .select('''
            *,
            customer:users!customer_id(name, avatar_url),
            provider:users!provider_id(name, avatar_url)
          ''')
          .or('customer_id.eq.$userId,provider_id.eq.$userId')
          .order('last_message_at', ascending: false, nullsFirst: false);

      return (data as List<dynamic>)
          .map((json) => ConversationModel.fromJson(
              Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch conversations: $e');
    }
  }

  /// Get or create a conversation between customer and provider
  Future<ConversationModel> getOrCreateConversation({
    required String customerId,
    required String providerId,
    String? serviceId,
  }) async {
    try {
      // Check if conversation already exists
      final existing = await _supabase
          .from('conversations')
          .select('''
            *,
            customer:users!customer_id(name, avatar_url),
            provider:users!provider_id(name, avatar_url)
          ''')
          .eq('customer_id', customerId)
          .eq('provider_id', providerId)
          .maybeSingle();

      if (existing != null) {
        return ConversationModel.fromJson(
            Map<String, dynamic>.from(existing as Map));
      }

      // Create new conversation
      final inserted = await _supabase.from('conversations').insert({
        'customer_id': customerId,
        'provider_id': providerId,
        'service_id': serviceId,
      }).select('''
            *,
            customer:users!customer_id(name, avatar_url),
            provider:users!provider_id(name, avatar_url)
          ''').single();

      return ConversationModel.fromJson(
          Map<String, dynamic>.from(inserted as Map));
    } catch (e) {
      throw ServerFailure('Failed to get/create conversation: $e');
    }
  }

  /// Get a single conversation by ID with joined user data
  Future<ConversationModel?> getConversationById(String conversationId) async {
    try {
      final data = await _supabase.from('conversations').select('''
            *,
            customer:users!customer_id(name, avatar_url),
            provider:users!provider_id(name, avatar_url)
          ''').eq('id', conversationId).maybeSingle();

      if (data == null) return null;
      return ConversationModel.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      throw ServerFailure('Failed to fetch conversation: $e');
    }
  }

  /// Delete a conversation and all its messages (CASCADE)
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _supabase.from('conversations').delete().eq('id', conversationId);
    } catch (e) {
      throw ServerFailure('Failed to delete conversation: $e');
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────

  /// Get messages for a conversation
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
    int page = 0,
  }) async {
    try {
      final data = await _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .range(page * limit, (page + 1) * limit - 1);

      return (data as List<dynamic>)
          .map((json) =>
              MessageModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch messages: $e');
    }
  }

  /// Send a message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    try {
      final data = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'content': content,
          })
          .select()
          .single();

      return MessageModel.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (e) {
      throw ServerFailure('Failed to send message: $e');
    }
  }

  /// Mark all messages in a conversation as read (for the other party)
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String currentUserId,
  }) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);
    } catch (_) {
      // Non-critical
    }
  }

  /// Get unread message count across all conversations
  Future<int> getUnreadCount(String userId) async {
    try {
      // Get all conversation IDs for this user
      final convos = await _supabase
          .from('conversations')
          .select('id')
          .or('customer_id.eq.$userId,provider_id.eq.$userId');

      final convoIds =
          (convos as List<dynamic>).map((c) => c['id'] as String).toList();

      if (convoIds.isEmpty) return 0;

      final data = await _supabase
          .from('messages')
          .select('id')
          .inFilter('conversation_id', convoIds)
          .neq('sender_id', userId)
          .eq('is_read', false);

      return (data as List<dynamic>).length;
    } catch (_) {
      return 0;
    }
  }

  /// Real-time stream for messages in a conversation
  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) {
    return _supabase.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }
}
