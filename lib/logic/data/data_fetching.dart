import '../../core/database.dart';

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
  Function(Map<String, dynamic>) setState,
) async {
  if (isLoading || !hasMoreData) return;

  setState({
    'isLoading': true,
  });

  List<Map<String, dynamic>> newData;
  try {
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

    setState({
      'data': data..addAll(newData),
      'offset': offset + limit,
      'isLoading': false,
      'hasMoreData': newData.length >= limit,
    });
  } catch (e) {
    setState({
      'isLoading': false,
      'hasMoreData': false,
    });
    // Handle error appropriately
    print('Error loading data: $e');
  }
}