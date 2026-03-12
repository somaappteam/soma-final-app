import 'package:flutter/material.dart';
import '../../services/tts_service.dart';

/// Writing Practice Mode with AI feedback
/// Write sentences and get AI-powered corrections
class WritingPracticeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> sentences;
  final String targetLanguage;
  final String nativeLanguage;

  const WritingPracticeScreen({
    super.key,
    required this.sentences,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<WritingPracticeScreen> createState() => _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends State<WritingPracticeScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitted = false;
  bool _isLoading = false;
  int _score = 0;
  int _currentIndex = 0;
  
  String _aiFeedback = '';
  List<GrammarCorrection> _corrections = [];
  
  @override
  void dispose() {
    TtsService().stop();
    _controller.dispose();
    super.dispose();
  }
  void _submitWriting() {
    if (_controller.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    // Simulate AI analysis
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
        _isSubmitted = true;
        
        // Demo corrections
        _corrections = [
          GrammarCorrection(
            original: 'yo soy',
            corrected: 'soy',
            explanation: 'Personal pronouns are often omitted in Spanish',
            type: CorrectionType.style,
          ),
          GrammarCorrection(
            original: 'muy bien',
            corrected: 'muy bueno',
            explanation: 'Use "bueno" for things, "bien" for actions',
            type: CorrectionType.grammar,
          ),
        ];
        
        _aiFeedback = 'Great effort! Your writing shows good understanding of basic grammar. I\'ve identified a few areas for improvement. Keep practicing!';
        _score = 85;
      });
    });
  }

  void _nextPrompt() {
    setState(() {
      _controller.clear();
      _isSubmitted = false;
      _corrections = [];
      _aiFeedback = '';
      _currentIndex = (_currentIndex + 1) % widget.sentences.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sentences.isEmpty) {
       return Scaffold(
          appBar: AppBar(title: const Text('Writing Practice')),
          body: const Center(child: Text('No writing data available')),
       );
    }
    final currentPrompt = widget.sentences[_currentIndex];
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Writing Practice'),
        actions: [
          if (_score > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_score%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.sentences.length,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 24),
              
              // Prompt card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.edit, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Level 1',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Translate to ${widget.targetLanguage}: ${currentPrompt['translation']}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Example:',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    final example = currentPrompt['full_sentence'] as String? ?? '';
                                    if (example.isNotEmpty) {
                                      TtsService().speak(example, languageCode: widget.targetLanguage, context: context);
                                    }
                                  },
                                  child: const Icon(Icons.volume_up, color: Color(0xFF667eea), size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentPrompt['full_sentence'] as String? ?? '',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Writing area
              if (!_isSubmitted)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write your response here...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getScoreColor().withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Writing:',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _controller.text,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // AI Feedback
              if (_isSubmitted) ...[
                // AI Analysis header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Feedback',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _aiFeedback,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Corrections
                if (_corrections.isNotEmpty) ...[
                  Text(
                    'Corrections',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._corrections.map((correction) => _buildCorrectionCard(correction)),
                ],
              ],
              
              const SizedBox(height: 24),
              
              // Action button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _isLoading 
                      ? null 
                      : (_isSubmitted ? _nextPrompt : _submitWriting),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(_isSubmitted ? Icons.arrow_forward : Icons.check),
                  label: Text(
                    _isLoading 
                        ? 'Analyzing...' 
                        : (_isSubmitted ? 'NEXT PROMPT' : 'GET FEEDBACK'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorrectionCard(GrammarCorrection correction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: correction.type == CorrectionType.grammar
            ? Colors.red.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: correction.type == CorrectionType.grammar
              ? Colors.red.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: correction.type == CorrectionType.grammar
                      ? Colors.red.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  correction.type == CorrectionType.grammar ? 'Grammar' : 'Style',
                  style: TextStyle(
                    color: correction.type == CorrectionType.grammar
                        ? Colors.red
                        : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    correction.original,
                    style: const TextStyle(
                      color: Colors.red,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    correction.corrected,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            correction.explanation,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor() {
    if (_score >= 80) return Colors.green;
    if (_score >= 60) return Colors.orange;
    return Colors.red;
  }
}

class GrammarCorrection {
  final String original;
  final String corrected;
  final String explanation;
  final CorrectionType type;

  GrammarCorrection({
    required this.original,
    required this.corrected,
    required this.explanation,
    required this.type,
  });
}

enum CorrectionType {
  grammar,
  style,
  vocabulary,
}
