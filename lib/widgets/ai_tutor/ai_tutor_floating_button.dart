import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_tutor_provider.dart';
import '../../models/ai_conversation.dart';
import '../../theme/app_theme.dart';

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
    if (onPressed != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: const Icon(Icons.smart_toy, color: AppColors.textOnDark),
        label: const Text('Ask AI', style: TextStyle(color: AppColors.textOnDark)),
        backgroundColor: Theme.of(context).primaryColor,
      );
    }

    if (!hasContext) return const SizedBox.shrink();

    return Consumer<AITutorProvider>(
      builder: (context, aiProvider, child) {
        return FloatingActionButton.extended(
          onPressed: () => _showAITutor(context, aiProvider),
          icon: const Icon(Icons.smart_toy, color: AppColors.textOnDark),
          label: const Text('Ask AI', style: TextStyle(color: AppColors.textOnDark)),
          backgroundColor: Theme.of(context).primaryColor,
        );
      },
    );
  }

  void _showAITutor(BuildContext context, AITutorProvider aiProvider) {
    aiProvider.setLearningContext(
      lessonId: lessonId,
      vocabularyId: vocabularyId,
      grammarRuleId: grammarRuleId,
      content: content,
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkCard : AppColors.surface;
    final inputBg = isDark ? AppColors.darkElevated : AppColors.neutralLight;
    final borderColor = isDark ? AppColors.darkTextTertiary.withValues(alpha: 0.3) : AppColors.neutralMid.withValues(alpha: 0.4);

    return Consumer<AITutorProvider>(
      builder: (context, aiProvider, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    Icon(Icons.smart_toy, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('AI Tutor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    if (aiProvider.remainingRequests < 20)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: aiProvider.remainingRequests < 5 ? AppColors.error : AppColors.warning,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${aiProvider.remainingRequests} left',
                          style: const TextStyle(color: AppColors.textOnDark, fontSize: 12),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Context chips
              if (aiProvider.currentVocabularyId != null) _buildContextChip('Vocabulary Help', context),
              if (aiProvider.currentGrammarRuleId != null) _buildContextChip('Grammar Help', context),
              if (aiProvider.currentLessonId != null) _buildContextChip('Lesson Help', context),

              // Error message
              if (aiProvider.error != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(aiProvider.error!, style: const TextStyle(color: AppColors.error)),
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
                        itemBuilder: (context, index) => _buildMessageBubble(aiProvider.messages[index]),
                      ),
              ),

              // Loading indicator
              if (aiProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Thinking...'),
                    ],
                  ),
                ),

              // Input area / rate-limit message
              if (aiProvider.isRateLimited)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: inputBg,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_off, color: AppColors.textLight),
                      SizedBox(width: 8),
                      Text(
                        'Daily limit reached. Try again tomorrow.',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: inputBg,
                    border: Border(top: BorderSide(color: borderColor)),
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
                              fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildContextChip(String label, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Chip(
        avatar: Icon(Icons.book, size: 16, color: Theme.of(context).colorScheme.primary),
        label: Text(label),
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy_outlined, size: 64, color: AppColors.neutralMid),
          SizedBox(height: 16),
          Text('Ask me about this content!', style: TextStyle(fontSize: 16, color: AppColors.textMedium)),
          SizedBox(height: 8),
          Text(
            'Examples:\n• "Explain this word"\n• "Give me a hint"\n• "Why is this grammar rule used?"',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIConversation message) {
    final isUser = message.message.isNotEmpty;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryTeal : AppColors.neutralLight,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? message.message : message.response,
              style: TextStyle(color: isUser ? AppColors.textOnDark : AppColors.textDark),
            ),
            if (!isUser && message.response.isNotEmpty) _buildAIResponseExtras(message),
          ],
        ),
      ),
    );
  }

  Widget _buildAIResponseExtras(AIConversation message) {
    return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: []);
  }

  void _sendMessage(AITutorProvider aiProvider) {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    _messageController.clear();
    aiProvider.askQuestion(message, userProficiencyLevel: widget.proficiencyLevel);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }
}

/// Simple AI Tutor Floating Button widget with basic onPressed callback
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
      icon: const Icon(Icons.smart_toy, color: AppColors.textOnDark),
      label: const Text('Ask AI', style: TextStyle(color: AppColors.textOnDark)),
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      tooltip: tooltip ?? 'AI Tutor',
    );
  }
}
