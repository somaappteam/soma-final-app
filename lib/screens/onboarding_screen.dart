import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import 'onboarding/onboarding_flow_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Learn by Playing',
      'description': 'Gamified lessons that make learning addictive and fun',
      'icon': Icons.videogame_asset,
      'color': AppColors.accentCoral,
    },
    {
      'title': 'Speak Confidently',
      'description': 'AI-powered pronunciation feedback in real-time',
      'icon': Icons.record_voice_over,
      'color': AppColors.accentOrange,
    },
    {
      'title': 'Track Progress',
      'description': 'Detailed analytics and achievement system',
      'icon': Icons.trending_up,
      'color': AppColors.primaryTeal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => _navigateToLanguage(),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.primaryTeal,
                      dotColor: Colors.grey.shade300,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_currentPage == _pages.length - 1)
                    PulsingButton(
                      onPressed: _navigateToLanguage,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page, int index) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  page['color'].withValues(alpha: 0.2),
                  page['color'].withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page['icon'],
              size: 100,
              color: page['color'],
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
          
          const SizedBox(height: 60),
          
          Text(
            page['title'],
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          )
          .animate()
          .fadeIn(delay: 200.ms)
          .slideY(begin: 0.2, end: 0, delay: 200.ms),
          
          const SizedBox(height: 16),
          
          Text(
            page['description'],
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textMedium,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
          .animate()
          .fadeIn(delay: 400.ms)
          .slideY(begin: 0.2, end: 0, delay: 400.ms),
        ],
      ),
    );
  }

  void _navigateToLanguage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

