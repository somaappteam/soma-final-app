import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AI Conversation Practice Screen
/// Practice speaking with AI in realistic scenarios
class AIConversationScreen extends StatefulWidget {
  final String? scenario;
  final String? difficulty;

  const AIConversationScreen({
    super.key,
    this.scenario,
    this.difficulty,
  });

  @override
  State<AIConversationScreen> createState() => _AIConversationScreenState();
}

class _AIConversationScreenState extends State<AIConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isVoiceMode = false;
  bool _isListening = false;
  
  // Conversation context
  String _currentTopic = 'Ordering at a Restaurant';
  String _aiPersona = 'Restaurant Server';
  final int _correctionsCount = 0;
  final int _helpfulPhrasesCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeConversation() {
    // Add initial AI greeting
    setState(() {
      _messages.add(ChatMessage(
        id: '1',
        text: '¡Hola! Bienvenido al Restaurante Sabroso. ¿Tienes una reserva? (Hello! Welcome to Restaurante Sabroso. Do you have a reservation?)',
        isUser: false,
        timestamp: DateTime.now(),
        translation: 'Hello! Welcome to Restaurante Sabroso. Do you have a reservation?',
        pronunciation: 'OH-lah, been-veh-NEE-doh',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildAppBar(),
          _buildScenarioCard(),
          Expanded(
            child: _buildChatArea(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Conversation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _aiPersona,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 8),
                const SizedBox(width: 6),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant, color: Color(0xFF667eea)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentTopic,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Practice ordering food and drinks in Spanish',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _changeScenario,
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF667eea) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  if (!isUser && message.translation != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.translate, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              message.translation!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isUser) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMessageAction(
                    icon: Icons.volume_up,
                    onTap: () => _speakMessage(message.text),
                  ),
                  const SizedBox(width: 8),
                  _buildMessageAction(
                    icon: Icons.copy,
                    onTap: () => _copyMessage(message.text),
                  ),
                  if (message.correction != null) ...[
                    const SizedBox(width: 8),
                    _buildMessageAction(
                      icon: Icons.check_circle,
                      color: Colors.green,
                      onTap: () => _showCorrection(message),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().slideX(
      begin: isUser ? 0.3 : -0.3,
      end: 0,
    );
  }

  Widget _buildMessageAction({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).scale(
      begin: const Offset(1, 1),
      end: const Offset(1.2, 1.2),
      duration: 600.ms,
      delay: (index * 200).ms,
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_isVoiceMode) _buildVoiceModeInterface(),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isVoiceMode ? Icons.keyboard : Icons.mic,
                    color: const Color(0xFF667eea),
                  ),
                  onPressed: () {
                    setState(() => _isVoiceMode = !_isVoiceMode);
                    HapticFeedback.lightImpact();
                  },
                ),
                if (!_isVoiceMode) ...[
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickPhrase('Hola'),
                const SizedBox(width: 8),
                _buildQuickPhrase('Gracias'),
                const SizedBox(width: 8),
                _buildQuickPhrase('Por favor'),
                const SizedBox(width: 8),
                _buildQuickPhrase('¿Cuánto cuesta?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceModeInterface() {
    return Container(
      height: 150,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(
            _isListening ? 'Listening...' : 'Tap to speak',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTapDown: (_) => setState(() => _isListening = true),
            onTapUp: (_) => setState(() => _isListening = false),
            onTapCancel: () => setState(() => _isListening = false),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: _isListening
                    ? const LinearGradient(
                        colors: [Colors.red, Colors.orange],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.red : const Color(0xFF667eea))
                        .withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 36,
              ),
            ),
          ).animate(
            target: _isListening ? 1 : 0,
          ).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.2, 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPhrase(String phrase) {
    return GestureDetector(
      onTap: () {
        _messageController.text = phrase;
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          phrase,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    HapticFeedback.mediumImpact();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: '¡Excelente! Una mesa para dos personas. ¿Prefieren sentarse dentro o en la terraza? (Excellent! A table for two. Would you prefer to sit inside or on the terrace?)',
          isUser: false,
          timestamp: DateTime.now(),
          translation: 'Excellent! A table for two. Would you prefer to sit inside or on the terrace?',
        ));
      });
      
      _scrollToBottom();
    });

    _scrollToBottom();
  }

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

  void _speakMessage(String text) {
    // Text-to-speech functionality
    HapticFeedback.lightImpact();
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showCorrection(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grammar Correction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.close, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.correction?.original ?? '',
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.correction?.corrected ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message.correction?.explanation ?? '',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeScenario() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a Scenario',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildScenarioOption(
                      'At the Restaurant',
                      'Practice ordering food and drinks',
                      Icons.restaurant,
                      Colors.orange,
                    ),
                    _buildScenarioOption(
                      'Hotel Check-in',
                      'Book a room and ask for amenities',
                      Icons.hotel,
                      Colors.blue,
                    ),
                    _buildScenarioOption(
                      'Shopping',
                      'Ask about prices and sizes',
                      Icons.shopping_bag,
                      Colors.pink,
                    ),
                    _buildScenarioOption(
                      'Airport',
                      'Navigate check-in and security',
                      Icons.flight,
                      Colors.purple,
                    ),
                    _buildScenarioOption(
                      'Doctor Visit',
                      'Describe symptoms and understand prescriptions',
                      Icons.local_hospital,
                      Colors.red,
                    ),
                    _buildScenarioOption(
                      'Job Interview',
                      'Professional conversation practice',
                      Icons.work,
                      Colors.teal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioOption(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          setState(() {
            _currentTopic = title;
            _aiPersona = title.contains('Restaurant')
                ? 'Restaurant Server'
                : title.contains('Hotel')
                    ? 'Hotel Receptionist'
                    : title.contains('Shopping')
                        ? 'Shop Assistant'
                        : title.contains('Airport')
                            ? 'Airport Staff'
                            : title.contains('Doctor')
                                ? 'Doctor'
                                : 'Interviewer';
            _messages.clear();
          });
          Navigator.pop(context);
          _initializeConversation();
        },
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? translation;
  final String? pronunciation;
  final MessageCorrection? correction;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.translation,
    this.pronunciation,
    this.correction,
  });
}

class MessageCorrection {
  final String original;
  final String corrected;
  final String explanation;

  MessageCorrection({
    required this.original,
    required this.corrected,
    required this.explanation,
  });
}
