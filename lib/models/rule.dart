import 'dart:convert';

class Rule {
  const Rule({
    this.id,
    required this.title,
    required this.theme,
    required this.explanation,
    required this.examples,
    this.structure,
    this.mistakes = const [],
    this.tags = const [],
  });

  final int? id;
  final String title;
  final String theme;
  final String explanation;
  final String examples;
  final String? structure;
  final List<Map<String, String>> mistakes;
  final List<String> tags;

  List<String> get exampleList => examples
      .split('\n')
      .where((example) => example.trim().isNotEmpty)
      .toList();

  factory Rule.fromMap(Map<String, Object?> map) => Rule(
        id: map['id'] as int?,
        title: map['title'] as String,
        theme: map['theme'] as String,
        explanation: map['explanation'] as String,
        examples: map['examples'] as String,
        structure: map['structure'] as String?,
        mistakes: map['mistakes'] == null
            ? const []
            : (jsonDecode(map['mistakes'] as String) as List<dynamic>)
                  .map((item) => Map<String, String>.from(item as Map))
                  .toList(),
        tags: map['tags'] == null
            ? const []
            : (jsonDecode(map['tags'] as String) as List<dynamic>)
                  .cast<String>(),
      );

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'title': title,
      'theme': theme,
      'explanation': explanation,
      'examples': examples,
      'structure': structure,
      'mistakes': jsonEncode(mistakes),
      'tags': jsonEncode(tags),
    };
    if (id != null) map['id'] = id;
    return map;
  }
}