class Exercise {
  final String name;
  final double weight;
  final int reps;
  final int sets;
  final DateTime timestamp;

  Exercise({
    required this.name,
    required this.weight,
    required this.reps,
    required this.sets,
    required this.timestamp,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['exercise'] ?? '',
      weight: double.tryParse(map['weight']?.toString() ?? '0.0') ?? 0.0,
      reps: int.tryParse(map['reps']?.toString() ?? '1') ?? 1,
      sets: int.tryParse(map['sets']?.toString() ?? '1') ?? 1,
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'name':
        return name;
      case 'Weight':
        return weight;
      case 'Reps':
        return reps;
      case 'Sets':
        return sets;
      case 'Timestamp':
        return timestamp;
      default:
        throw ArgumentError('Invalid property name: $key');
    }
  }
}
