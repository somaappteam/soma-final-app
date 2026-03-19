import 'package:csv/csv.dart';

void main() {
  final data = const CsvDecoder().convert('1,2,3');
  print(data);
}
