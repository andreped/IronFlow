class FitnessData {
  final String exercise;
  final double weight;
  final int height;
  final int age;
  final DateTime timestamp;

  FitnessData({
    required this.exercise,
    required this.weight,
    required this.height,
    required this.age,
    required this.timestamp,
  });

  factory FitnessData.fromMap(Map<String, dynamic> map) {
    return FitnessData(
      exercise: map['exercise'] ?? '',
      weight: double.tryParse(map['weight']?.toString() ?? '0.0') ?? 0.0,
      height: int.tryParse(map['height']?.toString() ?? '0') ?? 0,
      age: int.tryParse(map['age']?.toString() ?? '0') ?? 0,
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'exercise':
        return exercise;
      case 'Weight':
        return weight;
      case 'Height':
        return height;
      case 'Age':
        return age;
      case 'Timestamp':
        return timestamp;
      default:
        throw ArgumentError('Invalid property name: $key');
    }
  }
}
