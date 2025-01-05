import '../core/database.dart';

class RecordsRepository {
  final DatabaseHelper _dbHelper;

  RecordsRepository(this._dbHelper);

  Future<List<Map<String, dynamic>>> getMaxWeightsForExercises() async {
    return await _dbHelper.getMaxWeightsForExercises();
  }
}
