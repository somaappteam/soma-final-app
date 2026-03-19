import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/course_model.dart';
import '../../services/csv_data_service.dart';

class EntranceQuizStep extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  final VoidCallback onComplete;

  const EntranceQuizStep({
    super.key,
    required this.onboardingData,
    required this.onComplete,
  });

  @override
  State<EntranceQuizStep> createState() => _EntranceQuizStepState();
}

class _EntranceQuizStepState extends State<EntranceQuizStep> {
  int _currentQuestionIndex = 0;
  bool _answered = false;
  int? _selectedAnswer;
  int _correctAnswers = 0;
  final int _totalQuestions = 10;
  
  late List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    
    try {
      final targetData = widget.onboardingData['target_language'];
      final nativeData = widget.onboardingData['native_language'];
      
      LanguageModel? targetLang;
      LanguageModel? nativeLang;
      
      if (targetData is LanguageModel) {
        targetLang = targetData;
      } else if (targetData is String) {
        targetLang = LanguageModel.getByCode(targetData);
      }
      
      if (nativeData is LanguageModel) {
        nativeLang = nativeData;
      } else if (nativeData is String) {
        nativeLang = LanguageModel.getByCode(nativeData);
      }
      
      if (targetLang != null && nativeLang != null) {
        debugPrint('EntranceQuizStep: Loading vocabulary for ${targetLang.code} (Native: ${nativeLang.code})');
        final csvService = CsvDataService();
        final vocab = await csvService.getVocabulary(
          targetLang.code,
          nativeLang.code,
          limit: _totalQuestions,
        );
        
        if (vocab.isNotEmpty) {
          debugPrint('EntranceQuizStep: Successfully loaded ${vocab.length} real questions');
          if (mounted) {
            setState(() {
              _questions = vocab.map((item) {
                // Generate 3 random distractors from the same list
                final otherWords = vocab
                    .where((v) => v.id != item.id)
                    .map((v) => v.translation)
                    .toList();
                
                if (otherWords.length < 3) {
                  // Fallback if not enough distractors in real data
                  otherWords.addAll(['Option B', 'Option C', 'Option D']);
                }
                
                otherWords.shuffle();
                
                final options = [item.translation];
                options.addAll(otherWords.take(3));
                options.shuffle();
                
                return {
                  'question': 'How do you say "${item.word}"?',
                  'options': options,
                  'correctIndex': options.indexOf(item.translation),
                };
              }).toList();
              _isLoading = false;
            });
            return;
          }
        } else {
          debugPrint('EntranceQuizStep: CsvDataService returned empty vocabulary for ${targetLang.code}');
        }
      } else {
        debugPrint('EntranceQuizStep: targetLang or nativeLang is null. TargetData: $targetData, NativeData: $nativeData');
      }
      
      // Fallback to mock if failed to load
      debugPrint('EntranceQuizStep: Falling back to mock questions');
      _generateMockQuestions();
    } catch (e) {
      debugPrint('EntranceQuizStep: Error loading questions: $e');
      _generateMockQuestions();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateMockQuestions() {
    final language = widget.onboardingData['target_language'] as LanguageModel?;
    final code = language?.code.toLowerCase() ?? 'en';
    
    // Simple realistic mock words for common languages when real data fails
    Map<String, List<Map<String, dynamic>>> langMockData = {
      'es': [
        {'q': 'Hola', 'a': 'Hello'},
        {'q': 'Gracias', 'a': 'Thank you'},
        {'q': 'Por favor', 'a': 'Please'},
        {'q': 'Adiós', 'a': 'Goodbye'},
        {'q': 'Si', 'a': 'Yes'},
        {'q': 'No', 'a': 'No'},
        {'q': 'Uno', 'a': 'One'},
        {'q': 'Agua', 'a': 'Water'},
        {'q': 'Gato', 'a': 'Cat'},
        {'q': 'Perro', 'a': 'Dog'},
      ],
      'fr': [
        {'q': 'Bonjour', 'a': 'Hello'},
        {'q': 'Merci', 'a': 'Thank you'},
        {'q': 'S\'il vous plaît', 'a': 'Please'},
        {'q': 'Au revoir', 'a': 'Goodbye'},
        {'q': 'Oui', 'a': 'Yes'},
        {'q': 'Non', 'a': 'No'},
        {'q': 'Un', 'a': 'One'},
        {'q': 'Eau', 'a': 'Water'},
        {'q': 'Chat', 'a': 'Cat'},
        {'q': 'Chien', 'a': 'Dog'},
      ],
      'de': [
        {'q': 'Hallo', 'a': 'Hello'},
        {'q': 'Danke', 'a': 'Thank you'},
        {'q': 'Bitte', 'a': 'Please'},
        {'q': 'Tschüss', 'a': 'Goodbye'},
        {'q': 'Ja', 'a': 'Yes'},
        {'q': 'Nein', 'a': 'No'},
        {'q': 'Eins', 'a': 'One'},
        {'q': 'Wasser', 'a': 'Water'},
        {'q': 'Katze', 'a': 'Cat'},
        {'q': 'Hund', 'a': 'Dog'},
      ],
    };

    final mockSet = langMockData[code.split('-')[0]] ?? List.generate(10, (i) => {'q': 'Word $i', 'a': 'Translation $i'});
    
    _questions = mockSet.take(_totalQuestions).map((item) {
      final others = mockSet.where((m) => m != item).map((m) => m['a'] as String).toList();
      others.shuffle();
      final options = [item['a'] as String, ...others.take(3)];
      options.shuffle();
      
      return {
        'question': 'How do you say "${item['q']}"?',
        'options': options,
        'correctIndex': options.indexOf(item['a'] as String),
      };
    }).toList();
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    
    final question = _questions[_currentQuestionIndex];
    final isCorrect = index == question['correctIndex'];

    setState(() {
      _answered = true;
      _selectedAnswer = index;
      if (isCorrect) {
        _correctAnswers++;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (_currentQuestionIndex < _totalQuestions - 1) {
        setState(() {
          _currentQuestionIndex++;
          _answered = false;
          _selectedAnswer = null;
        });
      } else {
        // Store score in onboarding data before completing
        widget.onboardingData['entrance_quiz_score'] = _correctAnswers;
        widget.onboardingData['proficiency_level'] = (_correctAnswers / 2).ceil().clamp(1, 5);
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
    }

    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Could not load quiz questions.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onComplete,
              child: const Text('Finish Onboarding'),
            ),
          ],
        ),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _totalQuestions;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Entrance Quiz',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '${_currentQuestionIndex + 1} / $_totalQuestions',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.neutralLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: AppColors.tealGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    question['question'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                ...List.generate(4, (index) {
                  final isCorrect = index == question['correctIndex'];
                  final isSelected = _selectedAnswer == index;
                  
                  Color bgColor = Colors.white;
                  Color borderColor = AppColors.neutralLight;
                  
                  if (_answered) {
                    if (isCorrect) {
                      bgColor = AppColors.success;
                      borderColor = AppColors.success;
                    } else if (isSelected) {
                      bgColor = AppColors.error;
                      borderColor = AppColors.error;
                    }
                  } else if (isSelected) {
                    borderColor = AppColors.primaryTeal;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _selectAnswer(index),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Row(
                          children: [
                            Text(
                              String.fromCharCode(65 + index),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              question['options'][index],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
