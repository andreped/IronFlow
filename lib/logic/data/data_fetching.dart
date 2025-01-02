import '../../core/database.dart';

Future<List<Map<String, dynamic>>> loadNextChunk(
  String selectedTable,
  int offset,
  int limit,
  String sortColumn,
  bool sortAscending,
  DatabaseHelper dbHelper,
) async {
  List<Map<String, dynamic>> newData;
  bool isNumeric = sortColumn == 'weight';

  if (selectedTable == 'exercises') {
    newData = await dbHelper.getExercisesChunk(
      sortColumn: sortColumn,
      ascending: sortAscending,
      offset: offset,
      limit: limit,
      isNumeric: isNumeric,
      isDateTime: sortColumn == 'timestamp',
    );
  } else if (selectedTable == 'fitness') {
    newData = await dbHelper.getFitnessDataChunk(
      sortColumn: sortColumn,
      ascending: sortAscending,
      offset: offset,
      limit: limit,
      isNumeric: isNumeric,
      isDateTime: sortColumn == 'timestamp',
    );
  } else {
    newData = [];
  }

  return newData;
}