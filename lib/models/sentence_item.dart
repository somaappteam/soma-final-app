class SentenceItem {
  final String id;
  final String text;
  final String translation;
  final String? audioUrl;
  final String? difficulty;
  final List<String> concepts;

  SentenceItem({
    required this.id,
    required this.text,
    required this.translation,
    this.audioUrl,
    this.difficulty,
    this.concepts = const [],
  });

  factory SentenceItem.fromMap(Map<String, dynamic> map) {
    return SentenceItem(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? map['sentence']?.toString() ?? '',
      translation: map['translation']?.toString() ?? '',
      audioUrl: map['audio_url']?.toString(),
      difficulty: map['difficulty']?.toString() ?? map['difficulty_level']?.toString(),
      concepts: (map['concepts'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'translation': translation,
      'audio_url': audioUrl,
      'difficulty': difficulty,
      'concepts': concepts,
    };
  }
}
