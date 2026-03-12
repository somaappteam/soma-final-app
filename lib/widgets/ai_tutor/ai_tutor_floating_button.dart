import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_tutor_provider.dart';
import '../../models/ai_conversation.dart';

/// Floating AI Tutor Button
/// Only appears when user is viewing learning content
/// Automatically sets context when tapped
class AITutorFloatingButton extends StatelessWidget {
  final String? lessonId;
  final String? vocabularyId;
  final String? grammarRuleId;
  final Map<String, dynamic>? content;
  final String? languageCode;
  final String? proficiencyLevel;
  final VoidCallback? onPressed;

  const AITutorFloatingButton({
    super.key,
    this.lessonId,
    this.vocabularyId,
    this.grammarRuleId,
    this.content,
    this.languageCode,
    this.proficiencyLevel,
    this.onPressed,
  });

  bool get hasContext => lessonId != null || vocabularyId != null || grammarRuleId != null;

  @override
  Widget build(BuildContext context) {
    // If onPressed is provided, use a simple FAB
    if (onPressed != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: const Icon(Icons.smart_toy, color: Colors.white),
        label: const Text(
          'Ask AI',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      );
    }

    // Otherwise, only show if we have valid context
    if (!hasContext) return const SizedBox.shrink();

    return Consumer<AITutorProvider>(
      builder: (context, aiProvider, child) {
        return FloatingActionButton.extended(
          onPressed: () => _showAITutor(context, aiProvider),
          icon: const Icon(Icons.smart_toy, color: Colors.white),
          label: const Text(
            'Ask AI',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).primaryColor,
        );
      },
    );
  }

  void _showAITutor(BuildContext context, AITutorProvider aiProvider) {
    // Set the learning context
    aiProvider.setLearningContext(
      lessonId: lessonId,
      vocabularyId: vocabularyId,
      grammarRuleId: grammarRuleId,
      content: content,
    );

    // Show AI Tutor sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AITutorChatSheet(
        languageCode: languageCode ?? 'en',
        proficiencyLevel: proficiencyLevel,
      ),
    );
  }
}

/// AI Tutor Chat Sheet
/// Context-aware chat interface
class AITutorChatSheet extends StatefulWidget {
  final String languageCode;
  final String? proficiencyLevel;

  const AITutorChatSheet({
    super.key,
    required this.languageCode,
    this.proficiencyLevel,
  });

  @override
  State<AITutorChatSheet> createState() => _AITutorChatSheetState();
}

class _AITutorChatSheetState extends State<AITutorChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AITutorProvider>(
      builder: (context, aiProvider, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'AI Tutor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Rate limit indicator
                    if (aiProvider.remainingRequests < 20)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: aiProvider.remainingRequests < 5 ? Colors.red : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${aiProvider.remainingRequests} left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Context indicator
              if (aiProvider.currentVocabularyId != null)
                _buildContextChip('Vocabulary Help'),
              if (aiProvider.currentGrammarRuleId != null)
                _buildContextChip('Grammar Help'),
              if (aiProvider.currentLessonId != null)
                _buildContextChip('Lesson Help'),

              // Error message
              if (aiProvider.error != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aiProvider.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => aiProvider.clearError(),
                      ),
                    ],
                  ),
                ),

              // Messages list
              Expanded(
                child: aiProvider.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: aiProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = aiProvider.messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
              ),

              // Loading indicator
              if (aiProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Thinking...'),
                    ],
                  ),
                ),

              // Input area
              if (aiProvider.isRateLimited)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_off, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Daily limit reached. Try again tomorrow.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Ask about this content...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(aiProvider),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton.small(
                          onPressed: aiProvider.isLoading ? null : () => _sendMessage(aiProvider),
                          child: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContextChip(String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Chip(
        avatar: const Icon(Icons.book, size: 16),
        label: Text(label),
        backgroundColor: Colors.deepPurple.shade50,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Ask me about this content!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Examples:\n• "Explain this word"\n• "Give me a hint"\n• "Why is this grammar rule used?"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIConversation message) {
    final isUser = message.message.isNotEmpty; // Simple check
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? message.message : message.response,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
            if (!isUser && message.response.isNotEmpty)
              _buildAIResponseExtras(message),
          ],
        ),
      ),
    );
  }

  Widget _buildAIResponseExtras(AIConversation message) {
    // Parse response for examples
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add pronunciation guide if available
        // Add examples if available
        // These would be parsed from the AI response
      ],
    );
  }

  void _sendMessage(AITutorProvider aiProvider) {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    aiProvider.askQuestion(
      message,
      userProficiencyLevel: widget.proficiencyLevel,
    );

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

/// Simple AI Tutor Floating Button widget with basic onPressed callback
/// This is an alias for backward compatibility
class AiTutorFloatingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const AiTutorFloatingButton({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.smart_toy, color: Colors.white),
      label: const Text(
        'Ask AI',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      tooltip: tooltip ?? 'AI Tutor',
    );
  }
}
