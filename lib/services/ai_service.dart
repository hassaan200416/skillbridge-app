
// ---------------------------------------------------------------------------
// ai_service.dart
//
// Purpose: Singleton service for AI features (smart search, summaries, bots).
// Uses Groq's OpenAI-compatible Chat Completions API (llama-3.1-8b-instant).
//
// Responsibilities:
//   - AI Smart Search: extract category and price from natural language
//   - Review Summarizer: generate and cache summaries
//   - SkillBot: contextual platform assistant
//
// All AI calls are gated — if Groq is unavailable, the app degrades
// gracefully. AI enhances the app but is never a hard dependency.
//
// ---------------------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Result from AI smart search extraction
class SearchExtraction {
  /// Extracted category slug (e.g. 'plumber', 'electrician') or null
  final String? category;

  /// Extracted maximum price or null
  final double? maxPrice;

  /// Cleaned search query for text search
  final String cleanQuery;

  const SearchExtraction({
    this.category,
    this.maxPrice,
    required this.cleanQuery,
  });
}

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  bool _initialized = false;

  // Valid categories for extraction
  static const List<String> _validCategories = [
    'home_repair', 'tutoring', 'cleaning', 'electrician',
    'plumber', 'mechanic', 'beauty', 'graphic_design', 'moving', 'other',
  ];

  static const _groqUri =
      'https://api.groq.com/openai/v1/chat/completions';
  static const _groqModel = 'llama-3.1-8b-instant';

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Initialize AI features. Requires [GROQ_API_KEY] in `.env`.
  void initialize() {
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return;
      }
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  bool get isAvailable => _initialized;

  // ── Groq HTTP ──────────────────────────────────────────────────────────────

  Future<String> _groqRequest(
    List<Map<String, dynamic>> messages, {
    double temperature = 0.6,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception(
        'GROQ_API_KEY is missing or empty. Add it to .env and restart the app.',
      );
    }

    final uri = Uri.parse(_groqUri);
    final body = jsonEncode({
      'model': _groqModel,
      'messages': messages,
      'temperature': temperature,
    });

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final snippet = response.body.length > 800
          ? '${response.body.substring(0, 800)}…'
          : response.body;
      throw Exception(
        'Groq API HTTP ${response.statusCode}: $snippet',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Groq API returned JSON that is not an object.');
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw Exception(
        'Groq API response missing or empty "choices" array.',
      );
    }

    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw Exception('Groq API "choices[0]" is not an object.');
    }

    final msg = first['message'];
    if (msg is! Map<String, dynamic>) {
      throw Exception('Groq API response missing choices[0].message.');
    }

    final text = msg['content']?.toString().trim();
    if (text == null || text.isEmpty) {
      throw Exception('Groq API returned empty choices[0].message.content.');
    }

    return text;
  }

  // ── Feature 1: AI Smart Search ─────────────────────────────────────────────

  /// Extracts structured search parameters from a natural language query.
  ///
  /// Example:
  ///   Input:  "need someone to fix my leaking pipe under PKR 2000"
  ///   Output: SearchExtraction(category: 'plumber', maxPrice: 2000.0,
  ///            cleanQuery: 'leaking pipe repair')
  Future<SearchExtraction> extractSearchParameters(String userQuery) async {
    if (!isAvailable) {
      return SearchExtraction(cleanQuery: userQuery);
    }

    try {
      final prompt = '''
You are a search assistant for a local services marketplace in Pakistan.
Extract structured information from this search query.

Valid categories: ${_validCategories.join(', ')}

Query: "$userQuery"

Respond with ONLY a JSON object in this exact format (no markdown, no explanation):
{
  "category": "plumber" or null,
  "max_price": 2000 or null,
  "clean_query": "short descriptive search terms"
}

Rules:
- category must be one of the valid categories or null
- max_price is a number in PKR or null if not mentioned
- clean_query is 2-5 keywords describing what the user needs
- If you cannot determine category, use null
''';

      final text = await _groqRequest(
        [
          {'role': 'user', 'content': prompt},
        ],
        temperature: 0.3,
      );

      return _parseSearchExtraction(text, userQuery);
    } catch (_) {
      return SearchExtraction(cleanQuery: userQuery);
    }
  }

  SearchExtraction _parseSearchExtraction(String jsonText, String fallback) {
    try {
      // Clean the response in case model adds extra text
      final cleanJson = jsonText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Simple manual parsing to avoid adding json package dependency
      String? category;
      double? maxPrice;
      String cleanQuery = fallback;

      // Extract category
      final categoryMatch = RegExp(r'"category"\s*:\s*"([^"]+)"')
          .firstMatch(cleanJson);
      if (categoryMatch != null) {
        final extracted = categoryMatch.group(1)!.toLowerCase();
        if (_validCategories.contains(extracted)) {
          category = extracted;
        }
      }

      // Extract max_price
      final priceMatch = RegExp(r'"max_price"\s*:\s*(\d+(?:\.\d+)?)')
          .firstMatch(cleanJson);
      if (priceMatch != null) {
        maxPrice = double.tryParse(priceMatch.group(1)!);
      }

      // Extract clean_query
      final queryMatch = RegExp(r'"clean_query"\s*:\s*"([^"]+)"')
          .firstMatch(cleanJson);
      if (queryMatch != null) {
        cleanQuery = queryMatch.group(1)!;
      }

      return SearchExtraction(
        category: category,
        maxPrice: maxPrice,
        cleanQuery: cleanQuery,
      );
    } catch (_) {
      return SearchExtraction(cleanQuery: fallback);
    }
  }

  // ── Feature 2: Review Summarizer ───────────────────────────────────────────

  /// Generates a summary paragraph from pre-formatted review lines.
  /// Returns null if Groq is unavailable or [reviewTexts] is empty.
  ///
  /// The caller fetches reviews, formats text, and caches in the database.
  /// See [ServiceRepository.getOrRefreshAiSummary].
  Future<String?> generateReviewSummary({
    required String serviceName,
    required String reviewTexts,
  }) async {
    if (!isAvailable || reviewTexts.trim().isEmpty) return null;

    try {
      final prompt = '''
Summarize these customer reviews for "$serviceName" in 2-3 sentences.
Be specific about what customers praise and any common concerns.
Write in third person. Be honest — include negatives if they appear.
Keep it under 80 words.

Reviews:
$reviewTexts

Write ONLY the summary paragraph. No headings, no bullet points.
''';

      final summary = await _groqRequest(
        [
          {'role': 'user', 'content': prompt},
        ],
        temperature: 0.5,
      );

      if (summary.isEmpty) return null;
      return summary;
    } catch (e, st) {
      debugPrint('generateReviewSummary error: $e');
      debugPrint('$st');
      return null;
    }
  }

  // ── Feature 3: SkillBot Assistant ──────────────────────────────────────────

  /// Sends a message to SkillBot and returns the response.
  /// Maintains conversation history for multi-turn chat.
  ///
  /// The system prompt scopes SkillBot strictly to platform topics.
  /// Off-topic questions are politely declined.
  Future<String> sendSkillBotMessage({
    required String userMessage,
    required List<Map<String, String>> conversationHistory,
    required String userRole, // 'customer', 'provider', or 'admin'
  }) async {
    if (!isAvailable) {
      return 'SkillBot is currently unavailable. Please try again later.';
    }

    try {
      final systemContext = '''
You are SkillBot, the helpful assistant for SkillBridge — a local services 
marketplace in Pakistan connecting customers with service providers.

Current user role: $userRole

You ONLY answer questions about:
- How to find and book services
- How to manage bookings (cancel, track status)
- How to write reviews
- How to create and manage service listings (for providers)
- How to manage your profile
- Platform policies and rules
- How to contact support

For customers: explain booking, cancellation, reviews, saving services.
For providers: explain listing services, managing bookings, earnings, availability.

If asked about anything unrelated to SkillBridge, politely say:
"I can only help with questions about SkillBridge. For other questions, 
please use a general search engine."

Keep responses concise (under 100 words). Be friendly and helpful.
''';

      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': systemContext},
      ];

      for (final message in conversationHistory) {
        final isUser = message['role'] == 'user';
        final content = (message['content'] ?? '').trim();
        if (content.isEmpty) continue;
        messages.add({
          'role': isUser ? 'user' : 'assistant',
          'content': content,
        });
      }

      messages.add({'role': 'user', 'content': userMessage});

      final reply = await _groqRequest(messages, temperature: 0.7);
      return reply.isNotEmpty
          ? reply
          : 'I could not process that. Please try again.';
    } catch (_) {
      return 'SkillBot is temporarily unavailable. Please try again.';
    }
  }

  /// Generic multi-turn chat via Groq (OpenAI-compatible API).
  Future<String> sendChatMessage({
    required String systemPrompt,
    required List<Map<String, dynamic>> history,
    required String userMessage,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    debugPrint(
      'GROQ_KEY_CHECK: ${apiKey.isEmpty ? "EMPTY - NOT LOADED" : "Loaded, starts with: ${apiKey.substring(0, apiKey.length >= 6 ? 6 : apiKey.length)}"}',
    );

    if (apiKey.isEmpty) {
      throw Exception(
        'GROQ_API_KEY is missing or empty. Add it to .env and restart the app.',
      );
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    for (final message in history) {
      final content = _groqHistoryItemContent(message);
      if (content.isEmpty) continue;
      messages.add({
        'role': _groqOpenAiRole(message['role']),
        'content': content,
      });
    }

    messages.add({'role': 'user', 'content': userMessage});

    try {
      return await _groqRequest(messages, temperature: 0.7);
    } catch (e, st) {
      debugPrint('GROQ_ERROR: ${e.runtimeType}: $e');
      debugPrint('$st');
      if (e is Exception) {
        final msg = e.toString();
        if (msg.contains('Groq API') ||
            msg.contains('GROQ_API_KEY') ||
            msg.startsWith('Exception: Groq')) {
          rethrow;
        }
      }
      throw Exception('Groq chat request failed: $e');
    }
  }

  static String _groqHistoryItemContent(Map<String, dynamic> message) {
    final direct = message['content'];
    if (direct != null) {
      final s = direct.toString().trim();
      if (s.isNotEmpty) return s;
    }
    final parts = message['parts'];
    if (parts is List && parts.isNotEmpty) {
      final first = parts.first;
      if (first is Map) {
        final t = first['text'];
        if (t != null) {
          final ts = t.toString().trim();
          if (ts.isNotEmpty) return ts;
        }
      }
      return first.toString().trim();
    }
    return '';
  }

  static String _groqOpenAiRole(dynamic role) {
    final r = (role ?? 'user').toString().toLowerCase();
    if (r == 'assistant' || r == 'model') return 'assistant';
    if (r == 'system') return 'system';
    return 'user';
  }
}

