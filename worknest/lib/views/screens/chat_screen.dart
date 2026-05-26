import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = ChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _history = [];
  final List<_Bubble> _bubbles = [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;
    _controller.clear();

    setState(() {
      _bubbles.add(_Bubble(role: 'user', text: text));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _service.send(text, _history);
      _history.add(ChatMessage(role: 'user', text: text));
      _history.add(ChatMessage(role: 'assistant', text: reply));
      if (_history.length > 20) _history.removeRange(0, 2);

      setState(() => _bubbles.add(_Bubble(role: 'model', text: reply)));
    } catch (e) {
      setState(() => _bubbles.add(_Bubble(
          role: 'assistant',
          text: '⚠️ ${e.toString().replaceFirst("Exception: ", "")}')));
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Row(children: [
          Icon(Icons.smart_toy_rounded, size: 20),
          SizedBox(width: 8),
          Text('HR Assistant',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        ]),
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Welcome message
              _BubbleWidget(role: 'model',
                  text: '👋 Hi! Ask me anything about leave, claims, OT, payroll, or HR policies.'),
              ..._bubbles.map((b) => _BubbleWidget(role: b.role, text: b.text)),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: _TypingIndicator(),
                ),
            ],
          ),
        ),

        // Suggested chips (shown only at start)
        if (_bubbles.isEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(children: [
              'How is OT calculated?',
              'What claims can I submit?',
              'Explain EPF deductions',
              'How to apply leave?',
            ].map((q) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(q, style: const TextStyle(fontSize: 12)),
                onPressed: () => _send(q),
                backgroundColor: const Color(0xFFEDE9FE),
                labelStyle: const TextStyle(color: Color(0xFF6D28D9)),
                side: BorderSide.none,
              ),
            )).toList()),
          ),

        // Input bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _send(_controller.text),
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: _loading ? Colors.grey : AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Bubble {
  final String role;
  final String text;
  const _Bubble({required this.role, required this.text});
}

class _BubbleWidget extends StatelessWidget {
  final String role;
  final String text;
  const _BubbleWidget({required this.role, required this.text});

  @override
  Widget build(BuildContext context) {
    final isAi = role == 'model';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAi) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE), shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded,
                  size: 18, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAi ? const Color(0xFFF5F3FF) : AppTheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isAi ? 4 : 16),
                  bottomRight: Radius.circular(isAi ? 16 : 4),
                ),
              ),
              child: Text(text,
                  style: TextStyle(
                      fontSize: 14,
                      color: isAi ? const Color(0xFF1A1A2E) : Colors.white,
                      height: 1.5)),
            ),
          ),
          if (!isAi) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: const BoxDecoration(
            color: Color(0xFFEDE9FE), shape: BoxShape.circle),
        child: const Icon(Icons.smart_toy_rounded,
            size: 18, color: Color(0xFF7C3AED)),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 40, height: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Dot(delay: 0),
              _Dot(delay: 150),
              _Dot(delay: 300),
            ],
          ),
        ),
      ),
    ]);
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.0, end: -6.0).animate(CurvedAnimation(
        parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
            width: 7, height: 7,
            decoration: const BoxDecoration(
                color: Color(0xFF9CA3AF), shape: BoxShape.circle)),
      ),
    );
  }
}