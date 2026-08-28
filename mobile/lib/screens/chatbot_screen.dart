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
      text: 'Hello! I am your Autonomous Financial Copilot. I continuously monitor your bank SMS, Gmail receipts, and variable income. Ask me anything about your cashflow, upcoming rent shortfall, or discretionary budget safety.',
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
                  _buildPromptChip('Can I afford dinner tonight?', 'Can I afford dinner at a fancy restaurant tonight?'),
                  const SizedBox(width: 8),
                  _buildPromptChip('When is rent due?', 'When is my next rent due and is there a shortfall?'),
                  const SizedBox(width: 8),
                  _buildPromptChip('Who paid me this month?', 'Who paid me this month and what are my total received earnings?'),
                  const SizedBox(width: 8),
                  _buildPromptChip('Total balance snapshot', 'What is my total balance and upcoming bills?'),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: const Row(
                children: [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1548DC))),
                  SizedBox(width: 10),
                  Text('Copilot is reasoning over your causal graph with Gemini...', style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

          // Input Bar
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
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FC),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Color(0xFF1C2434), fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Ask about cashflow, rent safety, or budget...',
                        hintStyle: TextStyle(color: Color(0xFF8A99AD), fontSize: 12),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1548DC),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String label, String query) {
    return InkWell(
      onTap: () => _sendMessage(query),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEBF1FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF1548DC), fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
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
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: msg.isUser ? const Radius.circular(2) : const Radius.circular(18),
            bottomLeft: !msg.isUser ? const Radius.circular(2) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1548DC).withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                height: 1.4,
                fontWeight: FontWeight.w500,
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
                    const Icon(Icons.bolt_rounded, color: Color(0xFF1548DC), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Action: ${msg.suggestion}',
                      style: const TextStyle(color: Color(0xFF1548DC), fontSize: 10, fontWeight: FontWeight.bold),
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
