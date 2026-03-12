import 'package:logger/logger.dart';
import '../models/pronunciation_result.dart';
import 'supabase_service.dart';

/// Stub Pronunciation Service
/// This is a placeholder implementation without audio dependencies
/// To enable full pronunciation features, uncomment the dependencies in pubspec.yaml:
/// - speech_to_text
/// - flutter_tts
/// - record
/// - just_audio
/// - audio_session
/// - permission_handler
class PronunciationService {
  static final PronunciationService _instance = PronunciationService._internal();
  factory PronunciationService() => _instance;
  PronunciationService._internal();

  final Logger _logger = Logger();
  final SupabaseService _supabase = SupabaseService();
  
  bool _isListening = false;
  
  // Callbacks
  Function(String)? onSpeechResult;
  Function(double)? onSoundLevel;
  Function()? onListeningStarted;
  Function()? onListeningStopped;

  Future<void> initialize() async {
    _logger.i('Pronunciation service initialized (stub mode)');
    _logger.i('To enable speech recognition and TTS, uncomment audio dependencies in pubspec.yaml');
  }

  /// Check and request microphone permission - stub implementation
  Future<bool> checkPermissions() async {
    _logger.w('Permission checking not available in stub mode');
    return false;
  }

  /// Start listening for speech - stub implementation
  Future<bool> startListening({String localeId = 'en_US'}) async {
    _logger.w('Speech recognition not available in stub mode');
    _logger.w('Please uncomment speech_to_text dependency in pubspec.yaml to enable this feature');
    return false;
  }

  /// Stop listening - stub implementation
  Future<void> stopListening() async {
    _isListening = false;
    _logger.w('Speech recognition not available in stub mode');
  }

  bool get isListening => _isListening;

  /// Speak text - stub implementation
  Future<void> speak(String text, {String languageCode = 'en-US', double rate = 0.5}) async {
    _logger.w('Text-to-speech not available in stub mode');
    _logger.w('Please uncomment flutter_tts dependency in pubspec.yaml to enable this feature');
  }

  /// Stop speaking - stub implementation
  Future<void> stopSpeaking() async {
    _logger.w('Text-to-speech not available in stub mode');
  }

  /// Start recording audio - stub implementation
  Future<bool> startRecording() async {
    _logger.w('Audio recording not available in stub mode');
    _logger.w('Please uncomment record and permission_handler dependencies in pubspec.yaml to enable this feature');
    return false;
  }

  /// Stop recording and return path - stub implementation
  Future<String?> stopRecording() async {
    _logger.w('Audio recording not available in stub mode');
    return null;
  }

  /// Score pronunciation - stub implementation
  Future<PronunciationResult> scorePronunciation(
    String targetWord,
    String spokenText,
    String languageCode, {
    String? audioPath,
  }) async {
    final result = PronunciationResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _supabase.currentUserId ?? '',
      wordOrPhrase: targetWord,
      score: 85, // Stub score for now
      accuracyScore: 90,
      fluencyScore: 80,
      completenessScore: 85,
      targetLanguage: languageCode,
      attemptedAt: DateTime.now(),
    );

    try {
      await _supabase.client
          .from('pronunciation_results')
          .insert(result.toJson());
    } catch (e) {
      _logger.e('Failed to save pronunciation result', error: e);
    }

    return result;
  }

  Future<List<PronunciationResult>> getPronunciationHistory({int limit = 50}) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return [];

      final response = await _supabase.client
          .from('pronunciation_results')
          .select()
          .eq('user_id', userId)
          .order('attempted_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => PronunciationResult.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Failed to fetch pronunciation history', error: e);
      return [];
    }
  }

  Future<void> dispose() async {
    _logger.i('Pronunciation service disposed');
  }
}
