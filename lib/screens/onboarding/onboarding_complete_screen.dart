import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
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
      // Handle error (e.g., log it or show a snackbar if critical)
      debugPrint('Error saving onboarding data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Confetti animation
          Positioned.fill(
            child: SuccessConfettiAnimation(
              controller: _confettiController,
            ),
          ),
          
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Success icon
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
                  
                  // Title
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
                  
                  // Subtitle
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
                  
                  // Summary card
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
                          value: widget.onboardingData['proficiency_level']?.toString().toUpperCase() ?? 'BEGINNER',
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
                  
                  // Start button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigationScreen(),
                          ),
                          (route) => false,
                        );
                      },
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
                  
                  // Motivational text
                  const Text(
                    'First lesson starts in 3... 2... 1...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 1100.ms),
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

// Simple confetti animation widget
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
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
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
