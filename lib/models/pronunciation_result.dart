class PronunciationResult {
  final String id;
  final String userId;
  final String wordOrPhrase;
  final String? audioUrl;
  final int score; // 0-100
  final int accuracyScore;
  final int fluencyScore;
  final int completenessScore;
  final PronunciationFeedback? detailedFeedback;
  final String targetLanguage;
  final String? nativeLanguage;
  final DateTime attemptedAt;

  PronunciationResult({
    required this.id,
    required this.userId,
    required this.wordOrPhrase,
    this.audioUrl,
    required this.score,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    this.detailedFeedback,
    required this.targetLanguage,
    this.nativeLanguage,
    required this.attemptedAt,
  });

  factory PronunciationResult.fromJson(Map<String, dynamic> json) {
    return PronunciationResult(
      id: json['id'],
      userId: json['user_id'],
      wordOrPhrase: json['word_or_phrase'],
      audioUrl: json['audio_url'],
      score: json['score'] ?? 0,
      accuracyScore: json['accuracy_score'] ?? 0,
      fluencyScore: json['fluency_score'] ?? 0,
      completenessScore: json['completeness_score'] ?? 0,
      detailedFeedback: json['pronunciation_feedback'] != null
          ? PronunciationFeedback.fromJson(json['pronunciation_feedback'])
          : null,
      targetLanguage: json['target_language'],
      nativeLanguage: json['native_language'],
      attemptedAt: DateTime.parse(json['attempted_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'word_or_phrase': wordOrPhrase,
      'audio_url': audioUrl,
      'score': score,
      'accuracy_score': accuracyScore,
      'fluency_score': fluencyScore,
      'completeness_score': completenessScore,
      'pronunciation_feedback': detailedFeedback?.toJson(),
      'target_language': targetLanguage,
      'native_language': nativeLanguage,
      'attempted_at': attemptedAt.toIso8601String(),
    };
  }

  String get grade {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  String get feedback {
    if (score >= 90) return 'Excellent! Native-like pronunciation.';
    if (score >= 80) return 'Great job! Minor improvements needed.';
    if (score >= 70) return 'Good attempt. Keep practicing!';
    if (score >= 60) return 'Getting there. Focus on clarity.';
    return 'Keep practicing! Try listening to the native audio.';
  }
}

class PronunciationFeedback {
  final List<PhonemeFeedback> phonemes;
  final List<SyllableFeedback> syllables;
  final String? overallNotes;
  final List<String> tips;

  PronunciationFeedback({
    this.phonemes = const [],
    this.syllables = const [],
    this.overallNotes,
    this.tips = const [],
  });

  factory PronunciationFeedback.fromJson(Map<String, dynamic> json) {
    return PronunciationFeedback(
      phonemes: (json['phonemes'] as List? ?? [])
          .map((p) => PhonemeFeedback.fromJson(p))
          .toList(),
      syllables: (json['syllables'] as List? ?? [])
          .map((s) => SyllableFeedback.fromJson(s))
          .toList(),
      overallNotes: json['overall_notes'],
      tips: List<String>.from(json['tips'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phonemes': phonemes.map((p) => p.toJson()).toList(),
      'syllables': syllables.map((s) => s.toJson()).toList(),
      'overall_notes': overallNotes,
      'tips': tips,
    };
  }
}

class PhonemeFeedback {
  final String phoneme;
  final int score;
  final String? expected;
  final String? actual;
  final String? feedback;

  PhonemeFeedback({
    required this.phoneme,
    required this.score,
    this.expected,
    this.actual,
    this.feedback,
  });

  factory PhonemeFeedback.fromJson(Map<String, dynamic> json) {
    return PhonemeFeedback(
      phoneme: json['phoneme'],
      score: json['score'] ?? 0,
      expected: json['expected'],
      actual: json['actual'],
      feedback: json['feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phoneme': phoneme,
      'score': score,
      'expected': expected,
      'actual': actual,
      'feedback': feedback,
    };
  }
}

class SyllableFeedback {
  final String syllable;
  final int score;
  final int stressLevel; // 0=no stress, 1=secondary, 2=primary
  final String? feedback;

  SyllableFeedback({
    required this.syllable,
    required this.score,
    this.stressLevel = 0,
    this.feedback,
  });

  factory SyllableFeedback.fromJson(Map<String, dynamic> json) {
    return SyllableFeedback(
      syllable: json['syllable'],
      score: json['score'] ?? 0,
      stressLevel: json['stress_level'] ?? 0,
      feedback: json['feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'syllable': syllable,
      'score': score,
      'stress_level': stressLevel,
      'feedback': feedback,
    };
  }
}

class PronunciationPracticeItem {
  final String id;
  final String wordOrPhrase;
  final String? translation;
  final String? ipaPronunciation;
  final String? audioUrl;
  final String? exampleSentence;
  final int difficultyLevel;
  final String category;

  PronunciationPracticeItem({
    required this.id,
    required this.wordOrPhrase,
    this.translation,
    this.ipaPronunciation,
    this.audioUrl,
    this.exampleSentence,
    this.difficultyLevel = 1,
    this.category = 'general',
  });

  factory PronunciationPracticeItem.fromJson(Map<String, dynamic> json) {
    return PronunciationPracticeItem(
      id: json['id'],
      wordOrPhrase: json['word_or_phrase'],
      translation: json['translation'],
      ipaPronunciation: json['ipa_pronunciation'],
      audioUrl: json['audio_url'],
      exampleSentence: json['example_sentence'],
      difficultyLevel: json['difficulty_level'] ?? 1,
      category: json['category'] ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word_or_phrase': wordOrPhrase,
      'translation': translation,
      'ipa_pronunciation': ipaPronunciation,
      'audio_url': audioUrl,
      'example_sentence': exampleSentence,
      'difficulty_level': difficultyLevel,
      'category': category,
    };
  }
}
