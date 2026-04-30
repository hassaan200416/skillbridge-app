import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/chat_message_model.dart';
import '../../providers/provider_skillbot_provider.dart';

/// Wrap any Provider screen's body with this widget to inject the Provider SkillBot.
class ProviderSkillBotWidget extends StatefulWidget {
  const ProviderSkillBotWidget({super.key, required this.child});
  final Widget child;

  @override
  State<ProviderSkillBotWidget> createState() => _ProviderSkillBotWidgetState();
}

class _ProviderSkillBotWidgetState extends State<ProviderSkillBotWidget>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleBot() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOpen)
          Positioned(
            bottom: 80,
            right: 16,
            left: 16,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                alignment: Alignment.bottomRight,
                child: const _ProviderSkillBotSheet(),
              ),
            ),
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: _ProviderSkillBotFab(isOpen: _isOpen, onTap: _toggleBot),
        ),
      ],
    );
  }
}

class _ProviderSkillBotFab extends StatelessWidget {
  const _ProviderSkillBotFab({required this.isOpen, required this.onTap});
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: isOpen
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF00695C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isOpen ? AppColors.surfaceVariant : null,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00897B).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isOpen
                ? const Icon(Icons.close,
                    color: AppColors.grey600, size: 28, key: ValueKey('close'))
                : const Icon(Icons.support_agent_rounded,
                    color: Colors.white, size: 30, key: ValueKey('bot')),
          ),
        ),
      ),
    );
  }
}

class _ProviderSkillBotSheet extends ConsumerStatefulWidget {
  const _ProviderSkillBotSheet();

  @override
  ConsumerState<_ProviderSkillBotSheet> createState() =>
      _ProviderSkillBotSheetState();
}

class _ProviderSkillBotSheetState
    extends ConsumerState<_ProviderSkillBotSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    ref.read(providerSkillBotNotifierProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerSkillBotNotifierProvider);
    ref.listen(providerSkillBotNotifierProvider, (_, __) => _scrollToBottom());

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 420,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _ProviderBotHeader(
              onClear: () => ref
                  .read(providerSkillBotNotifierProvider.notifier)
                  .clearChat(),
            ),
            Expanded(
              child: state.messages.isEmpty
                  ? const _ProviderBotWelcome()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) =>
                          _MessageBubble(message: state.messages[index]),
                    ),
            ),
            if (state.isTyping)
              const Padding(
                padding: EdgeInsets.only(left: 16, bottom: 4),
                child: _TypingIndicator(),
              ),
            const _ProviderSuggestedPrompts(),
            _InputBar(
              controller: _inputController,
              focusNode: _focusNode,
              isLoading: state.isTyping,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderBotHeader extends StatelessWidget {
  const _ProviderBotHeader({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient:
            LinearGradient(colors: [Color(0xFF00897B), Color(0xFF00695C)]),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SkillBot - Provider',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'AI assistant - Powered by Groq',
                  style:
                      AppTextStyles.labelSmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white70, size: 18),
            tooltip: 'Clear chat',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ProviderBotWelcome extends StatelessWidget {
  const _ProviderBotWelcome();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00897B).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.handshake_outlined,
                size: 32, color: Color(0xFF00897B)),
          ),
          const SizedBox(height: 12),
          Text(
            'Hi Provider!',
            style: AppTextStyles.headingSmall
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'I can help you manage services, bookings, earnings, and provider dashboard actions.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }
}

class _ProviderSuggestedPrompts extends ConsumerWidget {
  const _ProviderSuggestedPrompts();

  static const _prompts = [
    'How do I accept a booking?',
    'How does payment work?',
    'How do I add service photos?',
    'How are my ratings calculated?',
    'Can I set my availability?',
    'How do I reject a booking?',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => ref
                .read(providerSkillBotNotifierProvider.notifier)
                .sendMessage(_prompts[index]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF00897B).withValues(alpha: 0.25)),
              ),
              child: Text(
                _prompts[index],
                style: AppTextStyles.labelSmall
                    .copyWith(color: const Color(0xFF00897B)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF00897B).withValues(alpha: 0.12),
              child: const Icon(Icons.support_agent_rounded,
                  size: 14, color: Color(0xFF00897B)),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isUser ? const Color(0xFF00897B) : AppColors.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.content,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isUser ? Colors.white : AppColors.grey800,
                  height: 1.45,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 6),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF00897B),
              child: Icon(Icons.person, size: 14, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final offset = ((_controller.value * 3) - index).clamp(0.0, 1.0);
            final opacity = (1 - (offset - 0.5).abs() * 2).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00897B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isLoading,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: AppTextStyles.bodySmall,
              decoration: InputDecoration(
                hintText: 'Ask about your services...',
                hintStyle:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.grey400),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: Color(0xFF00897B), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          isLoading
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFF00897B),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: onSend,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00897B), Color(0xFF00695C)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
        ],
      ),
    );
  }
}
