import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'language_selection_step.dart';
import 'proficiency_selection_screen.dart';
import 'daily_goal_screen.dart';
import 'notifications_screen.dart';
import 'onboarding_complete_screen.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final Map<String, dynamic> _onboardingData = {};

  final List<String> _stepTitles = [
    'Select Language',
    'Your Level',
    'Daily Goal',
    'Stay Motivated',
    'Ready to Learn',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _goToNext() {
    if (_currentStep < _stepTitles.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep++);
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            if (_currentStep < _stepTitles.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Step ${_currentStep + 1} of ${_stepTitles.length - 1}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: _goBack,
                            child: const Text('Back'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / (_stepTitles.length - 1),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryTeal,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 1: Language Selection
                  LanguageSelectionStep(
                    onboardingData: _onboardingData,
                    onNext: _goToNext,
                  ),
                  
                  // Step 2: Proficiency Level
                  ProficiencySelectionScreen(
                    onboardingData: _onboardingData,
                    onNext: _goToNext,
                    onBack: _goBack,
                  ),
                  
                  // Step 3: Daily Goal
                  DailyGoalScreen(
                    onboardingData: _onboardingData,
                    onNext: _goToNext,
                    onBack: _goBack,
                  ),
                  
                  // Step 4: Notifications
                  NotificationsScreen(
                    onboardingData: _onboardingData,
                    onNext: _goToNext,
                    onBack: _goBack,
                  ),
                  
                  // Step 5: Complete
                  OnboardingCompleteScreen(
                    onboardingData: _onboardingData,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
