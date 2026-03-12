import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_widgets.dart';

class ProficiencySelectionScreen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ProficiencySelectionScreen({
    super.key,
    required this.onboardingData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ProficiencySelectionScreen> createState() => _ProficiencySelectionScreenState();
}

class _ProficiencySelectionScreenState extends State<ProficiencySelectionScreen> {
  String? _selectedLevel;

  final List<Map<String, dynamic>> _levels = [
    {
      'id': 'beginner',
      'title': 'Beginner',
      'subtitle': 'New to the language',
      'description': 'Start from scratch with basics',
      'icon': Icons.school,
      'color': AppColors.success,
    },
    {
      'id': 'elementary',
      'title': 'Elementary',
      'subtitle': 'Know some basics',
      'description': 'Can introduce yourself and ask simple questions',
      'icon': Icons.emoji_objects,
      'color': AppColors.primaryTeal,
    },
    {
      'id': 'intermediate',
      'title': 'Intermediate',
      'subtitle': 'Can hold conversations',
      'description': 'Comfortable with everyday situations',
      'icon': Icons.chat_bubble,
      'color': AppColors.accentOrange,
    },
    {
      'id': 'advanced',
      'title': 'Advanced',
      'subtitle': 'Almost fluent',
      'description': 'Can discuss complex topics and read literature',
      'icon': Icons.auto_stories,
      'color': AppColors.accentCoral,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingStepWrapper(
      title: 'What\'s your level?',
      subtitle: 'This helps us personalize your learning journey',
      onBack: widget.onBack,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: _levels.length,
              itemBuilder: (context, index) {
                final level = _levels[index];
                final isSelected = _selectedLevel == level['id'];

                return AnimatedCard(
                  delayMs: index * 100,
                  onTap: () => setState(() => _selectedLevel = level['id']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                level['color'].withValues(alpha: 0.2),
                                level['color'].withValues(alpha: 0.05),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? level['color'] : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: level['color'].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            level['icon'],
                            color: level['color'],
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level['title'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? level['color'] : AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                level['subtitle'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? level['color'].withValues(alpha: 0.8) : AppColors.textMedium,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                level['description'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: level['color'],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedLevel != null
                    ? () {
                        widget.onboardingData['proficiency_level'] = _selectedLevel;
                        widget.onNext();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
            .animate(target: _selectedLevel != null ? 1 : 0)
            .fadeIn(),
          ),
        ],
      ),
    );
  }
}

class OnboardingStepWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  const OnboardingStepWrapper({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_ios),
                      color: AppColors.textDark,
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: onBack != null 
                          ? CrossAxisAlignment.center 
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
