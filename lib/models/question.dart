class Question {
  final String id;
  final String type; // 'vocabulary', 'sentence', 'listening'
  final String question;
  final String correctAnswer;
  final List<String> options;
  final String? imageAsset;
  final String? audioUrl;
  final String hint;
  
  Question({
    required this.id,
    required this.type,
    required this.question,
    required this.correctAnswer,
    required this.options,
    this.imageAsset,
    this.audioUrl,
    this.hint = '',
  });
}
