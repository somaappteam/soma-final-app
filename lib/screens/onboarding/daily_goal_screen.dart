import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_widgets.dart';

class DailyGoalScreen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const DailyGoalScreen({
    super.key,
    required this.onboardingData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<DailyGoalScreen> createState() => _DailyGoalScreenState();
}

class _DailyGoalScreenState extends State<DailyGoalScreen> {
  int _selectedGoal = 15;

  final List<Map<String, dynamic>> _goals = [
    {
      'minutes': 5,
      'title': 'Casual',
      'description': '5 min/day',
      'icon': Icons.coffee,
      'color': AppColors.accentCoral,
      'level': 'Relaxed pace',
    },
    {
      'minutes': 15,
      'title': 'Regular',
      'description': '15 min/day',
      'icon': Icons.star,
      'color': AppColors.primaryTeal,
      'level': 'Recommended',
      'isDefault': true,
    },
    {
      'minutes': 30,
      'title': 'Serious',
      'description': '30 min/day',
      'icon': Icons.local_fire_department,
      'color': AppColors.error,
      'level': 'Fast progress',
    },
    {
      'minutes': 60,
      'title': 'Intense',
      'description': '60 min/day',
      'icon': Icons.rocket,
      'color': AppColors.darkAccentPurple,
      'level': 'Maximum learning',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedGoal = 15; // Default
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepWrapper(
      title: 'Daily Learning Goal',
      subtitle: 'How much time can you dedicate each day?',
      onBack: widget.onBack,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final isSelected = _selectedGoal == goal['minutes'];

                return AnimatedCard(
                  delayMs: index * 100,
                  onTap: () => setState(() => _selectedGoal = goal['minutes']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                goal['color'].withValues(alpha: 0.2),
                                goal['color'].withValues(alpha: 0.05),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? goal['color'] : AppColors.neutralLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: goal['color'].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            goal['icon'],
                            color: goal['color'],
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    goal['title'],
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? goal['color'] : AppColors.textDark,
                                    ),
                                  ),
                                  if (goal['isDefault'] == true)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Recommended',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primaryTeal,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                goal['description'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected ? goal['color'].withValues(alpha: 0.8) : AppColors.textMedium,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                goal['level'],
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
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: goal['color'],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Info card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryTeal.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb,
                  color: AppColors.primaryTeal,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'With $_selectedGoal minutes a day, you can reach conversational level in about 6 months!',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(delay: 400.ms),
          
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  widget.onboardingData['daily_goal_minutes'] = _selectedGoal;
                  widget.onNext();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
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
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_ios),
                      color: AppColors.textDark,
                    ),
                ],
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
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
        Expanded(child: child),
      ],
    );
  }
}
