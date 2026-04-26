// chat_message_model.dart
// Immutable model representing a single SkillBot chat message.
// Used by skillbot_provider.dart and rendered by skillbot_widget.dart.

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  final String id;
  final String content;
  final bool isUser; // true = user bubble, false = bot bubble
  final DateTime timestamp;

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
    final end = content.length < 40 ? content.length : 40;
    return 'ChatMessageModel(id: $id, isUser: $isUser, content: ${content.substring(0, end)}...)';
  }
}
