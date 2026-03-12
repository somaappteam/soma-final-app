import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/study_models.dart';
import '../../services/haptic_feedback_service.dart';
import '../../theme/app_theme.dart';

class StoryReaderScreen extends StatefulWidget {
  final Story story;
  final UserStoryProgress? progress;

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
  
  StoryAnnotation? _selectedAnnotation;
  bool _showAnnotationPanel = false;
  
  List<StoryBookmark> _bookmarks = [];
  List<StoryNote> _notes = [];
  
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _hapticService.initialize();
    
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
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
                    color: Colors.white.withOpacity(0.1),
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
                    color: Colors.white.withOpacity(0.1),
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.story.estimatedReadTime} min',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.story.difficultyColor.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.story.difficultyDisplay,
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
                    if (widget.story.nativeTitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.story.nativeTitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
              _hapticService.toggle();
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryTeal.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: AppColors.primaryTeal)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.primaryTeal : AppColors.textMedium,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primaryTeal : AppColors.textMedium,
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
    final sortedAnnotations = List<StoryAnnotation>.from(widget.story.annotations)
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));
    
    for (final annotation in sortedAnnotations) {
      // Add plain text before annotation
      if (annotation.startOffset > lastEnd) {
        segments.add(TextSegment(
          text: widget.story.content.substring(lastEnd, annotation.startOffset),
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
    if (lastEnd < widget.story.content.length) {
      segments.add(TextSegment(
        text: widget.story.content.substring(lastEnd),
      ));
    }
    
    return segments;
  }

  Widget _buildAnnotatedSegment(TextSegment segment) {
    return GestureDetector(
      onTap: () => _showAnnotation(segment.annotation!),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: const Border(
            bottom: BorderSide(
              color: AppColors.primaryTeal,
              width: 2,
            ),
          ),
        ),
        child: Text(
          segment.text,
          style: TextStyle(
            fontSize: _fontSize,
            height: 1.8,
            color: AppColors.primaryTeal,
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

  void _showAnnotation(StoryAnnotation annotation) {
    _hapticService.lightImpact();
    setState(() {
      _selectedAnnotation = annotation;
      _showAnnotationPanel = true;
    });
  }

  Widget _buildAnnotationPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
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
                    color: AppColors.primaryTeal.withOpacity(0.1),
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
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school, color: Colors.purple, size: 20),
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
                backgroundColor: Colors.purple.withOpacity(0.1),
                side: BorderSide(color: Colors.purple.withOpacity(0.3)),
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
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.translate, color: Colors.blue, size: 20),
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
                backgroundColor: Colors.blue.withOpacity(0.1),
                side: BorderSide(color: Colors.blue.withOpacity(0.3)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComprehensionSection() {
    if (widget.story.questions.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.quiz, color: Colors.green),
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
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(option),
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
  final StoryAnnotation? annotation;

  TextSegment({
    required this.text,
    this.annotation,
  });
}
