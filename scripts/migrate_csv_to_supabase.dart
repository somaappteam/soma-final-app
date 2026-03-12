import 'dart:io';
import 'package:supabase/supabase.dart';

List<List<String>> manualParseCsv(String content) {
  final List<List<String>> rows = [];
  final List<String> lines = content.replaceFirst('\r\n', '\n').split('\n');

  for (var line in lines) {
    if (line.trim().isEmpty) continue;

    final List<String> fields = [];
    StringBuffer currentField = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(currentField.toString().trim());
        currentField.clear();
      } else {
        currentField.write(char);
      }
    }
    fields.add(currentField.toString().trim());
    rows.add(fields);
  }
  return rows;
}

void main() async {
  const url = 'https://imyjjyhrqhgyvgpiccbv.supabase.co';
  const key = '';

  final supabase = SupabaseClient(url, key);
  print('--- Manual CSV Migration Started (Fixed) ---');

  int safeParseLevel(String? l) {
    if (l == null) return 1;
    String s = l.toUpperCase();
    if (s.startsWith('A')) return 1;
    if (s.startsWith('B')) return 2;
    if (s.startsWith('C')) return 3;
    return 1;
  }

  // 1. Sentences
  final File sentencesFile = File('assets/database/sentences.csv');
  if (sentencesFile.existsSync()) {
    print('Processing sentences.csv...');
    final List<List<String>> rows =
        manualParseCsv(sentencesFile.readAsStringSync());
    print('Found ${rows.length - 1} sentence rows.');

    Map<String, String> enTrans = {};
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length >= 4 && row[2].startsWith('en')) {
        enTrans[row[1]] = row[3];
      }
    }

    final List<Map<String, dynamic>> records = [];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 6) continue;
      if (row[0].toLowerCase() == 'id' || row[0].toLowerCase() == 'sentence_id') {
        continue;
      }

      records.add({
        'language_code': row[2],
        'sentence': row[3],
        'translation': enTrans[row[1]] ?? 'Translation not found',
        'difficulty_level': row[5],
      });

      if (records.length >= 200) {
        try {
          await supabase.from('sentences').insert(records);
          print('Uploaded batch of ${records.length} sentences...');
        } catch (e) {
          print('Batch Sentence Insert Error: $e');
        }
        records.clear();
      }
    }
    if (records.isNotEmpty) await supabase.from('sentences').insert(records);
  }

  // 2. Vocabulary
  final File vocabFile = File('assets/database/vocabulary.csv');
  if (vocabFile.existsSync()) {
    print('Processing vocabulary.csv...');
    final List<List<String>> rows =
        manualParseCsv(vocabFile.readAsStringSync());
    print('Found ${rows.length - 1} vocabulary rows.');

    Map<String, String> enTrans = {};
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length >= 4 && row[2].startsWith('en')) {
        enTrans[row[1]] = row[3];
      }
    }

    final List<Map<String, dynamic>> records = [];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 12) continue;
      if (row[0].toLowerCase() == 'id' ||
          row[0].toLowerCase() == 'vocabulary_id') {
        continue;
      }

      records.add({
        'language_code': row[2],
        'word': row[3],
        'translation': enTrans[row[1]] ?? 'Translation not found',
        'part_of_speech': row[9],
        'category': row[10],
        'difficulty_level': safeParseLevel(row[11]),
        'example_sentences': [],
      });

      if (records.length >= 200) {
        try {
          await supabase.from('vocabulary').insert(records);
          print('Uploaded batch of ${records.length} vocabulary words...');
        } catch (e) {
          print('Batch Vocab Insert Error: $e');
        }
        records.clear();
      }
    }
    if (records.isNotEmpty) await supabase.from('vocabulary').insert(records);
  }

  print('--- Migration Complete ---');
  exit(0);
}
