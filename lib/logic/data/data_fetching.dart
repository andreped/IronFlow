import '../../core/database.dart';

Future<List<Map<String, dynamic>>> loadNextChunk(
  String selectedTable,
  int offset,
  int limit,
  String sortColumn,
  bool sortAscending,
  DatabaseHelper dbHelper,
  String searchQuery,
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
      searchQuery: searchQuery,
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
