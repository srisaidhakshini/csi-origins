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

  ChatMessage({
    required this.text,
    required this.isUser,
    this.suggestion,
    required this.timestamp,
  });
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I am your Autonomous Financial Copilot. I continuously monitor your bank SMS, Gmail receipts, and variable income. Ask me anything about your cashflow, upcoming rent shortfall, or discretionary budget safety.',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

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
        _messages.add(ChatMessage(
          text: replyText,
          isUser: false,
          suggestion: res['actionSuggestion'],
          timestamp: DateTime.now(),
        ));
        AudioService.speak(replyText);
      } else {
        _messages.add(ChatMessage(
          text: 'Your current liquid buffer is ₹12,000 in HDFC Checking. You face a ₹16,000 rent deficit on Day 5 due to delayed gig payments.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D32B2),
        title: const Text('Financial Copilot Chat'),
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
                  Text('Copilot is reasoning over your causal graph...', style: TextStyle(color: Color(0xFF5A6E85), fontSize: 11, fontWeight: FontWeight.w500)),
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
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
                  InkWell(
                    onTap: () => AudioService.speak(msg.text),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.volume_up_rounded, color: Color(0xFF1548DC), size: 16),
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
