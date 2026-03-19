import 'dart:io';
import 'package:csv/csv.dart';
import 'package:supabase/supabase.dart';

// CONFIGURATION
const String supabaseUrl = 'https://imyjjyhrqhgyvgpiccbv.supabase.co';
const String supabaseAnonKey = '';

const String vocabularyPath = 'assets/database/vocabulary_no_id.csv';
const String sentencesPath = 'assets/database/sentences_no_id.csv';

void main() async {
  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);
  print('🚀 Starting Migration...');

  try {
    await runMigration(client, 'vocabulary', vocabularyPath, [
      'concept_id',
      'lang_code',
      'word',
      'article',
      'gender',
      'plural',
      'word_pronunciation',
      'plural_pronunciation',
      'part_of_speech',
      'category',
      'level',
      'image_id'
    ]);

    await runMigration(client, 'sentences', sentencesPath,
        ['concept_id', 'lang_code', 'sentence', 'pronunciation', 'level']);

    print('🎉 Done!');
  } catch (e) {
    print('❌ Error: $e');
  }
  exit(0);
}

Future<void> runMigration(
    SupabaseClient client, String table, String path, List<String> cols) async {
  final file = File(path);
  if (!file.existsSync()) {
    print('Missing: $path');
    return;
  }

  print('Processing $path...');
  final csvData = await file.readAsString();
  final List<List<dynamic>> rows = CsvToListConverter().convert(csvData);

  print('Inserting ${rows.length} rows into $table...');
  const int batchSize = 1000;

  for (var i = 0; i < rows.length; i += batchSize) {
    final end = (i + batchSize < rows.length) ? i + batchSize : rows.length;
    final chunk = rows.sublist(i, end);

    final data = chunk.map((row) {
      final map = <String, dynamic>{};
      for (var j = 0; j < cols.length; j++) {
        if (j < row.length) {
          final val = row[j];
          map[cols[j]] = (val is String && val.trim().isEmpty) ? null : val;
        } else {
          map[cols[j]] = null;
        }
      }
      return map;
    }).toList();

    try {
      await client.from(table).insert(data);
      print('Batch ${i ~/ batchSize + 1} for $table OK');
    } catch (e) {
      print('Batch $i error: $e');
    }
  }
}
