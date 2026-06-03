// lib/screens/contact_doctor_screen.dart  (AI Chat screen)
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../app_theme.dart';

class ContactDoctorScreen extends StatefulWidget {
  final String? caseId;
  const ContactDoctorScreen({super.key, this.caseId});
  @override State<ContactDoctorScreen> createState() => _State();
}

class _State extends State<ContactDoctorScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  String? _sessionId;
  String _language = 'en';
  bool _loading = false;
  final List<Map<String, String>> _messages = [];

  @override void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _send() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty) return;
    _ctrl.clear();
    setState(() { _messages.add({'role': 'user', 'content': msg}); _loading = true; });
    _scrollDown();
    try {
      final resp = await ChatService.sendMessage(
          message: msg, sessionId: _sessionId, caseId: widget.caseId, language: _language);
      _sessionId = resp['session_id'];
      setState(() { _messages.add({'role': 'assistant', 'content': resp['response'] ?? ''}); });
    } catch (e) {
      setState(() { _messages.add({'role': 'assistant', 'content': 'Sorry, I could not process your message. Please try again.'}); });
    } finally {
      setState(() => _loading = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI Medical Assistant'),
        backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
        actions: [
          DropdownButton<String>(value: _language, dropdownColor: Colors.white,
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('EN', style: TextStyle(color: Colors.black))),
              DropdownMenuItem(value: 'ar', child: Text('AR', style: TextStyle(color: Colors.black))),
            ],
            onChanged: (v) => setState(() => _language = v ?? 'en')),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        // Disclaimer banner
        Container(color: Colors.amber.shade50, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Colors.amber, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('AI assistant only. Not a substitute for professional medical advice.',
                style: TextStyle(fontSize: 11, color: Colors.black87))),
          ])),
        // Messages
        Expanded(child: _messages.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Ask me about your diagnosis,\nmedications, or side effects',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
            ]))
          : ListView.builder(controller: _scroll, padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (_loading && i == _messages.length) return _TypingIndicator();
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
                    child: Text(m['content'] ?? '',
                        style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14))));
              })),
        // Input bar
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))]),
          child: Row(children: [
            Expanded(child: TextField(controller: _ctrl,
              decoration: InputDecoration(hintText: _language == 'ar' ? 'اكتب سؤالك...' : 'Ask about your health...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true, fillColor: Colors.grey.shade50),
              onSubmitted: (_) => _send(), textInputAction: TextInputAction.send,
              textDirection: _language == 'ar' ? TextDirection.rtl : TextDirection.ltr)),
            const SizedBox(width: 8),
            CircleAvatar(backgroundColor: AppTheme.primary, radius: 22,
              child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _send)),
          ])),
      ]),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(alignment: Alignment.centerLeft,
    child: Container(margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _Dot(delay: 0), _Dot(delay: 200), _Dot(delay: 400),
      ])));
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0).animate(_c);
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
    child: FadeTransition(opacity: _a, child: const CircleAvatar(radius: 4, backgroundColor: Colors.grey)));
}
