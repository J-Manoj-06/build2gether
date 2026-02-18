/// AI Chat Page
///
/// Chat interface with AI farming advisor
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // Colors matching the HTML design
  static const Color primaryColor = Color(0xFF2F7F34);
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(0xFF141E15);

  // Sample chat messages
  final List<Map<String, dynamic>> _messages = [
    {
      'isAI': true,
      'text':
          'Hello! I am your AI agricultural advisor. How are your crops doing today? I can help with disease diagnosis or pest control.',
      'time': '10:30 AM',
    },
    {
      'isAI': false,
      'text':
          'My paddy leaves are turning yellowish at the tips. Is it a nutrient deficiency?',
      'time': '10:32 AM',
    },
    {
      'isAI': true,
      'text':
          'Yellowing tips in paddy often indicate **Potassium deficiency** or **Nitrogen stress**.\n\nBased on current weather data for your region, I recommend checking the soil moisture first. Would you like me to schedule a soil test for you?',
      'hasImage': true,
      'time': '10:33 AM',
    },
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: primaryColor,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isAI': false,
        'text': _messageController.text.trim(),
        'time': TimeOfDay.now().format(context),
      });
      _isTyping = true;
    });

    _messageController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'isAI': true,
            'text': 'I understand your concern. Let me analyze that for you...',
            'time': TimeOfDay.now().format(context),
          });
          _isTyping = false;
        });

        // Scroll to bottom
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
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
                    child: message['isAI'] as bool
                        ? _buildAIMessage(message)
                        : _buildUserMessage(message),
                  ),
                ),

                // Typing Indicator
                if (_isTyping) _buildTypingIndicator(),
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
                          'Online Advisor',
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

              // Info Button
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: () {
                  // Handle info
                },
              ),

              // More Button
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  // Handle more options
                },
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: primaryColor,
              size: 32,
            ),
          ),

          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Farming Assistant',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ask me about crop health, weather forecasts, or soil quality!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIMessage(Map<String, dynamic> message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // AI Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withOpacity(0.3)),
          ),
          child: const Icon(
            Icons.psychology_outlined,
            color: primaryColor,
            size: 18,
          ),
        ),

        const SizedBox(width: 10),

        // Message Content
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  'UZHAVU SEI AI',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image if present
                    if (message['hasImage'] == true)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuBnMhqGTq6C8sr-7Wv5X8YTnd2OeO83WKtn_YqQIOQxTnZhIoSyI-T__hylGaWSqYNxS8zr1F4wCRGdVsUv5o_OkJPGcFWHFray2JhlTRTbFxd2yYAXW8cjqprNSJUjyVaVa-qim_N1gFnPUqGwZRPg39ZVljZRvC4BhyxPryrJEnvaC82EP4OavFX_fE2tToPfmSEvm2s_Oiu33RcbGDoKAtaxOtjMGnya8LM9AXPMQHqlXaTn27p6NCLQhWWWuxuR6ZQEsnPvt34',
                          height: 128,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 128,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image),
                            );
                          },
                        ),
                      ),

                    // Message Text
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        message['text'] as String,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserMessage(Map<String, dynamic> message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Message Content
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: Text(
                  'YOU',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message['text'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // User Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuDe6KFlMdIsN58ahgc09D2PR2MT67MU5Xzy2xut6BHa3Y0CLW9vXOwbYdhgBgGFN4fbxFzxN5d8QEWMPr3Cia_zjy6nwaKW0-NXFpYICwGS-mi4fTruDKnm4Hh9V_-HNjOO8joh4Nm-7YOOXSgtTAC2vaYcmAKPuO0GnHtiyouPvkisvQuXEiPL2DNaCvaqB_lL2tI11ehFcLNC-wkMNjwnO-IL8Xf9SNAV26_QZi1jQ_FDFCl74EAsUhaOed7pJbpaanNK1roNmEo',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.person, size: 20);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        const SizedBox(width: 8),
        Row(
          children: List.generate(
            3,
            (index) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Uzhavu Sei AI is thinking...',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Row(
                children: [
                  // Add Button
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: Colors.grey[400],
                    ),
                    onPressed: () {
                      // Handle attachment
                    },
                  ),

                  // Text Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: TextField(
                        controller: _messageController,
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
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),

            // Voice Button (Floating)
            Positioned(
              top: -44,
              right: 16,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white, size: 28),
                  onPressed: () {
                    // Handle voice input
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voice input coming soon!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
