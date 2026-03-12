import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class LearningStyleScreen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const LearningStyleScreen({
    super.key,
    required this.onboardingData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<LearningStyleScreen> createState() => _LearningStyleScreenState();
}

class _LearningStyleScreenState extends State<LearningStyleScreen> {
  String _selectedStyle = 'vocabulary';

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.onboardingData['learning_style']?.toString() ?? 'vocabulary';
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      ('vocabulary', 'Vocabulary Focus', 'Build strong word recall first', Icons.menu_book),
      ('sentences', 'Sentence Focus', 'Learn through contextual sentence patterns', Icons.notes),
      ('speaking', 'Speaking Focus', 'Prioritize listening and pronunciation', Icons.record_voice_over),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'How do you want to learn?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          const Text(
            'Pick a preferred style. We will preconfigure your first sessions.',
            style: TextStyle(fontSize: 15, color: AppColors.textMedium),
          ),
          const SizedBox(height: 24),
          ...options.map((option) {
            final isSelected = _selectedStyle == option.$1;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primaryTeal : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                leading: Icon(option.$4, color: isSelected ? AppColors.primaryTeal : AppColors.textMedium),
                title: Text(option.$2, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(option.$3),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryTeal) : null,
                onTap: () => setState(() => _selectedStyle = option.$1),
              ),
            );
          }),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onboardingData['learning_style'] = _selectedStyle;
                widget.onNext();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(onPressed: widget.onBack, child: const Text('Back')),
          ),
        ],
      ),
    );
  }
}
