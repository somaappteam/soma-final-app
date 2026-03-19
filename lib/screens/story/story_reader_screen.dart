import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/story_model.dart';
import '../../models/study_models.dart' as legacy;
import '../../services/haptic_feedback_service.dart';
import '../../theme/app_theme.dart';

class StoryReaderScreen extends StatefulWidget {
  final StoryModel story;
  final legacy.UserStoryProgress? progress;

  const StoryReaderScreen({
    super.key,
    required this.story,
    this.progress,
  });

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  final HapticFeedbackService _hapticService = HapticFeedbackService();
  
  bool _showTranslation = true;
  bool _isPlaying = false;
  double _fontSize = 18;
  int _currentPosition = 0;
  bool _autoScroll = false;
  
  legacy.StoryAnnotation? _selectedAnnotation;
  bool _showAnnotationPanel = false;
  
  List<legacy.StoryBookmark> _bookmarks = [];
  List<legacy.StoryNote> _notes = [];
  
  String _flattenedContent = '';
  List<legacy.StoryAnnotation> _flattenedAnnotations = [];
  
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _hapticService.initialize();
    
    _flattenStory();
    
    if (widget.progress != null) {
      _bookmarks = widget.progress!.bookmarks;
      _notes = widget.progress!.notes;
      _currentPosition = widget.progress!.currentPosition;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentPosition > 0) {
        _scrollToPosition(_currentPosition);
      }
    });
  }

  void _flattenStory() {
    final contentBuffer = StringBuffer();
    final annotations = <legacy.StoryAnnotation>[];
    
    for (final scene in widget.story.scenes) {
      if (scene.narration != null) {
        final start = contentBuffer.length;
        contentBuffer.writeln(scene.narration);
        contentBuffer.writeln();
      }
      
      for (final dialogue in scene.dialogues) {
        final start = contentBuffer.length;
        final dialogueText = '${dialogue.characterId}: ${dialogue.text}';
        contentBuffer.writeln(dialogueText);
        
        // Map vocabulary highlights to annotations if they exist
        if (dialogue.vocabularyToHighlight != null) {
          for (final word in dialogue.vocabularyToHighlight!) {
            final wordStart = dialogueText.indexOf(word);
            if (wordStart != -1) {
              annotations.add(legacy.StoryAnnotation(
                id: 'anno_${annotations.length}',
                word: word,
                text: word,
                translation: dialogue.translation ?? 'No translation available',
                startOffset: start + wordStart,
                endOffset: start + wordStart + word.length,
              ));
            }
          }
        }
        contentBuffer.writeln();
      }
    }
    
    setState(() {
      _flattenedContent = contentBuffer.toString();
      _flattenedAnnotations = annotations;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPosition(int position) {
    // Calculate scroll position based on text position
    // This is a simplified version
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: _buildStoryContent(),
              ),
              SliverToBoxAdapter(
                child: _buildComprehensionSection(),
              ),
            ],
          ),
          if (_showAnnotationPanel && _selectedAnnotation != null)
            _buildAnnotationPanel(),
          _buildFloatingControls(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.story.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.story.estimatedDuration ?? 5} min',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(widget.story.difficultyLevel).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getDifficultyDisplay(widget.story.difficultyLevel),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.story.culturalContext != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.story.culturalContext!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_border),
          onPressed: _showBookmarkDialog,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showStoryOptions,
        ),
      ],
    );
  }

  Widget _buildStoryContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReadingControls(),
          const SizedBox(height: 20),
          _buildAnnotatedText(),
          const SizedBox(height: 30),
          _buildGrammarFocus(),
          const SizedBox(height: 20),
          _buildVocabularyFocus(),
        ],
      ),
    );
  }

  Widget _buildReadingControls() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildControlButton(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            label: _isPlaying ? 'Pause' : 'Play',
            onTap: _toggleAudio,
          ),
          const SizedBox(width: 12),
          _buildControlButton(
            icon: Icons.translate,
            label: 'Translate',
            isActive: _showTranslation,
              onTap: () {
                setState(() => _showTranslation = !_showTranslation);
                _hapticService.lightImpact();
              },
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (_fontSize > 14) {
                    setState(() => _fontSize -= 2);
                  }
                },
              ),
              Text('${(_fontSize).toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_fontSize < 28) {
                    setState(() => _fontSize += 2);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: theme.colorScheme.primary)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnotatedText() {
    // Split content into segments based on annotations
    final segments = _parseContent();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((segment) {
        if (segment.annotation != null) {
          return _buildAnnotatedSegment(segment);
        }
        return _buildPlainSegment(segment.text);
      }).toList(),
    );
  }

  List<TextSegment> _parseContent() {
    final segments = <TextSegment>[];
    var lastEnd = 0;
    
    // Sort annotations by start position
    final sortedAnnotations = List<legacy.StoryAnnotation>.from(_flattenedAnnotations)
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));
    
    for (final annotation in sortedAnnotations) {
      // Add plain text before annotation
      if (annotation.startOffset > lastEnd) {
        segments.add(TextSegment(
          text: _flattenedContent.substring(lastEnd, annotation.startOffset),
        ));
      }
      
      // Add annotated segment
      segments.add(TextSegment(
        text: annotation.text,
        annotation: annotation,
      ));
      
      lastEnd = annotation.endOffset;
    }
    
    // Add remaining plain text
    if (lastEnd < _flattenedContent.length) {
      segments.add(TextSegment(
        text: _flattenedContent.substring(lastEnd),
      ));
    }
    
    return segments;
  }

  Widget _buildAnnotatedSegment(TextSegment segment) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showAnnotation(segment.annotation!),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        child: Text(
          segment.text,
          style: TextStyle(
            fontSize: _fontSize,
            height: 1.8,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPlainSegment(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: _fontSize,
        height: 1.8,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  void _showAnnotation(legacy.StoryAnnotation annotation) {
    _hapticService.lightImpact();
    setState(() {
      _selectedAnnotation = annotation;
      _showAnnotationPanel = true;
    });
  }

  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1: return AppColors.success;
      case 2: return AppColors.primaryTeal;
      case 3: return AppColors.accentCoral;
      case 4: return AppColors.error;
      default: return AppColors.neutralMid;
    }
  }

  String _getDifficultyDisplay(int level) {
    switch (level) {
      case 1: return 'Beginner';
      case 2: return 'Intermediate';
      case 3: return 'Advanced';
      case 4: return 'Expert';
      default: return 'Mixed';
    }
  }

  Widget _buildAnnotationPanel() {
    final theme = Theme.of(context);
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedAnnotation!.text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _showAnnotationPanel = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...[
            _buildAnnotationItem(
              icon: Icons.translate,
              title: 'Translation',
              content: _selectedAnnotation!.translation,
            ),
            const SizedBox(height: 12),
          ],
            if (_selectedAnnotation!.pronunciation != null) ...[
              _buildAnnotationItem(
                icon: Icons.record_voice_over,
                title: 'Pronunciation',
                content: _selectedAnnotation!.pronunciation!,
              ),
              const SizedBox(height: 12),
            ],
            if (_selectedAnnotation!.vocabularyDefinition != null) ...[
              _buildAnnotationItem(
                icon: Icons.menu_book,
                title: 'Definition',
                content: _selectedAnnotation!.vocabularyDefinition!,
              ),
              const SizedBox(height: 12),
            ],
            if (_selectedAnnotation!.grammarNote != null) ...[
              _buildAnnotationItem(
                icon: Icons.school,
                title: 'Grammar Note',
                content: _selectedAnnotation!.grammarNote!,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Add to vocabulary
                      setState(() => _showAnnotationPanel = false);
                      _hapticService.success();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Vocabulary'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 300.ms);
  }

  Widget _buildAnnotationItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textMedium),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrammarFocus() {
    if (widget.story.grammarFocus.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkAccentPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkAccentPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school, color: AppColors.darkAccentPurple, size: 20),
              SizedBox(width: 8),
              Text(
                'Grammar Focus',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.story.grammarFocus.map((grammar) {
              return Chip(
                label: Text(grammar),
                backgroundColor: AppColors.darkAccentPurple.withValues(alpha: 0.1),
                side: BorderSide(color: AppColors.darkAccentPurple.withValues(alpha: 0.3)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyFocus() {
    if (widget.story.vocabularyFocus.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.translate, color: AppColors.primaryTeal, size: 20),
              SizedBox(width: 8),
              Text(
                'Key Vocabulary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.story.vocabularyFocus.map((vocab) {
              return Chip(
                label: Text(vocab),
                backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                side: BorderSide(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComprehensionSection() {
    final theme = Theme.of(context);
    if (widget.story.questions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.quiz, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              const Text(
                'Comprehension Check',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...widget.story.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return _buildQuestionCard(index + 1, question);
          }),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int number, ComprehensionQuestion question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ${question.question}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...question.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final option = entry.value;
            return _buildOptionButton(number, optionIndex, option);
          }),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int questionNumber, int optionIndex, String option) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: () {
          _hapticService.selectionClick();
          // Check answer and show feedback
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          side: const BorderSide(color: AppColors.neutralMid),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(option),
      ),
    );
  }

  Widget _buildReaderSettings() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      color: theme.cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Settings',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildSettingSlider(
            label: 'Font Size',
            value: _fontSize,
            min: 14,
            max: 28,
            divisions: 7,
            onChanged: (value) {
              setState(() {
                _fontSize = value;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSettingToggle(
            label: 'Show Translation',
            value: _showTranslation,
            onChanged: (value) {
              setState(() {
                _showTranslation = value;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSettingToggle(
            label: 'Auto-scroll',
            value: _autoScroll,
            onChanged: (value) {
              setState(() {
                _autoScroll = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSettingToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSceneProgress() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: 0.5, // Replace with actual progress
            backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Scene 1 of 5', // Replace with actual scene info
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingControls() {
    final theme = Theme.of(context);
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildFloatingButton(
              icon: Icons.bookmark_border,
              onTap: _showBookmarkDialog,
            ),
            _buildFloatingButton(
              icon: Icons.note_add,
              onTap: _showNoteDialog,
            ),
            _buildFloatingButton(
              icon: Icons.share,
              onTap: () {},
            ),
            _buildFloatingButton(
              icon: Icons.settings,
              onTap: _showReadingSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, color: AppColors.textMedium),
      onPressed: onTap,
    );
  }

  void _toggleAudio() {
    setState(() => _isPlaying = !_isPlaying);
    _hapticService.buttonPress();
  }

  void _showBookmarkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bookmark'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Add a note (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _hapticService.success();
              Navigator.pop(context);
            },
            child: const Text('Bookmark'),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Write your notes here...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _hapticService.success();
              Navigator.pop(context);
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _showStoryOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.headphones),
              title: const Text('Audio Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Text Size'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Translation Language'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Issue'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showReadingSettings() {
    // Show reading settings dialog
  }
}

class TextSegment {
  final String text;
  final legacy.StoryAnnotation? annotation;

  TextSegment({
    required this.text,
    this.annotation,
  });
}

