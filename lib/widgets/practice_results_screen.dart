import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';

class PracticeResultsScreen extends StatefulWidget {
  final int correctCount;
  final int totalCount;
  final int xpEarned;
  final int bestStreak;
  final Duration timeElapsed;
  final bool hasMistakes;
  final VoidCallback onReplayMistakes;
  final VoidCallback onContinueToNext;
  final VoidCallback onBackToHome;
  final String title;
  final String subtitle;
  final String replayButtonLabel;

  const PracticeResultsScreen({
    super.key,
    required this.correctCount,
    required this.totalCount,
    required this.xpEarned,
    required this.timeElapsed,
    required this.onReplayMistakes,
    required this.onContinueToNext,
    required this.onBackToHome,
    this.bestStreak = 0,
    this.hasMistakes = true,
    this.title = 'Quiz Complete!',
    this.subtitle = 'Great effort! Keep practicing to improve.',
    this.replayButtonLabel = 'Replay Mistakes',
  });

  @override
  State<PracticeResultsScreen> createState() => _PracticeResultsScreenState();
}

class _PracticeResultsScreenState extends State<PracticeResultsScreen> {
  @override
  void initState() {
    super.initState();
    final isPerfect = widget.correctCount == widget.totalCount && widget.totalCount > 0;
    if (isPerfect) {
      SoundService().playSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPerfect = widget.correctCount == widget.totalCount && widget.totalCount > 0;
    final accuracy = widget.totalCount > 0 ? widget.correctCount / widget.totalCount : 0.0;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildHeader(isPerfect),
              const SizedBox(height: 32),
              _buildResultsStats(context, accuracy, isPerfect),
              const SizedBox(height: 40),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isPerfect) {
    return Column(
      children: [
        if (isPerfect)
          Lottie.network(
            'https://assets9.lottiefiles.com/packages/lf20_touohxv0.json', // Confetti animation
            height: 150,
            repeat: false,
            errorBuilder: (context, error, stackTrace) => _buildFallbackHeaderIcon(isPerfect),
          )
        else
          _buildFallbackHeaderIcon(isPerfect),
        const SizedBox(height: 24),
        Text(
          isPerfect ? 'Perfect Score!' : widget.title,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isPerfect ? AppColors.accentOrange : AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          isPerfect ? 'You got all questions right! Amazing!' : widget.subtitle,
          style: const TextStyle(fontSize: 16, color: AppColors.textMedium),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFallbackHeaderIcon(bool isPerfect) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isPerfect
            ? AppColors.goldGradient
            : AppColors.tealGradient,
        boxShadow: [
          BoxShadow(
            color: (isPerfect ? AppColors.accentOrange : AppColors.primaryTeal).withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        isPerfect ? Icons.emoji_events : Icons.check_circle_outline,
        color: AppColors.textOnDark,
        size: 60,
      ),
    );
  }

  Widget _buildResultsStats(BuildContext context, double accuracy, bool isPerfect) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildResultStatCard(
                  icon: Icons.check_circle,
                  value: '${widget.correctCount}/${widget.totalCount}',
                  label: 'Correct',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultStatCard(
                  icon: Icons.star,
                  value: '${widget.xpEarned}',
                  label: 'XP Earned',
                  color: AppColors.accentOrange,
                ),
              ),
            ],
          ),
          if (widget.bestStreak > 0 || widget.timeElapsed.inSeconds > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildResultStatCard(
                    icon: Icons.local_fire_department,
                    value: '${widget.bestStreak}',
                    label: 'Best Streak',
                    color: AppColors.accentCoral,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResultStatCard(
                    icon: Icons.timer,
                    value: '${widget.timeElapsed.inMinutes}:${(widget.timeElapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                    label: 'Time',
                    color: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Accuracy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(
                    '${(accuracy * 100).round()}%',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isPerfect ? AppColors.accentOrange : AppColors.primaryTeal),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: accuracy,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPerfect ? AppColors.accentOrange : AppColors.primaryTeal,
                  ),
                  minHeight: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.hasMistakes) ...[
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: widget.onReplayMistakes,
              icon: const Icon(Icons.replay),
              label: Text(
                widget.replayButtonLabel,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCoral,
                foregroundColor: AppColors.textOnDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.accentCoral.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: widget.onContinueToNext,
            icon: const Icon(Icons.arrow_forward),
            label: const Text(
              'Continue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: AppColors.textOnDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: AppColors.primaryTeal.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: widget.onBackToHome,
            icon: const Icon(Icons.home),
            label: const Text(
              'Back to Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMedium,
              side: BorderSide(color: AppColors.neutralMid.withValues(alpha: 0.5), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}
