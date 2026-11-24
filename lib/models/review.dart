class Review {
  const Review({
    this.id,
    required this.kind,
    required this.ref,
    required this.correct,
    required this.date,
  });

  final int? id;
  final String kind;
  final String ref;
  final bool correct;
  final DateTime date;

  factory Review.fromMap(Map<String, Object?> map) => Review(
        id: map['id'] as int?,
        kind: map['kind'] as String,
        ref: map['ref'] as String,
        correct: map['correct'] == 1,
        date: DateTime.parse(map['date'] as String),
      );

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'kind': kind,
      'ref': ref,
      'correct': correct ? 1 : 0,
      'date': date.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }
}