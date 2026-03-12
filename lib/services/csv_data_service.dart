import 'package:flutter/services.dart' show rootBundle;
import 'package:logger/logger.dart';
import '../models/vocabulary_item.dart';

class CsvDataService {
  static final CsvDataService _instance = CsvDataService._internal();
  factory CsvDataService() => _instance;
  CsvDataService._internal();

  final Logger _logger = Logger();
  
  List<List<dynamic>>? _vocabCache;
  List<List<dynamic>>? _sentencesCache;

  Future<void> _loadCsvsIfNeeded() async {
    if (_vocabCache != null && _sentencesCache != null) return;

    try {
      final vocabString = await rootBundle.loadString('assets/database/vocabulary .csv');
      _vocabCache = _parsePlainCsv(vocabString);
      // Remove header if it looks like one
      if (_vocabCache!.isNotEmpty && _vocabCache![0][0].toString().toLowerCase() == 'id') {
        _vocabCache!.removeAt(0);
      }

      final sentencesString = await rootBundle.loadString('assets/database/sentences .csv');
      _sentencesCache = _parsePlainCsv(sentencesString);
    } catch (e) {
      _logger.e('Failed to load CSV files: $e');
      _vocabCache = [];
      _sentencesCache = [];
    }
  }

  List<List<dynamic>> _parsePlainCsv(String input) {
    if (input.isEmpty) return [];
    return input.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          // Robust CSV line parsing (handles quotes and commas)
          final result = <dynamic>[];
          final regex = RegExp(r'"([^"]*)"|([^,]+)');
          final matches = regex.allMatches(line);
          for (final match in matches) {
            final val = match.group(1) ?? match.group(2) ?? '';
            result.add(val.trim());
          }
          return result;
        }).toList();
  }

  Future<List<String>> getConcepts(String targetLang, String nativeLang) async {
    await _loadCsvsIfNeeded();
    if (_vocabCache == null || _vocabCache!.isEmpty) return [];

    final targetRows = _vocabCache!.where((row) => row.length > 3 && row[2].toString().toLowerCase() == targetLang.toLowerCase()).toList();
    
    final concepts = <String>{};
    for (var row in targetRows) {
      if (row.length > 10) {
        final category = row[10].toString().trim();
        if (category.isNotEmpty) {
           concepts.add(category);
        }
      }
    }
    
    // Sort concepts alphabetically, or return in original order
    final sortedConcepts = concepts.toList()..sort();
    return sortedConcepts;
  }

  Future<List<VocabularyItem>> getVocabulary(String targetLang, String nativeLang, {String? category, int limit = 50}) async {
    await _loadCsvsIfNeeded();

    if (_vocabCache == null || _vocabCache!.isEmpty) return [];

    // The CSV columns are: 
    // 0: vocabulary_id, 1: concept_id, 2: lang_code, 3: word, 4: article, 5: gender, 
    // 6: plural, 7: word_pronunciation, 8: plural_pronunciation, 9: part_of_speech, 
    // 10: category, 11: level, 12: image_id

    // Get all rows for target language, optionally filtering by category
    final targetRows = _vocabCache!.where((row) {
      if (row.length <= 3) return false;
      if (row[2].toString().toLowerCase() != targetLang.toLowerCase()) return false;
      
      if (category != null && category.isNotEmpty) {
        if (row.length <= 10 || row[10].toString() != category) {
          return false;
        }
      }
      return true;
    }).toList();
    
    // Get all rows for native language to use as translations
    final nativeRows = _vocabCache!.where((row) => row.length > 3 && row[2].toString().toLowerCase() == nativeLang.toLowerCase()).toList();

    // Map concept_id to native word
    final nativeTranslations = <String, String>{};
    for (var row in nativeRows) {
      nativeTranslations[row[1].toString()] = row[3].toString();
    }

    final results = <VocabularyItem>[];
    for (var row in targetRows) {
      final conceptId = row[1].toString();
      final translation = nativeTranslations[conceptId];
      
      if (translation != null && translation.isNotEmpty) {
        // level can be A, B, C etc, convert to int for difficulty level
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

    // The CSV columns are:
    // 0: sentence_id, 1: concept_id, 2: lang_code, 3: sentence, 4: literal_translation, 5: level

    Set<String>? allowedConceptIds;
    
    if (categoryConceptIds != null && categoryConceptIds.isNotEmpty) {
      // If we provided a category, we first need to find which concept_ids belong to this category
       if (_vocabCache != null) {
          final matchingVocab = _vocabCache!.where((row) => 
            row.length > 10 && row[10].toString() == categoryConceptIds
          ).toList();
          allowedConceptIds = matchingVocab.map((r) => r[1].toString()).toSet();
       }
    }

    // Get all rows for target language
    final targetRows = _sentencesCache!.where((row) {
      if (row.length <= 3) return false;
      if (row[2].toString().toLowerCase() != targetLang.toLowerCase()) return false;
      
      if (allowedConceptIds != null) {
        if (!allowedConceptIds.contains(row[1].toString())) return false;
      }
      return true;
    }).toList();
    
    // Get all rows for native language to use as translations
    final nativeRows = _sentencesCache!.where((row) => row.length > 3 && row[2].toString().toLowerCase() == nativeLang.toLowerCase()).toList();

    // Map concept_id to native sentence
    final nativeTranslations = <String, String>{};
    for (var row in nativeRows) {
      nativeTranslations[row[1].toString()] = row[3].toString();
    }

    final results = <Map<String, dynamic>>[];
    for (var row in targetRows) {
      final conceptId = row[1].toString();
      final translation = nativeTranslations[conceptId];
      
      if (translation != null && translation.isNotEmpty) {
        final sentence = row[3].toString();
        // Extract a random word to blank out for the FillInBlank/SentenceCompletion games
        final words = sentence.split(' ');
        if (words.length > 2) {
          // Just pick a non-trivial random word (longer than 3 chars if possible) to blank out
          final candidates = words.where((w) => w.length > 3).toList();
          final blankWord = candidates.isNotEmpty ? candidates.first : words[1];
          final cleanBlank = blankWord.replaceAll(RegExp(r'[.,!?]'), '');
          
          final sentenceWithBlank = sentence.replaceFirst(cleanBlank, '___');

          // Generate some basic options
          final options = [cleanBlank];
          // we'd realistically need to pick other similar words, but for now just shuffle some other random target words
          for (int i=0; i<3; i++) {
             int randomIdx = (row[0].hashCode + i) % targetRows.length;
             final randomSentence = targetRows[randomIdx][3].toString();
             final randomWords = randomSentence.split(' ');
             options.add(randomWords.firstWhere((w) => w.length > 3, orElse: () => randomWords.first).replaceAll(RegExp(r'[.,!?]'), ''));
          }
          options.shuffle();

          results.add({
            'sentence': sentenceWithBlank,
            'blank': cleanBlank,
            'translation': translation,
            'options': options.toSet().toList(), // Remove duplicates
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
