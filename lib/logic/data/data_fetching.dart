import '../../../core/database.dart';

Future<void> loadNextChunk(
  String selectedTable,
  bool isLoading,
  bool hasMoreData,
  List<Map<String, dynamic>> data,
  int offset,
  int limit,
  String sortColumn,
  bool sortAscending,
  DatabaseHelper dbHelper,
  Function setState,
) async {
  if (isLoading || !hasMoreData) return;

  setState(() {
    isLoading = true;
  });

  List<Map<String, dynamic>> newData;
  try {
    if (selectedTable == 'exercises') {
      newData = await dbHelper.getExercisesChunk(
        sortColumn: sortColumn,
        ascending: sortAscending,
        offset: offset,
        limit: limit,
        isNumeric: sortColumn == 'Weight',
        isDateTime: sortColumn == 'Timestamp',
      );
    } else if (selectedTable == 'fitness') {
      newData = await dbHelper.getFitnessDataChunk(
        sortColumn: sortColumn,
        ascending: sortAscending,
        offset: offset,
        limit: limit,
        isNumeric: sortColumn == 'Weight',
        isDateTime: sortColumn == 'Timestamp',
      );
    } else {
      newData = [];
    }

    setState(() {
      data.addAll(newData);
      offset += limit;
      isLoading = false;
      if (newData.length < limit) {
        hasMoreData = false;
      }
    });
  } catch (e) {
    setState(() {
      isLoading = false;
      hasMoreData = false;
    });
    // Handle error appropriately
    print('Error loading data: $e');
  }
}
