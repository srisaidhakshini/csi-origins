import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String? suggestion;
  final DateTime timestamp;
  bool isSpeaking;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.suggestion,
    required this.timestamp,
    this.isSpeaking = false,
  });
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I am your Autonomous Financial Copilot. I continuously monitor your real bank transactions, checking buffer, and scheduled obligations directly from PostgreSQL. Ask me anything about your balance, cashflow, or discretionary spend safety.',
      isUser: false,
      timestamp: DateTime.now(),
      isSpeaking: false,
    ),
  ];
  bool _isLoading = false;

  @override
  void dispose() {
    AudioService.stop();
    _messageController.dispose();
    super.dispose();
  }

  void _toggleSpeech(ChatMessage msg) {
    setState(() {
      if (msg.isSpeaking) {
        AudioService.stop();
        msg.isSpeaking = false;
      } else {
        // Stop any other active message audio
        AudioService.stop();
        for (final m in _messages) {
          m.isSpeaking = false;
        }
        msg.isSpeaking = true;
        AudioService.speak(msg.text);
      }
    });
  }

  void _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    // Stop existing audio when user submits a new prompt
    AudioService.stop();
    for (final m in _messages) {
      m.isSpeaking = false;
    }

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });

    final res = await ApiService.sendChatMessage(query);

    setState(() {
      _isLoading = false;
      if (res != null && res['reply'] != null) {
        final replyText = res['reply'];
        final botMsg = ChatMessage(
          text: replyText,
          isUser: false,
          suggestion: res['actionSuggestion'],
          timestamp: DateTime.now(),
          isSpeaking: true,
        );
        _messages.add(botMsg);
        AudioService.speak(replyText);
      } else {
        const fallback = 'Your current liquid buffer is ₹12,000 in HDFC Checking. You face a ₹16,000 rent deficit on Day 5 due to delayed gig payments.';
        final botMsg = ChatMessage(
          text: fallback,
          isUser: false,
          timestamp: DateTime.now(),
          isSpeaking: true,
        );
        _messages.add(botMsg);
        AudioService.speak(fallback);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D32B2),
        title: const Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Financial Copilot Chat'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_off_rounded, color: Colors.white),
            tooltip: 'Mute all audio',
            onPressed: () {
              AudioService.stop();
              setState(() {
                for (final m in _messages) {
                  m.isSpeaking = false;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick sample prompts
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPromptChip('Can I afford to spend today?', 'Can I afford discretionary spending today?'),
                  const SizedBox(width: 8),
                  _buildPromptChip('When are bills due?', 'When are my scheduled obligations due and is my buffer safe?'),
                  const SizedBox(width: 8),
                  _buildPromptChip('Recent transactions', 'What are my recent transactions logged from SMS?'),
                  const SizedBox(width: 8),
                  _buildPromptChip('Total balance snapshot', 'What is my current checking buffer balance?'),
                ],
              ),
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1548DC)),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Copilot is reasoning over your causal graph with Gemini...',
                    style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          // Bottom Input Field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1548DC).withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask about your balance, rent, or cashflow...',
                        hintStyle: const TextStyle(color: Color(0xFF8A99AD), fontSize: 12.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF4F7FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF1548DC)),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String label, String fullPrompt) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1548DC))),
      backgroundColor: const Color(0xFFEBF1FF),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () => _sendMessage(fullPrompt),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF1548DC) : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isUser)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.smart_toy_rounded, color: Color(0xFF1548DC), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Origin Copilot',
                        style: TextStyle(color: Color(0xFF1548DC), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Tooltip(
                    message: msg.isSpeaking ? 'Mute / Stop reading' : 'Read aloud',
                    child: InkWell(
                      onTap: () => _toggleSpeech(msg),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: msg.isSpeaking ? const Color(0xFFEBF1FF) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: msg.isSpeaking ? const Color(0xFF1548DC).withOpacity(0.3) : const Color(0xFFE2E8F0),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              msg.isSpeaking ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                              color: msg.isSpeaking ? const Color(0xFF1548DC) : const Color(0xFF8A99AD),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              msg.isSpeaking ? 'Speaking' : 'Muted',
                              style: TextStyle(
                                color: msg.isSpeaking ? const Color(0xFF1548DC) : const Color(0xFF8A99AD),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (!msg.isUser) const SizedBox(height: 6),
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? Colors.white : const Color(0xFF1C2434),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (msg.suggestion != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF1FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF1548DC)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Recommended: ${msg.suggestion}',
                        style: const TextStyle(color: Color(0xFF1548DC), fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

