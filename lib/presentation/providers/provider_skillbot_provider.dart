// Provider SkillBot state and actions.
// This file powers the floating assistant used on provider screens.
// It mirrors the customer SkillBot provider but uses provider-focused help
// text and conversation history.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_message_model.dart';
import 'skillbot_provider.dart';

class ProviderSkillBotState {
  // Current provider chat transcript plus loading and error flags.
  const ProviderSkillBotState({
    this.messages = const [],
    this.isTyping = false,
    this.error,
  });

  final List<ChatMessageModel> messages;
  final bool isTyping;
  final String? error;

  ProviderSkillBotState copyWith({
    List<ChatMessageModel>? messages,
    bool? isTyping,
    String? error,
  }) {
    return ProviderSkillBotState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error: error,
    );
  }
}

class ProviderSkillBotNotifier extends Notifier<ProviderSkillBotState> {
  // Short prompt that keeps the assistant focused on provider workflows.
  static const String _systemPrompt = '''
You are SkillBot for service providers on SkillBridge.
Help providers with:
- accepting/rejecting/completing bookings
- managing service listings, pricing, and photos
- understanding earnings and ratings
- account/profile and availability settings

Be concise, practical, and action-oriented.
Do not invent account-specific data; tell providers to check dashboard values when needed.
''';

  @override
  ProviderSkillBotState build() => const ProviderSkillBotState();

  // Sends a provider message, waits for the AI answer, and updates state.
  // Sends a message, waits for the AI response, and updates the chat state.
  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    // Add the provider message to the conversation immediately.
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

    // Send the previous messages in a simple role/content format.
    final history = state.messages
        .where((m) => m.id != userMsg.id)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'parts': [m.content],
            })
        .toList();

    try {
      final geminiService = ref.read(geminiServiceProvider);
      final response = await geminiService.sendChatMessage(
        systemPrompt: _systemPrompt,
        history: history,
        userMessage: userText.trim(),
      );

      // Append the AI response as a provider-side helper message.
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
      // Show the same friendly fallback when the request fails.
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
    // Reset the whole conversation.
    state = const ProviderSkillBotState();
  }
}

// Riverpod provider for the provider-facing assistant.
final providerSkillBotNotifierProvider =
    NotifierProvider<ProviderSkillBotNotifier, ProviderSkillBotState>(
  ProviderSkillBotNotifier.new,
);
