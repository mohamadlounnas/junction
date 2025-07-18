import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:appsystem/theme.dart';
import 'package:appsystem/services/chatbot_service.dart';

/// Modern ChatBot Page with Voice-to-Text functionality
///
/// Features:
/// - Real-time chat interface
/// - Voice-to-text conversion
/// - ChatGPT API integration
/// - Modern UI with animations
/// - Arabic and English support
/// - Professional real estate assistant
class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage>
    with TickerProviderStateMixin {
  final ChatBotService _chatBotService = ChatBotService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isTyping = false;
  String _transcriptionText = '';

  late AnimationController _typingAnimationController;
  late AnimationController _listeningAnimationController;
  late Animation<double> _typingAnimation;
  late Animation<double> _listeningAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeChatBot();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _listeningAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _chatBotService.dispose();
    super.dispose();
  }

  /// Initialize animations
  void _initializeAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _listeningAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _typingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _listeningAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _listeningAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Initialize chatbot service
  Future<void> _initializeChatBot() async {
    final initialized = await _chatBotService.initializeSpeech();
    if (!initialized) {
      _showPermissionError();
    }
  }

  /// Add welcome message
  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            '''مرحباً! أنا مساعدك الذكي في مجال العقارات. يمكنني مساعدتك في:

• البحث عن العقارات المناسبة
• معلومات السوق والاتجاهات
• إدارة علاقات العملاء
• التقييم العقاري
• النصائح الاستثمارية
• المعلومات القانونية

كيف يمكنني مساعدتك اليوم؟

---
Hello! I'm your intelligent real estate assistant. I can help you with:

• Finding suitable properties
• Market information and trends
• Client relationship management
• Property valuation
• Investment advice
• Legal information

How can I help you today?''',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Show permission error
  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'يجب السماح بالوصول إلى الميكروفون لاستخدام الميزة الصوتية\nMicrophone permission is required for voice features',
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'إعدادات',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Open app settings
          },
        ),
      ),
    );
  }

  /// Send text message
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await _chatBotService.sendMessage(message);

      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content:
                'عذراً، حدث خطأ. يرجى المحاولة مرة أخرى.\nSorry, an error occurred. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  /// Start voice input
  Future<void> _startVoiceInput() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _transcriptionText = '';
    });

    _listeningAnimationController.repeat();

    try {
      await _chatBotService.startListening(
        onResult: (text) async {
          setState(() {
            _transcriptionText = text;
          });

          if (text.isNotEmpty) {
            setState(() {
              _messages.add(
                ChatMessage(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  content: text,
                  isUser: true,
                  timestamp: DateTime.now(),
                  type: MessageType.voice,
                ),
              );
              _isTyping = true;
            });

            _scrollToBottom();

            final response = await _chatBotService.sendMessage(text);

            setState(() {
              _isTyping = false;
              _messages.add(
                ChatMessage(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  content: response,
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
              );
            });

            _scrollToBottom();
          }
        },
        onListeningStarted: () {
          setState(() {
            _isListening = true;
          });
        },
        onListeningStopped: () {
          setState(() {
            _isListening = false;
            _transcriptionText = '';
          });
          _listeningAnimationController.stop();
        },
      );
    } catch (e) {
      setState(() {
        _isListening = false;
        _transcriptionText = '';
      });
      _listeningAnimationController.stop();
      _showPermissionError();
    }
  }

  /// Stop voice input
  Future<void> _stopVoiceInput() async {
    await _chatBotService.stopListening();
    setState(() {
      _isListening = false;
      _transcriptionText = '';
    });
    _listeningAnimationController.stop();
  }

  /// Scroll to bottom of chat
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
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Chat messages
            Expanded(child: _buildChatMessages()),

            // Transcription text
            if (_transcriptionText.isNotEmpty) _buildTranscriptionText(),

            // Input area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  /// Build header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen,
                  AppTheme.primaryGreen.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Iconsax.message_question,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المساعد الذكي',
                  style: AppTheme.getSafeTextTheme().titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Smart Assistant',
                  style: AppTheme.getSafeTextTheme().bodySmall?.copyWith(
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'متصل',
              style: AppTheme.getSafeTextTheme().labelSmall?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build chat messages
  Widget _buildChatMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }

        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  /// Build message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen,
                    AppTheme.primaryGreen.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Iconsax.message_question,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primaryGreen.withOpacity(0.2)
                    : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                border: Border.all(
                  color: isUser
                      ? AppTheme.primaryGreen.withOpacity(0.3)
                      : AppTheme.borderColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.voice) ...[
                    Row(
                      children: [
                        Icon(
                          Iconsax.microphone,
                          size: 16,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'رسالة صوتية',
                          style: AppTheme.getSafeTextTheme().labelSmall
                              ?.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  Text(
                    message.content,
                    style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                      color: isUser ? AppTheme.textWhite : AppTheme.textWhite,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _formatTime(message.timestamp),
                    style: AppTheme.getSafeTextTheme().labelSmall?.copyWith(
                      color: AppTheme.textGrey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Icon(Iconsax.user, color: AppTheme.primaryGreen, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  /// Build typing indicator
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen,
                  AppTheme.primaryGreen.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Iconsax.message_question,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(
                20,
              ).copyWith(bottomLeft: const Radius.circular(4)),
              border: Border.all(
                color: AppTheme.borderColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _typingAnimation,
                  builder: (context, child) {
                    return Row(
                      children: [
                        _buildTypingDot(0),
                        const SizedBox(width: 4),
                        _buildTypingDot(1),
                        const SizedBox(width: 4),
                        _buildTypingDot(2),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build typing dot
  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        final delay = index * 0.2;
        final animationValue = (_typingAnimation.value + delay) % 1.0;

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(
              0.3 + (animationValue * 0.7),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  /// Build transcription text
  Widget _buildTranscriptionText() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _listeningAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _listeningAnimation.value,
                child: Icon(
                  Iconsax.microphone,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _transcriptionText,
              style: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build input area
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Voice button
            GestureDetector(
              onTapDown: (_) => _startVoiceInput(),
              onTapUp: (_) => _stopVoiceInput(),
              onTapCancel: () => _stopVoiceInput(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isListening
                      ? AppTheme.primaryGreen.withOpacity(0.2)
                      : AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isListening
                        ? AppTheme.primaryGreen
                        : AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _listeningAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? _listeningAnimation.value : 1.0,
                      child: Icon(
                        _isListening
                            ? Iconsax.microphone_slash
                            : Iconsax.microphone,
                        color: AppTheme.primaryGreen,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.borderColor.withOpacity(0.5),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  style: AppTheme.getSafeTextTheme().bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك هنا...',
                    hintStyle: AppTheme.getSafeTextTheme().bodyMedium?.copyWith(
                      color: AppTheme.textGrey,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.send_1,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format timestamp
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} د';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} س';
    } else {
      return '${difference.inDays} يوم';
    }
  }
}
