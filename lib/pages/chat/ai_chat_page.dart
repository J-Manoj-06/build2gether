/// AI Chat Page
///
/// Real-time chat interface with Gemini AI farming advisor
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ai/find_buyers_page.dart';
import '../../models/chat_message.dart';
import '../../services/gemini_service.dart';
import '../../services/chat_cache_service.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Services
  final GeminiService _geminiService = GeminiService();
  final ChatCacheService _cacheService = ChatCacheService();

  // State
  List<ChatMessage> _messages = [];
  bool _loading = false;

  // Colors matching the design
  static const Color primaryColor = Color(0xFF2F7F34);
  static const Color backgroundLight = Color(0xFFF6F8F6);

  @override
  void initState() {
    super.initState();
    _loadCachedMessages();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: primaryColor,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Load cached chat history on startup
  Future<void> _loadCachedMessages() async {
    final cachedMessages = await _cacheService.loadMessages();

    if (cachedMessages.isEmpty) {
      // Add welcome message if no history
      setState(() {
        _messages = [
          ChatMessage(
            text:
                'Hello! I am your AI agricultural advisor. How are your crops doing today? I can help with disease diagnosis, pest control, fertilizer recommendations, and more.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ];
      });
      await _cacheService.saveMessages(_messages);
    } else {
      setState(() {
        _messages = cachedMessages;
      });
    }

    // Scroll to bottom after loading
    _scrollToBottom();
  }

  /// Send message to Gemini AI
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    // Prevent empty messages
    if (messageText.isEmpty) return;

    // Clear input immediately
    _messageController.clear();

    // Add user message
    final userMessage = ChatMessage(
      text: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _loading = true;
    });

    _scrollToBottom();

    // Convert message history to API format
    List<Map<String, String>> history = [];
    for (int i = 0; i < _messages.length - 1; i++) {
      history.add({
        'role': _messages[i].isUser ? 'user' : 'model',
        'text': _messages[i].text,
      });
    }

    try {
      // Call Gemini API
      final aiResponse = await _geminiService.sendMessage(messageText, history);

      // Add AI response
      final aiMessage = ChatMessage(
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _loading = false;
      });

      // Save to cache
      await _cacheService.saveMessages(_messages);

      _scrollToBottom();
    } catch (e) {
      // Handle error
      setState(() {
        _messages.add(
          ChatMessage(
            text: '⚠️ Sorry, I encountered an error. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _loading = false;
      });

      _scrollToBottom();
    }
  }

  /// Scroll to bottom of chat
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Clear chat history
  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will delete all messages. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cacheService.clearMessages();
      setState(() {
        _messages = [
          ChatMessage(
            text:
                'Hello! I am your AI agricultural advisor. How can I help you today?',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ];
      });
      await _cacheService.saveMessages(_messages);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Column(
        children: [
          // Top App Bar
          _buildHeader(),

          // Main Chat Area
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Context Card
                _buildContextCard(),

                const SizedBox(height: 24),

                // Chat Messages
                ..._messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: message.isUser
                        ? _buildUserMessage(message)
                        : _buildAIMessage(message),
                  ),
                ),

                // Typing Indicator
                if (_loading) _buildTypingIndicator(),
              ],
            ),
          ),

          // Bottom Input Bar
          _buildBottomInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: primaryColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Back Button
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),

              const SizedBox(width: 12),

              // Title and Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uzhavu Sei AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Powered by Gemini AI',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Clear chat button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _clearChat,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agriculture Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ask anything about farming',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionChip('Disease Diagnosis', Icons.bug_report),
                _buildQuickActionChip('Pest Control', Icons.pest_control),
                _buildQuickActionChip('Weather Tips', Icons.cloud),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FindBuyersPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 20),
                  SizedBox(width: 8),
                  Text('Find Buyers for My Crop'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon) {
    return InkWell(
      onTap: () {
        _messageController.text = 'Tell me about $label';
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIMessage(ChatMessage message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
        ),

        const SizedBox(width: 12),

        // Message Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message.formattedTime,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserMessage(ChatMessage message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),

        // Message Content
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2F7F34), Color(0xFF1B5E20)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message.formattedTime,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // User Avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person, color: Colors.grey, size: 20),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
        ),

        const SizedBox(width: 12),

        // Typing Animation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTypingDot(0),
              const SizedBox(width: 4),
              _buildTypingDot(1),
              const SizedBox(width: 4),
              _buildTypingDot(2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = (value - delay).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, -4 * (1 - (animValue * 2 - 1).abs())),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        setState(() {});
      },
    );
  }

  Widget _buildBottomInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Text Input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: TextField(
                    controller: _messageController,
                    enabled: !_loading,
                    decoration: const InputDecoration(
                      hintText: 'Ask AI about farming...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      hintStyle: TextStyle(fontSize: 15),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send Button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _loading ? Colors.grey : primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _loading ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
