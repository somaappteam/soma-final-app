import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import 'completion_screen.dart';

class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({super.key});

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  bool isRecording = false;
  double progress = 0.3;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryTeal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pronunciation',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildInfoChip('Beginner', Icons.person),
                const SizedBox(width: 8),
                _buildInfoChip('Level 10', Icons.star, Colors.amber),
                const SizedBox(width: 8),
                _buildInfoChip('00:02:11', Icons.timer),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(Colors.orange),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Pronunciation',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        size: 80,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 3000.ms),
                  const SizedBox(height: 30),
                  const Text(
                    'Sunglasses',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'suh-n-gla-suhz',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textMedium,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAudioButton(),
                      const SizedBox(width: 20),
                      WaveformBars(isActive: isRecording),
                      const SizedBox(width: 20),
                      const Text(
                        '0:10',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Repeat the word after\npressing the button',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTapDown: (_) => setState(() => isRecording = true),
            onTapUp: (_) {
              setState(() => isRecording = false);
              Future.delayed(const Duration(seconds: 1), () {
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompletionScreen(
                      score: 80,
                      total: 100,
                      quizType: null,
                    ),
                  ),
                );
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isRecording ? 100 : 80,
              height: isRecording ? 100 : 80,
              decoration: BoxDecoration(
                color: isRecording ? Colors.red : AppColors.accentOrange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isRecording ? Colors.red : AppColors.accentOrange)
                        .withValues(alpha: 0.4),
                    blurRadius: isRecording ? 40 : 20,
                    spreadRadius: isRecording ? 10 : 5,
                  ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 40,
              ),
            ),
          )
          .animate(target: isRecording ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.play_arrow,
        color: AppColors.accentOrange,
      ),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }
}

