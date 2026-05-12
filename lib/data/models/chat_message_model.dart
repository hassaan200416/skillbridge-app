// Chat message data used by the SkillBot assistant.
// Each object stores one message bubble from either the user or the bot.
// The model is immutable so the chat history can be updated safely in Riverpod.

class ChatMessageModel {
  // One chat bubble in the conversation timeline.
  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  final String id;
  final String content;
  // True for user messages, false for assistant replies.
  final bool isUser;
  final DateTime timestamp;

  // Creates a copy with selected fields replaced.
  ChatMessageModel copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    // Short preview for debug logs and diagnostics.
    final end = content.length < 40 ? content.length : 40;
    return 'ChatMessageModel(id: $id, isUser: $isUser, content: ${content.substring(0, end)}...)';
  }
}
