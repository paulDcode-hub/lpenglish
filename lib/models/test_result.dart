class TestResult {
  const TestResult({
    this.id,
    required this.type,
    required this.score,
    required this.total,
    this.theme,
    required this.date,
  });

  final int? id;
  final String type;
  final int score;
  final int total;
  final String? theme;
  final DateTime date;

  factory TestResult.fromMap(Map<String, Object?> map) => TestResult(
        id: map['id'] as int?,
        type: map['type'] as String,
        score: map['score'] as int,
        total: map['total'] as int,
        theme: map['theme'] as String?,
        date: DateTime.parse(map['date'] as String),
      );

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'type': type,
      'score': score,
      'total': total,
      'theme': theme,
      'date': date.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }
}