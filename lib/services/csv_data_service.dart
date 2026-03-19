import 'package:flutter/services.dart' show rootBundle;
import 'package:logger/logger.dart';
import 'package:csv/csv.dart';
import '../models/vocabulary_item.dart';

class CsvDataService {
  static final CsvDataService _instance = CsvDataService._internal();
  factory CsvDataService() => _instance;
  CsvDataService._internal();

  final Logger _logger = Logger();
  
  List<List<dynamic>>? _vocabCache;
  List<List<dynamic>>? _sentencesCache;

  String _normalizeLangCode(String code) {
    if (code.contains('-')) {
      return code.split('-')[0].toLowerCase();
    }
    if (code.contains('_')) {
      return code.split('_')[0].toLowerCase();
    }
    return code.toLowerCase();
  }

  Future<void> _loadCsvsIfNeeded() async {
    if (_vocabCache != null && _sentencesCache != null) return;

    try {
      final vocabString = await rootBundle.loadString('assets/database/vocabulary.csv');
      _vocabCache = const CsvDecoder().convert(vocabString);
      if (_vocabCache!.isNotEmpty && _vocabCache![0][0].toString().toLowerCase().contains('id')) {
        _vocabCache!.removeAt(0);
      }

      final sentencesString = await rootBundle.loadString('assets/database/sentences.csv');
      _sentencesCache = const CsvDecoder().convert(sentencesString);
      if (_sentencesCache!.isNotEmpty && _sentencesCache![0][0].toString().toLowerCase().contains('concept_id')) {
        _sentencesCache!.removeAt(0);
      }
    } catch (e) {
      _logger.e('Failed to load CSV files: $e');
      _vocabCache = [];
      _sentencesCache = [];
    }
  }

  // Removed _parsePlainCsv as we now use CsvToListConverter directly in _loadCsvsIfNeeded

  Future<List<String>> getConcepts(String targetLang, String nativeLang) async {
    await _loadCsvsIfNeeded();
    if (_vocabCache == null || _vocabCache!.isEmpty) return [];

    final normalizedTarget = _normalizeLangCode(targetLang);
    final targetRows = _vocabCache!.where((row) => row.length > 2 && _normalizeLangCode(row[2].toString()) == normalizedTarget).toList();
    
    final concepts = <String>{};
    for (var row in targetRows) {
      if (row.length > 10) {
        final category = row[10].toString().trim();
        if (category.isNotEmpty) {
           concepts.add(category);
        }
      }
    }
    
    final sortedConcepts = concepts.toList()..sort();
    return sortedConcepts;
  }

  Future<List<VocabularyItem>> getVocabulary(String targetLang, String nativeLang, {String? category, int limit = 50}) async {
    await _loadCsvsIfNeeded();

    if (_vocabCache == null || _vocabCache!.isEmpty) return [];

    // vocabulary.csv columns:
    // 0: vocabulary_id, 1: concept_id, 2: lang, 3: word, 4: article, 5: gender, 
    // 6: plural, 7: word_pronunciation, 8: plural_pronunciation, 9: part_of_speech, 
    // 10: category, 11: level, 12: image_id

    final normalizedTarget = _normalizeLangCode(targetLang);
    final targetRows = _vocabCache!.where((row) {
      if (row.length <= 3) return false;
      if (_normalizeLangCode(row[2].toString()) != normalizedTarget) return false;
      
      if (category != null && category.isNotEmpty) {
        if (row.length <= 10 || row[10].toString() != category) {
          return false;
        }
      }
      return true;
    }).toList();
    
    final normalizedNative = _normalizeLangCode(nativeLang);
    final nativeRows = _vocabCache!.where((row) => row.length > 3 && _normalizeLangCode(row[2].toString()) == normalizedNative).toList();

    final nativeTranslations = <String, String>{};
    for (var row in nativeRows) {
      nativeTranslations[row[1].toString()] = row[3].toString();
    }

    final results = <VocabularyItem>[];
    for (var row in targetRows) {
      final conceptId = row[1].toString();
      final translation = nativeTranslations[conceptId];
      
      if (translation != null && translation.isNotEmpty) {
        final levelStr = row.length > 11 ? row[11].toString() : 'A';
        int difficultyLevel = 1;
        if (levelStr == 'B') difficultyLevel = 2;
        if (levelStr == 'C') difficultyLevel = 3;

        results.add(VocabularyItem(
          id: row[0].toString(),
          courseId: 'local_$targetLang',
          word: row[3].toString(),
          translation: translation,
          difficultyLevel: difficultyLevel,
          createdAt: DateTime.now(),
          category: row.length > 10 ? row[10].toString() : null,
          pronunciationIpa: row.length > 7 ? row[7].toString() : null,
          partOfSpeech: row.length > 9 ? row[9].toString() : null,
        ));

        if (results.length >= limit) break;
      }
    }

    results.shuffle();
    return results.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> getSentences(String targetLang, String nativeLang, {String? categoryConceptIds, int limit = 10}) async {
    await _loadCsvsIfNeeded();

    if (_sentencesCache == null || _sentencesCache!.isEmpty) return [];

    // sentences.csv columns:
    // 0: concept_id, 1: lang_code, 2: sentence, 3: literal_translation, 4: pronunciation, 5: level

    Set<String>? allowedConceptIds;
    
    if (categoryConceptIds != null && categoryConceptIds.isNotEmpty) {
       if (_vocabCache != null) {
          final matchingVocab = _vocabCache!.where((row) => 
            row.length > 10 && row[10].toString() == categoryConceptIds
          ).toList();
          allowedConceptIds = matchingVocab.map((r) => r[1].toString()).toSet();
       }
    }

    final normalizedTarget = _normalizeLangCode(targetLang);
    final targetRows = _sentencesCache!.where((row) {
      if (row.length <= 2) return false;
      if (_normalizeLangCode(row[1].toString()) != normalizedTarget) return false;
      
      if (allowedConceptIds != null) {
        if (!allowedConceptIds.contains(row[0].toString())) return false;
      }
      return true;
    }).toList();
    
    final normalizedNative = _normalizeLangCode(nativeLang);
    final nativeRows = _sentencesCache!.where((row) => row.length > 2 && _normalizeLangCode(row[1].toString()) == normalizedNative).toList();

    final nativeTranslations = <String, String>{};
    for (var row in nativeRows) {
      nativeTranslations[row[0].toString()] = row[2].toString();
    }

    final results = <Map<String, dynamic>>[];
    for (var row in targetRows) {
      final conceptId = row[0].toString();
      final translation = nativeTranslations[conceptId];
      
      if (translation != null && translation.isNotEmpty) {
        final sentence = row[2].toString();
        final words = sentence.split(' ');
        if (words.length > 1) {
          final candidates = words.where((w) => w.length > 3).toList();
          final blankWord = candidates.isNotEmpty ? candidates.first : words[0];
          final cleanBlank = blankWord.replaceAll(RegExp(r'[.,!?]'), '');
          
          final sentenceWithBlank = sentence.replaceFirst(cleanBlank, '___');

          final options = [cleanBlank];
          for (int i=0; i<3; i++) {
             int randomIdx = (conceptId.hashCode + i) % targetRows.length;
             final randomSentence = targetRows[randomIdx][2].toString();
             final randomWords = randomSentence.split(' ');
             options.add(randomWords.firstWhere((w) => w.length > 2, orElse: () => randomWords.first).replaceAll(RegExp(r'[.,!?]'), ''));
          }
          options.shuffle();

          results.add({
            'sentence': sentenceWithBlank,
            'blank': cleanBlank,
            'translation': translation,
            'options': options.toSet().toList(),
            'hint': 'Complete the sentence',
            'full_sentence': sentence,
          });

          if (results.length >= limit) break;
        }
      }
    }

    results.shuffle();
    return results.take(limit).toList();
  }
}
