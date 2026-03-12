import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../animations/page_transitions.dart';
import '../animations/success_animations.dart';
import '../widgets/skeleton_loaders.dart';

/// Comprehensive demo screen showcasing all micro-interactions
class AnimationDemoScreen extends StatefulWidget {
  const AnimationDemoScreen({super.key});

  @override
  State<AnimationDemoScreen> createState() => _AnimationDemoScreenState();
}

class _AnimationDemoScreenState extends State<AnimationDemoScreen> {
  bool _isLoading = false;
  bool _showSuccess = false;
  bool _showFailure = false;
  bool _showCelebration = false;
  bool _showStreak = false;
  bool _showAchievement = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Micro-Interactions Demo'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Page Transitions'),
            _buildPageTransitionsSection(),
            const SizedBox(height: 32),
            
            _buildSectionTitle('Success States'),
            _buildSuccessStatesSection(),
            const SizedBox(height: 32),
            
            _buildSectionTitle('Skeleton Loading'),
            _buildSkeletonLoadingSection(),
            const SizedBox(height: 32),
            
            _buildSectionTitle('Celebrations'),
            _buildCelebrationsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==================== PAGE TRANSITIONS ====================

  Widget _buildPageTransitionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTransitionButton('Fade Transition', () {
            Navigator.push(
              context,
              PageTransitions.fade(const _DemoDetailScreen('Fade')),
            );
          }),
          _buildTransitionButton('Slide Right', () {
            Navigator.push(
              context,
              PageTransitions.slideRight(const _DemoDetailScreen('Slide Right')),
            );
          }),
          _buildTransitionButton('Slide Up (Modal)', () {
            Navigator.push(
              context,
              PageTransitions.slideUp(const _DemoDetailScreen('Slide Up')),
            );
          }),
          _buildTransitionButton('Scale Transition', () {
            Navigator.push(
              context,
              PageTransitions.scale(const _DemoDetailScreen('Scale')),
            );
          }),
          _buildTransitionButton('Shared Axis', () {
            Navigator.push(
              context,
              PageTransitions.sharedAxis(const _DemoDetailScreen('Shared Axis')),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransitionButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        child: Text(label),
      ),
    );
  }

  // ==================== SUCCESS STATES ====================

  Widget _buildSuccessStatesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _showSuccess = true);
                    HapticFeedback.mediumImpact();
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _showSuccess = false);
                    });
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Success'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _showFailure = true);
                    HapticFeedback.heavyImpact();
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _showFailure = false);
                    });
                  },
                  icon: const Icon(Icons.error),
                  label: const Text('Failure'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_showSuccess)
            SuccessAnimation(
              message: 'Correct!',
              onComplete: () => setState(() => _showSuccess = false),
            ),
          if (_showFailure)
            FailureAnimation(
              message: 'Try Again',
              onComplete: () => setState(() => _showFailure = false),
            ),
        ],
      ),
    );
  }

  // ==================== SKELETON LOADING ====================

  Widget _buildSkeletonLoadingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _isLoading = !_isLoading),
                child: Text(_isLoading ? 'Stop Loading' : 'Show Loading'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading) ...[
            const SkeletonVocabularyCard(),
            const SizedBox(height: 16),
            const SkeletonStoryCard(),
            const SizedBox(height: 16),
            const SkeletonStats(),
          ] else
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Content Loaded! 🎉'),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== CELEBRATIONS ====================

  Widget _buildCelebrationsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() => _showCelebration = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _showCelebration = false);
                  });
                },
                child: const Text('Confetti'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _showStreak = true);
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) setState(() => _showStreak = false);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Streak'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _showAchievement = true);
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) setState(() => _showAchievement = false);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
                child: const Text('Achievement'),
              ),
            ],
          ),
          const SizedBox(height: 200),
          if (_showCelebration)
            CelebrationAnimation(
              onComplete: () => setState(() => _showCelebration = false),
            ),
          if (_showStreak)
            StreakAnimation(
              streak: 30,
              onComplete: () => setState(() => _showStreak = false),
            ),
          if (_showAchievement)
            AchievementUnlockAnimation(
              title: 'Grammar Guru',
              icon: '📚',
              color: Colors.purple,
              onComplete: () => setState(() => _showAchievement = false),
            ),
        ],
      ),
    );
  }
}

class _DemoDetailScreen extends StatelessWidget {
  final String transitionType;

  const _DemoDetailScreen(this.transitionType);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$transitionType Transition'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.animation,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              transitionType,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Smooth page transition complete!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
