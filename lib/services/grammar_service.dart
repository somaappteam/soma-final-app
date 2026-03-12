import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/grammar_models.dart';
import 'ai_tutor_service.dart';
import 'supabase_service.dart';

/// High-end Grammar Service for comprehensive grammar teaching system
/// Integrates with AI for personalized learning experiences
class GrammarService {
  static final GrammarService _instance = GrammarService._internal();
  factory GrammarService() => _instance;
  GrammarService._internal();

  final _logger = Logger();
  final _aiService = AITutorService();
  final _supabase = SupabaseService();

  // Cache for grammar content
  final Map<String, List<GrammarSkillNode>> _skillTreeCache = {};
  final Map<String, List<VerbConjugation>> _conjugationCache = {};
  final Map<String, List<SentencePattern>> _patternCache = {};
  final Map<String, GrammarLessonContent> _lessonContentCache = {};

  /// Initialize the grammar service with course-specific content
  Future<void> initialize(String courseId, String targetLanguage, String nativeLanguage) async {
    if (courseId.isEmpty) {
      _logger.d('Skipping GrammarService initialization: No course selected');
      return;
    }
    _logger.i('Initializing GrammarService for course: $courseId');
    // Pre-load essential grammar data
    await Future.wait([
      _loadSkillTree(courseId),
      _loadConjugations(courseId, targetLanguage),
      _loadSentencePatterns(courseId, targetLanguage, nativeLanguage),
    ]);
  }

  // ==================== SKILL TREE MANAGEMENT ====================

  /// Get the complete grammar skill tree for a course
  Future<List<GrammarSkillNode>> getSkillTree(String courseId) async {
    if (_skillTreeCache.containsKey(courseId)) {
      return _skillTreeCache[courseId]!;
    }
    return await _loadSkillTree(courseId);
  }

  Future<List<GrammarSkillNode>> _loadSkillTree(String courseId) async {
    try {
      final response = await _supabase.client
          .from('grammar_skill_tree')
          .select()
          .eq('course_id', courseId);

      final skills = (response as List)
          .map((json) => GrammarSkillNode.fromJson(json))
          .toList();

      _skillTreeCache[courseId] = skills;
      return skills;
    } catch (e) {
      _logger.e('Failed to load grammar skill tree', error: e);
      // Fallback to demo data if Supabase fails
      final demoSkills = _getDemoSkillTree();
      _skillTreeCache[courseId] = demoSkills;
      return demoSkills;
    }
  }

  /// Get user's grammar progress with skill tree status
  Future<List<GrammarSkillNode>> getUserSkillTree(
    String courseId,
    String userId,
  ) async {
    final skillTree = await getSkillTree(courseId);
    return skillTree;
  }

  /// Unlock skills based on prerequisites
  List<GrammarSkillNode> calculateUnlockedSkills(
    List<GrammarSkillNode> skillTree,
    List<String> completedSkillIds,
  ) {
    return skillTree.map((skill) {
      final prerequisitesMet = skill.requires.every(
        (prereq) => completedSkillIds.contains(prereq),
      );
      
      return skill.copyWith(
        isUnlocked: prerequisitesMet || skill.isUnlocked,
      );
    }).toList();
  }

  /// Get skill by ID
  GrammarSkillNode? getSkillById(List<GrammarSkillNode> skillTree, String skillId) {
    try {
      return skillTree.firstWhere((s) => s.id == skillId);
    } catch (e) {
      return null;
    }
  }

  /// Get available skills (unlocked but not completed)
  List<GrammarSkillNode> getAvailableSkills(List<GrammarSkillNode> skillTree) {
    return skillTree.where((s) => s.isUnlocked && !s.isCompleted).toList();
  }

  /// Get recommended next skill
  GrammarSkillNode? getRecommendedSkill(List<GrammarSkillNode> skillTree) {
    final available = getAvailableSkills(skillTree);
    if (available.isEmpty) return null;
    
    // Recommend skill with lowest progress
    available.sort((a, b) => a.progress.compareTo(b.progress));
    return available.first;
  }

  // ==================== CONJUGATION SYSTEM ====================

  /// Get verb conjugations for a language
  Future<List<VerbConjugation>> getConjugations(
    String courseId,
    String language,
  ) async {
    final cacheKey = '${courseId}_$language';
    if (_conjugationCache.containsKey(cacheKey)) {
      return _conjugationCache[cacheKey]!;
    }
    return await _loadConjugations(courseId, language);
  }

  Future<List<VerbConjugation>> _loadConjugations(
    String courseId,
    String language,
  ) async {
    try {
      final response = await _supabase.client
          .from('verb_conjugations')
          .select()
          .eq('course_id', courseId)
          .eq('language', language);

      final conjugations = (response as List)
          .map((json) => VerbConjugation.fromJson(json))
          .toList();

      final cacheKey = '${courseId}_$language';
      _conjugationCache[cacheKey] = conjugations;
      return conjugations;
    } catch (e) {
      _logger.e('Failed to load verb conjugations', error: e);
      // Fallback to demo data
      final demoConjugations = _getDemoConjugations();
      final cacheKey = '${courseId}_$language';
      _conjugationCache[cacheKey] = demoConjugations;
      return demoConjugations;
    }
  }

  /// Get conjugation for specific verb
  VerbConjugation? getConjugationForVerb(
    List<VerbConjugation> conjugations,
    String verb,
  ) {
    try {
      return conjugations.firstWhere((c) => 
        c.infinitive.toLowerCase() == verb.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }

  /// Generate conjugation exercise
  Map<String, dynamic> generateConjugationExercise(VerbConjugation conjugation) {
    final random = Random();
    final tenses = conjugation.conjugations.keys.toList();
    final selectedTense = tenses[random.nextInt(tenses.length)];
    final persons = conjugation.conjugations[selectedTense]!.keys.toList();
    final selectedPerson = persons[random.nextInt(persons.length)];
    
    return {
      'verb': conjugation.infinitive,
      'tense': selectedTense,
      'person': selectedPerson,
      'correctAnswer': conjugation.getConjugation(selectedTense, selectedPerson),
    };
  }

  // ==================== SENTENCE PATTERNS ====================

  /// Get sentence patterns for language pair
  Future<List<SentencePattern>> getSentencePatterns(
    String courseId,
    String targetLanguage,
    String nativeLanguage,
  ) async {
    final cacheKey = '${courseId}_$targetLanguage';
    if (_patternCache.containsKey(cacheKey)) {
      return _patternCache[cacheKey]!;
    }
    return await _loadSentencePatterns(courseId, targetLanguage, nativeLanguage);
  }

  Future<List<SentencePattern>> _loadSentencePatterns(
    String courseId,
    String targetLanguage,
    String nativeLanguage,
  ) async {
    try {
      final response = await _supabase.client
          .from('sentence_patterns')
          .select()
          .eq('course_id', courseId)
          .eq('language', targetLanguage); // Assuming language column for target

      final patterns = (response as List)
          .map((json) => SentencePattern.fromJson(json))
          .toList();

      final cacheKey = '${courseId}_$targetLanguage';
      _patternCache[cacheKey] = patterns;
      return patterns;
    } catch (e) {
      _logger.e('Failed to load sentence patterns', error: e);
      // Fallback to demo data
      final demoPatterns = _getDemoSentencePatterns();
      final cacheKey = '${courseId}_$targetLanguage';
      _patternCache[cacheKey] = demoPatterns;
      return demoPatterns;
    }
  }

  /// Generate sentence building exercise
  Map<String, dynamic> generateSentenceExercise(SentencePattern pattern) {
    return {
      'pattern': pattern.pattern,
      'explanation': pattern.explanation,
      'examples': pattern.examples,
    };
  }

  // ==================== AI-POWERED FEATURES ====================

  /// Get AI explanation for grammar concept
  Future<String> getAIExplanation(
    String concept,
    String targetLanguage,
    String nativeLanguage,
  ) async {
    try {
      final prompt = '''
        Explain the grammar concept "$concept" in $targetLanguage 
        to a learner who speaks $nativeLanguage.
        Be concise but thorough. Use examples.
      ''';
      
      final response = await _aiService.sendMessage(prompt);
      return response;
    } catch (e) {
      _logger.e('Error getting AI explanation: $e');
      return 'Unable to get explanation at this time.';
    }
  }

  /// Get AI feedback on grammar exercise
  Future<Map<String, dynamic>> getAIFeedback(
    String userAnswer,
    String correctAnswer,
    String context,
  ) async {
    try {
      final prompt = '''
        The user answered "$userAnswer" for this grammar exercise.
        The correct answer is "$correctAnswer".
        Context: $context
        
        Provide:
        1. Whether it's correct (true/false)
        2. Brief explanation
        3. Tip for next time
        
        Format as JSON with keys: isCorrect, explanation, tip
      ''';
      
      final response = await _aiService.sendMessage(prompt);
      // Parse JSON response
      return {
        'isCorrect': response.toLowerCase().contains('correct'),
        'explanation': response,
        'tip': 'Keep practicing!',
      };
    } catch (e) {
      _logger.e('Error getting AI feedback: $e');
      return {
        'isCorrect': false,
        'explanation': 'Unable to analyze answer.',
        'tip': 'Try again!',
      };
    }
  }

  /// Check grammar in user text
  Future<List<GrammarErrorPattern>> checkGrammar(String text) async {
    // Demo implementation - would use AI in production
    return _getDemoErrorPatterns();
  }

  // ==================== DEMO DATA ====================

  List<GrammarSkillNode> _getDemoSkillTree() {
    return [
      const GrammarSkillNode(
        id: 'g1',
        title: 'Present Tense',
        description: 'Learn regular verb conjugations in present tense',
        type: GrammarSkillType.conjugation,
        x: 0.5,
        y: 0.0,
        isUnlocked: true,
        color: Colors.blue,
      ),
      const GrammarSkillNode(
        id: 'g2',
        title: 'Articles',
        description: 'Master definite and indefinite articles',
        type: GrammarSkillType.rule,
        x: 0.2,
        y: 0.2,
        requires: ['g1'],
        color: Colors.green,
      ),
      const GrammarSkillNode(
        id: 'g3',
        title: 'Gender Rules',
        description: 'Understanding masculine and feminine nouns',
        type: GrammarSkillType.rule,
        x: 0.8,
        y: 0.2,
        requires: ['g1'],
        color: Colors.purple,
      ),
      const GrammarSkillNode(
        id: 'g4',
        title: 'Prepositions',
        description: 'Common prepositions and their usage',
        type: GrammarSkillType.pattern,
        x: 0.5,
        y: 0.4,
        requires: ['g2', 'g3'],
        color: Colors.orange,
      ),
    ];
  }

  List<VerbConjugation> _getDemoConjugations() {
    return [
      const VerbConjugation(
        infinitive: 'hablar',
        language: 'es',
        conjugations: {
          'present': {
            'yo': 'hablo',
            'tú': 'hablas',
            'él/ella': 'habla',
            'nosotros': 'hablamos',
            'vosotros': 'habláis',
            'ellos': 'hablan',
          },
        },
      ),
      const VerbConjugation(
        infinitive: 'comer',
        language: 'es',
        conjugations: {
          'present': {
            'yo': 'como',
            'tú': 'comes',
            'él/ella': 'come',
            'nosotros': 'comemos',
            'vosotros': 'coméis',
            'ellos': 'comen',
          },
        },
      ),
    ];
  }

  List<SentencePattern> _getDemoSentencePatterns() {
    return [
      const SentencePattern(
        id: 'p1',
        title: 'Subject + Verb',
        pattern: '[Subject] + [Verb]',
        explanation: 'Basic sentence structure with subject and verb',
        examples: ['Yo hablo', 'Ella come', 'Nosotros vivimos'],
      ),
      const SentencePattern(
        id: 'p2',
        title: 'Subject + Verb + Object',
        pattern: '[Subject] + [Verb] + [Object]',
        explanation: 'Complete sentence with direct object',
        examples: ['Yo como manzanas', 'Ella lee libros'],
      ),
    ];
  }

  List<GrammarErrorPattern> _getDemoErrorPatterns() {
    return [
      const GrammarErrorPattern(
        id: 'e1',
        errorType: 'Article Agreement',
        incorrectPattern: 'la libro',
        correctPattern: 'el libro',
        explanation: 'Libro is masculine, so use "el" not "la"',
      ),
    ];
  }
}
