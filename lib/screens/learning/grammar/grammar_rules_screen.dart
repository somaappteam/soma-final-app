import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/grammar_models.dart';
import '../../../services/grammar_service.dart';
import '../../../theme/app_theme.dart';

class GrammarRulesScreen extends StatefulWidget {
  final String? skillId;

  const GrammarRulesScreen({
    super.key,
    this.skillId,
  });

  @override
  State<GrammarRulesScreen> createState() => _GrammarRulesScreenState();
}

class _GrammarRulesScreenState extends State<GrammarRulesScreen> {
  final GrammarService _grammarService = GrammarService();
  bool _isLoading = true;
  GrammarLessonContent? _content;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.skillId == null) {
      setState(() {
        _isLoading = false;
        _error = 'No skill selected';
      });
      return;
    }

    try {
      final content = await _grammarService.getLessonContent(widget.skillId!);
      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_content?.title ?? 'Grammar Rules'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    if (_content == null) return const Center(child: Text('No content found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _content!.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 20),
          Text(
            _content!.body,
            style: TextStyle(
              fontSize: 18,
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ).animate().fadeIn(delay: 200.ms),
          // The LinearProgressIndicator snippet provided in the instruction
          // seems to be misplaced here as it's not syntactically valid within TextStyle.
          // Assuming it was intended to be a separate widget, but without further context,
          // it cannot be correctly integrated while maintaining syntactic correctness
          // and adhering to the "faithfully and without making any unrelated edits" rule.
          // Therefore, it is omitted to prevent a syntax error.
          const SizedBox(height: 40),
          
          if (_content!.examples.isNotEmpty) ...[
            const Text(
              'Examples',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._content!.examples.map((example) => _buildExampleCard(example)),
            const SizedBox(height: 40),
          ],
          
          if (_content!.tips.isNotEmpty) ...[
            const Text(
              'Pro Tips',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._content!.tips.map((tip) => _buildTipCard(tip)),
          ],
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('I Understand', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildExampleCard(String example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(example, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildTipCard(String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentCoral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentCoral.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: AppColors.accentCoral, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

