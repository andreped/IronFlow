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
  bool isNumeric = sortColumn == 'Weight';

  if (selectedTable == 'exercises') {
    newData = await dbHelper.getExercisesChunk(
      sortColumn: sortColumn,
      ascending: sortAscending,
      offset: offset,
      limit: limit,
      isNumeric: isNumeric,
      isDateTime: sortColumn == 'Timestamp',
    );
  } else if (selectedTable == 'fitness') {
    newData = await dbHelper.getFitnessDataChunk(
      sortColumn: sortColumn,
      ascending: sortAscending,
      offset: offset,
      limit: limit,
      isNumeric: isNumeric,
      isDateTime: sortColumn == 'Timestamp',
    );
  } else {
    newData = [];
  }

  return newData;
}
