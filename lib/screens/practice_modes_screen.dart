import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/vocabulary_item.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../services/csv_data_service.dart';
import '../theme/app_theme.dart';
import 'games/falling_words_launcher.dart';
import 'games/word_match_game.dart';
import 'practice/flashcards_screen.dart';
import 'practice/vocabulary_quiz_screen.dart';
import 'practice/fill_in_blank_screen.dart';
import 'practice/listening_practice_screen.dart';
import 'practice/speed_challenge_screen.dart';
import 'practice/pronunciation_practice_screen.dart';
import 'practice_modes/sentence_completion_screen.dart';
import 'auth/register_screen.dart';

class PracticeModesScreen extends StatefulWidget {
  const PracticeModesScreen({super.key});

  @override
  State<PracticeModesScreen> createState() => _PracticeModesScreenState();
}

class _PracticeModesScreenState extends State<PracticeModesScreen> {
  bool _isLoading = true;
  List<VocabularyItem> _vocabulary = [];
  List<String> _concepts = [];
  String? _selectedConcept;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  Future<void> _loadVocabulary() async {
    try {
      final courseProvider = context.read<CourseProvider>();
      final activeCourse = courseProvider.activeCourse;
      
      if (activeCourse != null) {
        final csvService = CsvDataService();
        
        // Fetch concepts if not already fetched
        if (_concepts.isEmpty) {
          final concepts = await csvService.getConcepts(
            activeCourse.targetLanguage, 
            activeCourse.nativeLanguage,
          );
          _concepts = concepts;
          if (_concepts.isNotEmpty && _selectedConcept == null) {
            _selectedConcept = _concepts.first;
          }
        }

        final vocab = await csvService.getVocabulary(
          activeCourse.targetLanguage, 
          activeCourse.nativeLanguage,
          category: _selectedConcept,
        );
        
        setState(() {
          _vocabulary = vocab;
          _isLoading = false;
        });
      } else {
        setState(() {
          _vocabulary = _getDemoVocabulary();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _vocabulary = _getDemoVocabulary();
        _isLoading = false;
      });
    }
  }

  List<VocabularyItem> _getDemoVocabulary() {
    // Demo vocabulary for testing
    return [
      VocabularyItem(
        id: '1',
        courseId: 'demo',
        word: 'Hello',
        translation: 'Hola',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '2',
        courseId: 'demo',
        word: 'Goodbye',
        translation: 'Adiós',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '3',
        courseId: 'demo',
        word: 'Thank you',
        translation: 'Gracias',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '4',
        courseId: 'demo',
        word: 'Please',
        translation: 'Por favor',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '5',
        courseId: 'demo',
        word: 'Water',
        translation: 'Agua',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '6',
        courseId: 'demo',
        word: 'Food',
        translation: 'Comida',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isGuest = authProvider.isGuest;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Practice Modes',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),
                if (isGuest)
                  SliverToBoxAdapter(
                    child: _buildGuestBanner(context),
                  ),
                if (_concepts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildConceptSelector(),
                  ),
                SliverToBoxAdapter(
                  child: _buildPracticeModesList(context, isGuest),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.tealGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your Practice',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_vocabulary.length} words available',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildGuestBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A65), Color(0xFFFF6E40)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Guest Mode Limitations',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Limited to basic practice modes\n• Progress not saved\n• No achievements or leaderboards\n• Create an account to unlock all features!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(delay: 100.ms);
  }

  Widget _buildConceptSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Concept',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _concepts.map((concept) {
                final isSelected = _selectedConcept == concept;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(concept),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected && _selectedConcept != concept) {
                        setState(() {
                          _selectedConcept = concept;
                          _isLoading = true;
                        });
                        _loadVocabulary();
                      }
                    },
                    selectedColor: AppColors.primaryTeal.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryTeal : AppColors.textMedium,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryTeal : Colors.grey.shade300,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(delay: 50.ms);
  }

  Widget _buildPracticeModesList(BuildContext context, bool isGuest) {
    final modes = [
      {
        'name': 'Falling Words',
        'description': 'Catch falling words and match translations',
        'icon': Icons.arrow_downward,
        'color': Colors.purple,
        'available': true,
        'isNew': true,
        'onTap': () => _launchFallingWords(context),
      },
      {
        'name': 'Word Match',
        'description': 'Match words with their translations',
        'icon': Icons.compare_arrows,
        'color': Colors.teal,
        'available': true,
        'isNew': true,
        'onTap': () => _launchWordMatch(context),
      },
      {
        'name': 'Vocabulary Quiz',
        'description': 'Test your knowledge with multiple choice',
        'icon': Icons.quiz,
        'color': AppColors.primaryTeal,
        'available': true,
        'isNew': false,
        'onTap': () => _launchVocabularyQuiz(context),
      },
      {
        'name': 'Flashcards',
        'description': 'Review words with flashcards',
        'icon': Icons.style,
        'color': Colors.orange,
        'available': !isGuest,
        'isNew': false,
        'onTap': isGuest ? () => _showGuestRestriction(context) : () => _launchFlashcards(context),
      },
      {
        'name': 'Fill in Blank',
        'description': 'Complete sentences with missing words',
        'icon': Icons.edit_note,
        'color': Colors.indigo,
        'available': !isGuest,
        'isNew': false,
        'onTap': isGuest ? () => _showGuestRestriction(context) : () => _launchFillInBlank(context),
      },
      {
        'name': 'Sentence Completion',
        'description': 'Build sentences word by word',
        'icon': Icons.wrap_text,
        'color': Colors.deepOrange,
        'available': !isGuest,
        'isNew': true,
        'onTap': isGuest ? () => _showGuestRestriction(context) : () => _launchSentenceCompletion(context),
      },
      {
        'name': 'Listening Practice',
        'description': 'Listen and type what you hear',
        'icon': Icons.hearing,
        'color': AppColors.accentOrange,
        'available': !isGuest,
        'isNew': false,
        'onTap': isGuest ? () => _showGuestRestriction(context) : () => _launchListeningPractice(context),
      },
      {
        'name': 'Pronunciation',
        'description': 'Practice speaking with AI feedback',
        'icon': Icons.mic,
        'color': Colors.blue,
        'available': !isGuest,
        'isNew': false,
        'onTap': isGuest ? () => _showGuestRestriction(context) : () => _launchPronunciation(context),
      },
      {
        'name': 'Speed Challenge',
        'description': 'Race against time to answer questions',
        'icon': Icons.speed,
        'color': Colors.red,
        'available': !isGuest,
        'isNew': false,
        'onTap': isGuest ? () => _showGuestRestriction(context) : () => _launchSpeedChallenge(context),
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: modes.map((mode) {
          final index = modes.indexOf(mode);
          return _buildModeCard(mode, index);
        }).toList(),
      ),
    );
  }

  Widget _buildModeCard(Map<String, dynamic> mode, int index) {
    final isAvailable = mode['available'] as bool;
    final isNew = mode['isNew'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedCard(
        delayMs: index * 100,
        onTap: isAvailable ? mode['onTap'] as VoidCallback? : null,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAvailable 
                  ? (mode['color'] as Color).withValues(alpha: 0.3)
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? (mode['color'] as Color).withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  mode['icon'] as IconData,
                  color: isAvailable ? mode['color'] as Color : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mode['name'] as String,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isAvailable 
                                ? AppColors.textDark 
                                : Colors.grey,
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode['description'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: isAvailable 
                            ? AppColors.textMedium 
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isAvailable)
                const Icon(
                  Icons.lock,
                  color: Colors.grey,
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: mode['color'] as Color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchFallingWords(BuildContext context) {
    if (_vocabulary.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => FallingWordsLauncher(
        vocabulary: _vocabulary,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
  }

  void _launchWordMatch(BuildContext context) {
    if (_vocabulary.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => WordMatchLauncher(
        vocabulary: _vocabulary,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
  }

  void _launchVocabularyQuiz(BuildContext context) {
    if (_vocabulary.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => VocabularyQuizScreen(
        vocabulary: _vocabulary,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
  }

  void _launchFlashcards(BuildContext context) {
    if (_vocabulary.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => FlashcardsScreen(
        vocabulary: _vocabulary,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
  }

  Future<void> _launchFillInBlank(BuildContext context) async {
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    setState(() { _isLoading = true; });

    final csvService = CsvDataService();
    final sentences = await csvService.getSentences(
      activeCourse.targetLanguage,
      activeCourse.nativeLanguage,
      categoryConceptIds: _selectedConcept,
    );

    setState(() { _isLoading = false; });

    if (sentences.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sentences available for Fill in Blank'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => FillInBlankScreen(
          sentences: sentences,
          targetLanguage: activeCourse.targetLanguage,
          nativeLanguage: activeCourse.nativeLanguage,
        ),
      ));
    }
  }

  void _launchListeningPractice(BuildContext context) {
    if (_vocabulary.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ListeningPracticeScreen(
        vocabulary: _vocabulary,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
  }

  void _launchSpeedChallenge(BuildContext context) {
    if (_vocabulary.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => SpeedChallengeScreen(
        vocabulary: _vocabulary,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
  }

  void _launchPronunciation(BuildContext context) {
    if (_vocabulary.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => PronunciationPracticeScreen(
        vocabulary: _vocabulary,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
  }

  Future<void> _launchSentenceCompletion(BuildContext context) async {
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    setState(() {
      _isLoading = true;
    });
    
    // Fetch sentences for the chosen concept
    final csvService = CsvDataService();
    final sentences = await csvService.getSentences(
      activeCourse.targetLanguage,
      activeCourse.nativeLanguage,
      categoryConceptIds: _selectedConcept,
    );

    setState(() {
      _isLoading = false;
    });

    if (sentences.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sentences available for this concept'), backgroundColor: Colors.orange,),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => SentenceCompletionScreen(
          sentences: sentences,
          targetLanguage: activeCourse.targetLanguage,
          nativeLanguage: activeCourse.nativeLanguage,
        ),
      ));
    }
  }

  void _showGuestRestriction(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'This practice mode is only available for registered users. '
          'Create a free account to unlock all practice modes and save your progress!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to registration
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }
}

class AnimatedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final int delayMs;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: child.animate()
        .fadeIn(delay: Duration(milliseconds: delayMs))
        .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: delayMs)),
    );
  }
}

