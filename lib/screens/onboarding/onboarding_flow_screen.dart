import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added this import
import '../../theme/app_theme.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_state.dart';
import '../../models/course_model.dart';
import '../../models/language.dart';
import 'language_selection_step.dart';
import 'entrance_quiz_step.dart';
import '../home/integrated_home_screen.dart';

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
    'Native Language',
    'Language to Learn',
    'Entrance Quiz',
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
    } else {
      _finalizeOnboarding();
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

  Future<void> _finalizeOnboarding() async {
    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal)),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      
      final nativeLang = _onboardingData['native_language'] as LanguageModel;
      final targetLang = _onboardingData['target_language'] as LanguageModel;

      // Ensure a guest user exists
      if (!authProvider.isAuthenticated && !authProvider.isGuest) {
        await authProvider.continueAsGuest();
      }

      // Update languages in auth provider/guest user
      await authProvider.updateLanguages(
        nativeLanguage: nativeLang.code,
        learningLanguages: [targetLang.code],
        activeLanguage: targetLang.code, // Explicitly set active language
      );
      
      // Calculate initial level and XP from proficiency
      final proficiency = (_onboardingData['proficiency_level'] as int?) ?? 1;
      final initialLevel = proficiency;
      final initialXP = (proficiency - 1) * 1000; // Give some starting XP based on level

      // Create and set the active course
      await courseProvider.addCourse(
        nativeLanguage: nativeLang.code,
        targetLanguage: targetLang.code,
        currentLevel: initialLevel,
        totalXP: initialXP,
      );

      // Sync AppState so home screen header shows the correct flag/language
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        final native = Language(nativeLang.code, nativeLang.name, nativeLang.flag, nativeLang.nativeName);
        final target = Language(targetLang.code, targetLang.name, targetLang.flag, targetLang.nativeName);
        appState.selectLanguages(native, target);
      }

      // Mark onboarding as completed so it bypasses next time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);

      // Ensure AuthProvider and CourseProvider are in sync with storage
      if (authProvider.isGuest) {
        await authProvider.refreshGuestUser();
      }
      await courseProvider.loadCourses();

      if (mounted) {
        Navigator.pop(context); // Remove loading
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const IntegratedHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting up your course: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of ${_stepTitles.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_currentStep > 0 && _currentStep < _stepTitles.length - 1)
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
                      value: (_currentStep + 1) / _stepTitles.length,
                      backgroundColor: AppColors.neutralLight,
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
                  // Step 1: Native Language
                  LanguageSelectionStep(
                    isTargetLanguage: false,
                    onboardingData: _onboardingData,
                    onNext: _goToNext,
                  ),
                  
                  // Step 2: Target Language
                  LanguageSelectionStep(
                    isTargetLanguage: true,
                    onboardingData: _onboardingData,
                    onNext: _goToNext,
                  ),
                  
                  // Step 3: Entrance Quiz
                  EntranceQuizStep(
                    onboardingData: _onboardingData,
                    onComplete: _finalizeOnboarding,
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

