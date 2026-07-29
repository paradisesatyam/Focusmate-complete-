import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _gemini = GeminiService();
  final List<ChatMessage> _messages = [];
  bool _loading = false;

  final _quickPrompts = ['Plan my week 📅', 'Motivate me 💪', 'Study tips 📚', 'Productivity hack ⚡'];

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send([String? text]) async {
    final msg = (text ?? _ctrl.text).trim();
    if (msg.isEmpty) return;
    _ctrl.clear();
    setState(() {
      _messages.add(ChatMessage(text: msg, isUser: true, time: DateTime.now()));
      _loading = true;
    });
    _scrollDown();
    final reply = await _gemini.send(msg);
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: reply, isUser: false, time: DateTime.now()));
      _loading = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('AI Chat', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [if (_messages.isNotEmpty) IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () => setState(() => _messages.clear()))]),
      body: Column(children: [
        Expanded(child: _messages.isEmpty
          ? _emptyState()
          : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return _typingIndicator();
                return _Bubble(msg: _messages[i]);
              },
            )),

        // Input bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SafeArea(child: Column(children: [
            if (_messages.isEmpty) ...[
              SizedBox(height: 48, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _quickPrompts.length, itemBuilder: (_, i) => GestureDetector(onTap: () => _send(_quickPrompts[i]), child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)), child: Text(_quickPrompts[i], style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)))))),
              const SizedBox(height: 10),
            ],
            Row(children: [
              Expanded(child: TextField(
                controller: _ctrl, maxLines: null,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ask anything...', hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true, fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _loading ? null : () => _send(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: _loading ? Colors.grey.shade300 : AppColors.primary, shape: BoxShape.circle),
                  child: Icon(_loading ? Icons.hourglass_empty_rounded : Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ])),
        ),
      ]),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 40)),
    const SizedBox(height: 20),
    const Text('FocusMate AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    const SizedBox(height: 8),
    const Text('Your productivity assistant.', style: TextStyle(color: AppColors.textSecondary)),
  ]));

  Widget _typingIndicator() => Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 12, right: 60), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => AnimatedContainer(duration: Duration(milliseconds: 400 + i * 150), margin: const EdgeInsets.symmetric(horizontal: 2), width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))))));
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(msg.isUser ? 18 : 4), bottomRight: Radius.circular(msg.isUser ? 4 : 18)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(msg.text, style: TextStyle(fontSize: 14, color: msg.isUser ? Colors.white : AppColors.textPrimary, height: 1.5)),
          const SizedBox(height: 4),
          Text(DateFormat('hh:mm a').format(msg.time), style: TextStyle(fontSize: 10, color: msg.isUser ? Colors.white60 : AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
