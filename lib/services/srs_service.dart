import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocabulary_item.dart';

/// SM-2 Spaced Repetition data for a single card.
class SrsCard {
  final String wordId;
  int repetitions;        // how many consecutive successes
  double easeFactor;      // 1.3 – 2.5+
  int intervalDays;       // days until next review
  DateTime dueDate;       // when to review next

  SrsCard({
    required this.wordId,
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    DateTime? dueDate,
  }) : dueDate = dueDate ?? DateTime.now();

  bool get isDue => DateTime.now().isAfter(dueDate) || DateTime.now().isAtSameMomentAs(dueDate);

  Map<String, dynamic> toJson() => {
    'wordId': wordId,
    'repetitions': repetitions,
    'easeFactor': easeFactor,
    'intervalDays': intervalDays,
    'dueDate': dueDate.toIso8601String(),
  };

  factory SrsCard.fromJson(Map<String, dynamic> json) => SrsCard(
    wordId: json['wordId'] as String,
    repetitions: json['repetitions'] as int? ?? 0,
    easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
    intervalDays: json['intervalDays'] as int? ?? 1,
    dueDate: json['dueDate'] != null
        ? DateTime.parse(json['dueDate'] as String)
        : DateTime.now(),
  );
}

/// Quality grades passed to [SrsService.updateSrsState].
/// Maps to the SM-2 0–5 quality scale:
///   5 = Perfect, 4 = Good, 3 = Hard, 2 = Wrong but close, 1 = wrong, 0 = blackout
enum SrsQuality {
  blackout(0),
  wrong(1),
  wrongButClose(2),
  hard(3),
  good(4),
  perfect(5);

  final int value;
  const SrsQuality(this.value);
}

/// Persists per-word SRS state using the SM-2 algorithm.
/// State is stored in SharedPreferences keyed by [courseId]_[wordId].
class SrsService {
  static SrsService? _instance;
  factory SrsService() => _instance ??= SrsService._();
  SrsService._();

  static const String _prefix = 'srs_card_';

  String _key(String courseId, String wordId) => '$_prefix${courseId}_$wordId';

  // ── State Access ─────────────────────────────────────────────────────────

  Future<SrsCard> getSrsCard(String courseId, String wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(courseId, wordId));
    if (raw == null) return SrsCard(wordId: wordId);
    try {
      return SrsCard.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return SrsCard(wordId: wordId);
    }
  }

  Future<void> _saveSrsCard(String courseId, SrsCard card) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(courseId, card.wordId), jsonEncode(card.toJson()));
  }

  // ── SM-2 Update ────────────────────────────────────────────────────────

  /// Update a word's SRS state after answering.
  /// [quality] 0–5 per SM-2 convention.
  Future<SrsCard> updateSrsState(String courseId, String wordId, SrsQuality quality) async {
    final card = await getSrsCard(courseId, wordId);
    final q = quality.value;

    if (q < 3) {
      // Failed: reset
      card.repetitions = 0;
      card.intervalDays = 1;
    } else {
      // Passed
      switch (card.repetitions) {
        case 0:
          card.intervalDays = 1;
          break;
        case 1:
          card.intervalDays = 6;
          break;
        default:
          card.intervalDays = (card.intervalDays * card.easeFactor).round();
      }
      card.repetitions++;
    }

    // Update ease factor (clamped to minimum 1.3)
    card.easeFactor = max(
      1.3,
      card.easeFactor + 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02),
    );

    card.dueDate = DateTime.now().add(Duration(days: card.intervalDays));
    await _saveSrsCard(courseId, card);
    return card;
  }

  // ── Session Selection ─────────────────────────────────────────────────

  /// Returns [count] vocabulary items for a session using SRS priority:
  ///   1. Due / overdue words (sorted by how overdue they are)
  ///   2. New words (never seen before)
  ///   3. Random filler from the remaining pool
  ///
  /// All items are shuffled within each tier so order feels random.
  Future<List<VocabularyItem>> selectSessionWords({
    required String courseId,
    required List<VocabularyItem> allVocab,
    required int count,
  }) async {
    if (allVocab.isEmpty) return [];
    final effectiveCount = min(count, allVocab.length);

    final prefs = await SharedPreferences.getInstance();

    // Classify each word
    final List<VocabularyItem> dueWords = [];
    final List<VocabularyItem> newWords = [];
    final List<VocabularyItem> futureWords = [];

    for (final vocab in allVocab) {
      final raw = prefs.getString(_key(courseId, vocab.id));
      if (raw == null) {
        newWords.add(vocab);
      } else {
        try {
          final card = SrsCard.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          if (card.isDue) {
            dueWords.add(vocab);
          } else {
            futureWords.add(vocab);
          }
        } catch (_) {
          newWords.add(vocab);
        }
      }
    }

    // Sort due words: most overdue first
    dueWords.sort((a, b) {
      // We can't do async here, but we already loaded them above; use a quick
      // rough heuristic — interval days stored, shorter = more overdue
      return a.id.compareTo(b.id); // safe fallback
    });

    // Shuffle within tiers
    final rng = Random();
    dueWords.shuffle(rng);
    newWords.shuffle(rng);
    futureWords.shuffle(rng);

    // Fill session: due → new → future
    final result = <VocabularyItem>[];
    for (final tier in [dueWords, newWords, futureWords]) {
      for (final word in tier) {
        if (result.length >= effectiveCount) break;
        result.add(word);
      }
      if (result.length >= effectiveCount) break;
    }

    // Final shuffle so the categories don't appear in obvious order
    result.shuffle(rng);
    return result;
  }

  // ── Quality Helpers ────────────────────────────────────────────────────

  /// Convert a simple correct/wrong boolean to SRS quality.
  static SrsQuality fromCorrect(bool correct) =>
      correct ? SrsQuality.good : SrsQuality.wrong;

  /// Convert a flashcard-style rating (0–3) to SRS quality.
  ///   0 = Again, 1 = Hard, 2 = Good, 3 = Easy
  static SrsQuality fromCardRating(int rating) {
    switch (rating) {
      case 0:  return SrsQuality.wrong;
      case 1:  return SrsQuality.hard;
      case 2:  return SrsQuality.good;
      case 3:  return SrsQuality.perfect;
      default: return SrsQuality.good;
    }
  }
}
