// skillbot_provider.dart
// Riverpod state management for the SkillBot AI assistant.
// Manages conversation history, calls AiService with a SkillBridge
// system prompt, and exposes loading + message state to the widget layer.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_message_model.dart';
import '../../data/models/user_model.dart';
import '../../services/ai_service.dart';
import 'auth_providers.dart'; // for optional user context

final geminiServiceProvider = Provider<AiService>(
  (ref) => AiService.instance,
);

// ─────────────────────────────────────────────
// State model
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────

class SkillBotNotifier extends Notifier<SkillBotState> {
  static const String _systemPrompt = '''
You are SkillBot, the friendly AI assistant for SkillBridge — a local services marketplace app.

Your role:
- Help users find the right service providers (plumbers, electricians, cleaners, etc.)
- Explain how bookings, payments, and reviews work in the app
- Answer questions about provider profiles, ratings, and cancellations
- Guide new users through the app's features
- Give helpful, concise answers — max 3 short paragraphs

Tone: Friendly, helpful, and concise. Use simple language. Avoid jargon.

App facts:
- Users can browse and book local service providers
- Providers set their own availability and pricing
- Bookings go through: Pending → Accepted → Completed
- Customers can leave star ratings and written reviews after completion
- Both customers and providers get in-app notifications
- Support: help@skillbridge.app

Do NOT invent prices, provider names, or availability information.
If you don't know something specific to the user's account, tell them to check the app directly.
''';

  @override
  SkillBotState build() => const SkillBotState();

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    // 1. Add user message immediately
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

    // 2. Build conversation history for Gemini multi-turn
    final history = state.messages
        .where((m) => m.id != userMsg.id)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'parts': [m.content],
            })
        .toList();

    try {
      final currentUser = ref.read(currentUserProvider);
      final contextualPrompt = currentUser == null
          ? _systemPrompt
          : '$_systemPrompt\n\nCurrent user role: ${currentUser.role.value}\nCurrent user name: ${currentUser.name}';
      final geminiService = ref.read(geminiServiceProvider);
      final response = await geminiService.sendChatMessage(
        systemPrompt: contextualPrompt,
        history: history,
        userMessage: userText.trim(),
      );

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
      final errorMsg = ChatMessageModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_err',
        content:
            "Sorry, I couldn't connect right now. Please check your internet connection and try again. 🔌",
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
    state = const SkillBotState();
  }
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

final skillBotNotifierProvider =
    NotifierProvider<SkillBotNotifier, SkillBotState>(
  SkillBotNotifier.new,
);

