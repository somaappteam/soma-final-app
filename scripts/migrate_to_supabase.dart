import 'dart:io';
import 'package:csv/csv.dart';
import 'package:supabase/supabase.dart';

// CONFIGURATION - Update these if needed
const String supabaseUrl = 'https://imyjjyhrqhgyvgpiccbv.supabase.co';
const String supabaseAnonKey = '';

// File Paths
const String vocabularyPath = 'assets/database/vocabulary_no_id.csv';
const String sentencesPath = 'assets/database/sentences_no_id.csv';

void main() async {
  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  print('🚀 Starting Migration to Supabase...');

  try {
    // 1. Migrate Vocabulary
    await migrateTable(client, 'vocabulary', vocabularyPath, [
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

    // 2. Migrate Sentences
    await migrateTable(client, 'sentences', sentencesPath,
        ['concept_id', 'lang_code', 'sentence', 'pronunciation', 'level']);

    print('🎉 Migration Complete!');
  } catch (e) {
    print('❌ Global Error: $e');
  }
  exit(0);
}

Future<void> migrateTable(SupabaseClient client, String tableName,
    String filePath, List<String> columns) async {
  final file = File(filePath);
  if (!file.existsSync()) {
    print('❌ File not found: $filePath');
    return;
  }

  print('Reading $filePath...');
  final contents = await file.readAsString();
  final fields = const CsvToListConverter().convert(contents);

  print('Preparing to insert ${fields.length} rows into $tableName...');

  const int batchSize = 1000;
  for (var i = 0; i < fields.length; i += batchSize) {
    var end = (i + batchSize < fields.length) ? i + batchSize : fields.length;
    var batch = fields.sublist(i, end);

    var data = batch.map((row) {
      var map = <String, dynamic>{};
      for (var colIdx = 0; colIdx < columns.length; colIdx++) {
        if (colIdx < row.length) {
          var value = row[colIdx];
          // Convert empty strings to null for database
          map[columns[colIdx]] =
              (value is String && value.toString().trim() == '') ? null : value;
        } else {
          map[columns[colIdx]] = null;
        }
      }
      return map;
    }).toList();

    try {
      await client.from(tableName).insert(data);
      print(
          '✅ Inserted batch ${i ~/ batchSize + 1} ($end/${fields.length}) into $tableName');
    } catch (e) {
      print('❌ Error inserting batch starting at index $i: $e');
    }
  }
}
