import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/quiz_type.dart';
import '../providers/app_state.dart';
import '../widgets/animated_widgets.dart';
import 'completion_screen.dart';

class QuizScreen extends StatefulWidget {
  final QuizType quizType;
  
  const QuizScreen({super.key, required this.quizType});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> 
    with SingleTickerProviderStateMixin {
  int currentQuestion = 0;
  int score = 0;
  String? selectedAnswer;
  bool isAnswered = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final questions = appState.getQuestions(widget.quizType.id);
    final question = questions[currentQuestion];
    
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (currentQuestion + 1) / questions.length,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(widget.quizType.color),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Question ${currentQuestion + 1}/${questions.length}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (question.hint.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Hint: ${question.hint}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn().slideY(),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final option = question.options[index];
                  final isSelected = selectedAnswer == option;
                  final isCorrect = option == question.correctAnswer;
                  
                  Color getColor() {
                    if (!isAnswered) return Colors.white;
                    if (isCorrect) return Colors.green.shade100;
                    if (isSelected) return Colors.red.shade100;
                    return Colors.white;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnimatedCard(
                      delayMs: index * 50,
                      onTap: isAnswered ? null : () => _selectAnswer(option),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: getColor(),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                                ? widget.quizType.color 
                                : Colors.grey.shade200,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? widget.quizType.color 
                                    : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    color: isSelected 
                                        ? Colors.white 
                                        : AppColors.textMedium,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textDark,
                                  fontWeight: isSelected 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isAnswered && isCorrect)
                              const Icon(Icons.check_circle, color: Colors.green)
                            else if (isAnswered && isSelected)
                              const Icon(Icons.cancel, color: Colors.red),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isAnswered)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _nextQuestion(questions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.quizType.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    currentQuestion < questions.length - 1 
                        ? 'Next Question' 
                        : 'See Results',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().slideY(begin: 1, end: 0),
          ],
        ),
      ),
    );
  }

  void _selectAnswer(String answer) {
    setState(() {
      selectedAnswer = answer;
      isAnswered = true;
      if (answer == context.read<AppState>()
          .getQuestions(widget.quizType.id)[currentQuestion]
          .correctAnswer) {
        score++;
      }
    });
    _controller.forward();
  }

  void _nextQuestion(List questions) {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        isAnswered = false;
      });
      _controller.reset();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CompletionScreen(
            score: score,
            total: questions.length,
            quizType: widget.quizType,
          ),
        ),
      );
    }
  }
}

