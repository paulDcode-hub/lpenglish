import 'dart:convert';

class Word {
  const Word({
    this.id,
    required this.en,
    required this.fr,
    required this.theme,
    this.ease = 2.5,
    this.interval = 0,
    this.reps = 0,
    this.lapses = 0,
    required this.due,
    required this.created,
    this.termKey,
    this.sense,
    this.stress,
    this.pos,
    this.context,
    this.highlight,
    this.note,
    this.tags = const [],
    this.marked = false,
  });

  final int? id;
  final String en;
  final String fr;
  final String theme;
  final double ease;
  final int interval;
  final int reps;
  final int lapses;
  final DateTime due;
  final DateTime created;
  final String? termKey;
  final String? sense;
  final String? stress;
  final String? pos;
  final String? context;
  final String? highlight;
  final String? note;
  final List<String> tags;
  final bool marked;

  bool get isDue => !due.isAfter(DateTime.now());

  bool get isMastered => interval >= 21;

  factory Word.fromMap(Map<String, Object?> map) => Word(
        id: map['id'] as int?,
        en: map['en'] as String,
        fr: map['fr'] as String,
        theme: map['theme'] as String,
        ease: (map['ease'] as num).toDouble(),
        interval: map['interval'] as int,
        reps: map['reps'] as int,
        lapses: map['lapses'] as int,
        due: DateTime.parse(map['due'] as String),
        created: DateTime.parse(map['created'] as String),
        termKey: map['term_key'] as String?,
        sense: map['sense'] as String?,
        stress: map['stress'] as String?,
        pos: map['pos'] as String?,
        context: map['context'] as String?,
        highlight: map['highlight'] as String?,
        note: map['note'] as String?,
        tags: map['tags'] == null
            ? const []
            : (jsonDecode(map['tags'] as String) as List<dynamic>)
                  .cast<String>(),
        marked: (map['marked'] as int? ?? 0) == 1,
      );

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'en': en,
      'fr': fr,
      'theme': theme,
      'ease': ease,
      'interval': interval,
      'reps': reps,
      'lapses': lapses,
      'due': due.toIso8601String(),
      'created': created.toIso8601String(),
      'term_key': termKey,
      'sense': sense,
      'stress': stress,
      'pos': pos,
      'context': context,
      'highlight': highlight,
      'note': note,
      'tags': jsonEncode(tags),
      'marked': marked ? 1 : 0,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  Word copyWith({
    int? id,
    String? en,
    String? fr,
    String? theme,
    double? ease,
    int? interval,
    int? reps,
    int? lapses,
    DateTime? due,
    DateTime? created,
    String? termKey,
    String? sense,
    String? stress,
    String? pos,
    String? context,
    String? highlight,
    String? note,
    List<String>? tags,
    bool? marked,
  }) =>
      Word(
        id: id ?? this.id,
        en: en ?? this.en,
        fr: fr ?? this.fr,
        theme: theme ?? this.theme,
        ease: ease ?? this.ease,
        interval: interval ?? this.interval,
        reps: reps ?? this.reps,
        lapses: lapses ?? this.lapses,
        due: due ?? this.due,
        created: created ?? this.created,
        termKey: termKey ?? this.termKey,
        sense: sense ?? this.sense,
        stress: stress ?? this.stress,
        pos: pos ?? this.pos,
        context: context ?? this.context,
        highlight: highlight ?? this.highlight,
        note: note ?? this.note,
        tags: tags ?? this.tags,
        marked: marked ?? this.marked,
      );
}