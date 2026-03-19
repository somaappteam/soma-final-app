import 'package:csv/csv.dart';

void main() {
  const csv = 'a,b,c\n1,2,3';
  final rows = CsvToListConverter().convert(csv);
  print('Parsed ${rows.length} rows');
}
