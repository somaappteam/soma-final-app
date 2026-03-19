import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../providers/course_provider.dart';
import '../../models/course_model.dart';
import '../main_navigation_screen.dart';

class OnboardingCompleteScreen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;

  const OnboardingCompleteScreen({
    super.key,
    required this.onboardingData,
  });

  @override
  State<OnboardingCompleteScreen> createState() => _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends State<OnboardingCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _confettiController.forward();

    // Save onboarding data after a delay to allow animation to start
    _saveOnboardingData();
  }

  Future<void> _saveOnboardingData() async {
    try {
      await _userService.saveOnboardingData(widget.onboardingData);
    } catch (e) {
      debugPrint('Error saving onboarding data: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await _savePersonalizedPracticeDefaults(prefs);
    await prefs.setBool('onboarding_completed', true);
  }

  Future<void> _savePersonalizedPracticeDefaults(SharedPreferences prefs) async {
    final targetData = widget.onboardingData['target_language'];
    final nativeData = widget.onboardingData['native_language'];
    
    String targetLanguage = 'es';
    String nativeLanguage = 'en';

    if (targetData is LanguageModel) {
      targetLanguage = targetData.code;
    } else if (targetData is String) {
      targetLanguage = targetData;
    }

    if (nativeData is LanguageModel) {
      nativeLanguage = nativeData.code;
    } else if (nativeData is String) {
      nativeLanguage = nativeData;
    }

    final proficiency =
        (widget.onboardingData['proficiency_level'] ?? 'beginner').toString().toLowerCase();
    final learningStyle =
        (widget.onboardingData['learning_style'] ?? 'vocabulary').toString().toLowerCase();

    final defaultDifficulty = switch (proficiency) {
      'advanced' => 'advanced',
      'intermediate' => 'intermediate',
      _ => 'beginner',
    };

    String sentenceCategory = 'all';
    String vocabCategory = 'all';
    bool autoDifficulty = true;

    if (learningStyle == 'speaking') {
      sentenceCategory = 'greetings';
      autoDifficulty = false;
    } else if (learningStyle == 'sentences') {
      sentenceCategory = 'travel';
    } else {
      vocabCategory = 'action';
    }

    final key = 'practice_session_config_default_${targetLanguage}_$nativeLanguage';

    await prefs.setString(
      key,
      '{"vocabulary":{"difficulty":"$defaultDifficulty","partOfSpeech":"all","category":"$vocabCategory","questionCount":10,"reviewQueue":"all","autoDifficultyEnabled":$autoDifficulty},"sentences":{"difficulty":"$defaultDifficulty","category":"$sentenceCategory","questionCount":10,"autoDifficultyEnabled":$autoDifficulty}}',
    );
  }

  Future<void> _createCourseAndNavigate() async {
    final targetData = widget.onboardingData['target_language'];
    final nativeData = widget.onboardingData['native_language'];
    
    String targetCode = 'es';
    String nativeCode = 'en';

    if (targetData is LanguageModel) {
      targetCode = targetData.code;
    } else if (targetData is String) {
      targetCode = targetData;
    }

    if (nativeData is LanguageModel) {
      nativeCode = nativeData.code;
    } else if (nativeData is String) {
      nativeCode = nativeData;
    }

    try {
      final courseProvider = context.read<CourseProvider>();
      await courseProvider.addCourse(
        nativeLanguage: nativeCode,
        targetLanguage: targetCode,
      );
    } catch (e) {
      debugPrint('Error creating course during onboarding: $e');
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          Positioned.fill(
            child: SuccessConfettiAnimation(
              controller: _confettiController,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: AppColors.tealGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 80,
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .shake(delay: 600.ms, duration: 400.ms),
                  const SizedBox(height: 40),
                  const Text(
                    'You\'re All Set!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.3, end: 0, delay: 300.ms),
                  const SizedBox(height: 16),
                  const Text(
                    'Your personalized learning journey is ready. Let\'s start learning!',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textMedium,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 500.ms)
                      .slideY(begin: 0.3, end: 0, delay: 500.ms),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          icon: Icons.language,
                          label: 'Learning',
                          value: _getLanguageName(widget.onboardingData['target_language']),
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          icon: Icons.trending_up,
                          label: 'Level',
                          value: widget.onboardingData['proficiency_level']
                                  ?.toString()
                                  .toUpperCase() ??
                              'BEGINNER',
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          icon: Icons.schedule,
                          label: 'Daily Goal',
                          value: '${widget.onboardingData['daily_goal_minutes']} min',
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 700.ms)
                      .slideY(begin: 0.3, end: 0, delay: 700.ms),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _createCourseAndNavigate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.primaryTeal.withValues(alpha: 0.4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start Learning',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.rocket_launch, size: 24),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 900.ms)
                      .slideY(begin: 0.5, end: 0, delay: 900.ms),
                  const SizedBox(height: 20),
                  const Text(
                    'First lesson starts in 3... 2... 1...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ).animate().fadeIn(delay: 1100.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryTeal,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getLanguageName(String? code) {
    final languages = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'ru': 'Russian',
      'ar': 'Arabic',
      'hi': 'Hindi',
    };
    return languages[code] ?? code?.toUpperCase() ?? 'Unknown';
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
}

class SuccessConfettiAnimation extends StatelessWidget {
  final AnimationController controller;

  const SuccessConfettiAnimation({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ConfettiPainter(
            progress: controller.value,
          ),
        );
      },
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;

  ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      AppColors.error,
      AppColors.primaryTeal,
      AppColors.success,
      Colors.yellow,
      AppColors.darkAccentPurple,
      AppColors.accentCoral,
    ];

    final random = progress * 100;

    for (int i = 0; i < 50; i++) {
      final x = (i * 37 + random * 10) % size.width;
      final y = ((i * 23 + random * 50) % size.height) * (1 - progress);
      final color = colors[i % colors.length];

      final paint = Paint()
        ..color = color.withValues(alpha: 1 - progress)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        5 + (i % 5).toDouble(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
