// ---------------------------------------------------------------------------
// chat_model.dart
//
// Purpose: Data models for the chat system.
//
// ---------------------------------------------------------------------------

class ConversationModel {
  final String id;
  final String customerId;
  final String providerId;
  final String? serviceId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  // Joined fields
  final String? customerName;
  final String? customerAvatar;
  final String? providerName;
  final String? providerAvatar;

  const ConversationModel({
    required this.id,
    required this.customerId,
    required this.providerId,
    this.serviceId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.customerName,
    this.customerAvatar,
    this.providerName,
    this.providerAvatar,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final provider = json['provider'] as Map<String, dynamic>?;

    return ConversationModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      providerId: json['provider_id'] as String,
      serviceId: json['service_id'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      customerName: customer?['name'] as String?,
      customerAvatar: customer?['avatar_url'] as String?,
      providerName: provider?['name'] as String?,
      providerAvatar: provider?['avatar_url'] as String?,
    );
  }

  /// Returns the other party's name based on current user ID
  String otherPartyName(String currentUserId) {
    if (currentUserId == customerId) return providerName ?? 'Provider';
    return customerName ?? 'Customer';
  }

  /// Returns the other party's avatar based on current user ID
  String? otherPartyAvatar(String currentUserId) {
    if (currentUserId == customerId) return providerAvatar;
    return customerAvatar;
  }

  /// Returns the other party's ID
  String otherPartyId(String currentUserId) {
    if (currentUserId == customerId) return providerId;
    return customerId;
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
