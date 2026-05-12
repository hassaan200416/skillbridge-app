// Customer SkillBot state and actions.
// This provider keeps the chat messages, typing state, and error text for the
// floating help assistant shown in customer screens.
//
// The provider stays thin on purpose: message scoping, AI reply generation,
// and safety checks all live inside AiService.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_message_model.dart';
import '../../services/ai_service.dart';
import 'auth_providers.dart';

final geminiServiceProvider = Provider<AiService>(
  (ref) => AiService.instance,
);

// Chat state model.
// Holds the current conversation and the UI flags that control the chat box.

class SkillBotState {
  const SkillBotState({
    this.messages = const [],
    this.isTyping = false,
    this.error,
  });

  final List<ChatMessageModel> messages;
  final bool isTyping;
  final String? error;

  SkillBotState copyWith({
    List<ChatMessageModel>? messages,
    bool? isTyping,
    String? error,
  }) {
    return SkillBotState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error: error,
    );
  }
}

// Chat controller.
// Adds the user message immediately, requests the AI reply, and appends the
// response or fallback error message to the conversation.

class SkillBotNotifier extends Notifier<SkillBotState> {
  @override
  SkillBotState build() => const SkillBotState();

  // Sends one customer message, waits for the AI answer, and updates state.
  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    // Add the user message first so the UI feels instant.
    final userMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: userText.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
      error: null,
    );

    // Build the history sent to the AI, excluding the new message because it
    // is passed separately as the latest user input.
    final history = state.messages
        .where((m) => m.id != userMsg.id)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    try {
      // The current user role lets AiService tailor the answer a little.
      final currentUser = ref.read(currentUserProvider);
      final userRole = currentUser?.role.name ?? 'customer';
      // Ask AiService for a scoped SkillBridge reply.
      final aiService = ref.read(geminiServiceProvider);
      final response = await aiService.sendSkillBotMessage(
        userMessage: userText.trim(),
        conversationHistory: history
            .map((m) => {
                  'role': m['role']!.toString(),
                  'content': m['content']!.toString(),
                })
            .toList(),
        userRole: userRole,
      );

      // Append the AI response as a bot message.
      final botMsg = ChatMessageModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_bot',
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, botMsg],
        isTyping: false,
      );
    } catch (e) {
      // Show a friendly fallback message when the request fails.
      final errorMsg = ChatMessageModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_err',
        content:
            "Sorry, I couldn't connect right now. Please check your internet connection and try again.",
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isTyping: false,
        error: e.toString(),
      );
    }
  }

  void clearChat() {
    // Remove all messages and reset the chat panel.
    state = const SkillBotState();
  }
}

// Riverpod provider.
// Screens read this provider to show the chat and send new messages.

final skillBotNotifierProvider =
    NotifierProvider<SkillBotNotifier, SkillBotState>(
  SkillBotNotifier.new,
);
