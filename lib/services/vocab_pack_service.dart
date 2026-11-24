import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../data/database.dart';

class VocabPackFormatException implements Exception {
  const VocabPackFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VocabPackPreview {
  const VocabPackPreview({
    required this.pack,
    required this.newWords,
    required this.updatedWords,
    required this.identicalWords,
    required this.mergedWords,
    required this.duplicateWords,
  });

  final Map<String, dynamic> pack;
  final int newWords;
  final int updatedWords;
  final int identicalWords;
  final int mergedWords;
  final int duplicateWords;

  String get title => pack['meta']['title'] as String;
  int get themeCount => (pack['themes'] as List<dynamic>).length;
  int get grammarCount => (pack['grammar'] as List<dynamic>).length;
  int get wordCount => newWords + updatedWords + identicalWords + mergedWords;
}

class VocabPackService {
  static VocabPackPreview parseAndPreview(String source) {
    dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw VocabPackFormatException('JSON invalide : ${error.message}');
    }
    _validatePack(decoded);

    final pack = Map<String, dynamic>.from(decoded as Map)
      ..putIfAbsent('grammar', () => <dynamic>[]);
    final entries = _entries(pack);
    final entryIds = <String>{};
    var duplicates = 0;
    final termSenses = <String>{};
    for (final entry in entries) {
      final id = entry['id'] as String;
      if (!entryIds.add(id)) {
        throw VocabPackFormatException('Identifiant d’entrée dupliqué : $id');
      }
      final key = '${entry['term_key']}\u0000${entry['sense'] ?? ''}';
      if (!termSenses.add(key)) duplicates++;
    }
    final allIds = entries.map((entry) => entry['id'] as String).toSet();
    for (var index = 0; index < (pack['themes'] as List).length; index++) {
      final theme = pack['themes'][index] as Map;
      final includes = theme['include'] as List? ?? const [];
      for (
        var includeIndex = 0;
        includeIndex < includes.length;
        includeIndex++
      ) {
        if (!allIds.contains(includes[includeIndex])) {
          throw VocabPackFormatException(
            'themes[$index].include[$includeIndex] référence une entrée inconnue.',
          );
        }
      }
    }

    return _preview(pack, duplicates);
  }

  static Future<VocabPackPreview> readAndPreview(String source) async {
    final parsed = parseAndPreview(source);
    final db = await AppDatabase.instance;
    final packId = parsed.pack['meta']['id'] as String;
    var newWords = 0;
    var updatedWords = 0;
    var identicalWords = 0;
    var mergedWords = 0;
    for (final entry in _entries(parsed.pack)) {
      final aliases = await db.query(
        'vocab_entry_aliases',
        columns: ['word_id'],
        where: 'pack_id = ? AND entry_id = ?',
        whereArgs: [packId, entry['id']],
        limit: 1,
      );
      final rows = aliases.isNotEmpty
          ? await db.query(
              'words',
              where: 'id = ?',
              whereArgs: [aliases.single['word_id']],
              limit: 1,
            )
          : await db.query(
              'words',
              where: 'term_key = ? AND COALESCE(sense, \'\') = ?',
              whereArgs: [entry['term_key'], entry['sense'] ?? ''],
              limit: 1,
            );
      if (rows.isEmpty) {
        newWords++;
      } else if (aliases.isEmpty) {
        mergedWords++;
      } else if (_hasSameContent(rows.single, entry)) {
        identicalWords++;
      } else {
        updatedWords++;
      }
    }
    return VocabPackPreview(
      pack: parsed.pack,
      newWords: newWords,
      updatedWords: updatedWords,
      identicalWords: identicalWords,
      mergedWords: mergedWords,
      duplicateWords: parsed.duplicateWords,
    );
  }

  static Future<int> importPack(VocabPackPreview preview) async {
    final pack = preview.pack;
    pack.putIfAbsent('grammar', () => <dynamic>[]);
    final meta = Map<String, dynamic>.from(pack['meta'] as Map);
    final packId = meta['id'] as String;
    final db = await AppDatabase.instance;
    return db.transaction((txn) async {
      await txn.insert('vocab_packs', {
        'id': packId,
        'title': meta['title'],
        'source_lang': meta['source_lang'],
        'target_lang': meta['target_lang'],
        'metadata': jsonEncode(meta),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete(
        'word_theme_links',
        where: 'pack_id = ?',
        whereArgs: [packId],
      );
      await txn.delete(
        'vocab_themes',
        where: 'pack_id = ?',
        whereArgs: [packId],
      );

      final themes = pack['themes'] as List<dynamic>;
      for (final rawTheme in themes) {
        final theme = Map<String, dynamic>.from(rawTheme as Map);
        await txn.insert('vocab_themes', {
          'pack_id': packId,
          'theme_id': theme['id'],
          'title': theme['title'],
          'display_order': theme['order'],
          'read_aloud': jsonEncode(theme['read_aloud'] ?? const []),
        });
      }

      final wordIds = <String, int>{};
      for (final entry in _entries(pack)) {
        final entryId = entry['id'] as String;
        final alias = await txn.query(
          'vocab_entry_aliases',
          columns: ['word_id'],
          where: 'pack_id = ? AND entry_id = ?',
          whereArgs: [packId, entryId],
          limit: 1,
        );
        Map<String, Object?>? existing;
        if (alias.isNotEmpty) {
          final rows = await txn.query(
            'words',
            where: 'id = ?',
            whereArgs: [alias.single['word_id']],
            limit: 1,
          );
          if (rows.isNotEmpty) existing = rows.single;
        } else {
          final rows = await txn.query(
            'words',
            where: 'term_key = ? AND COALESCE(sense, \'\') = ?',
            whereArgs: [entry['term_key'], entry['sense'] ?? ''],
            orderBy: 'id ASC',
            limit: 1,
          );
          if (rows.isNotEmpty) existing = rows.single;
        }

        final themeTitle = _primaryTheme(pack, entryId);
        final content = _wordContent(entry, themeTitle);
        final wordId = existing == null
            ? await txn.insert('words', {
                ...content,
                'ease': 2.5,
                'interval': 0,
                'reps': 0,
                'lapses': 0,
                'due': DateTime.now().toIso8601String(),
                'created': DateTime.now().toIso8601String(),
              })
            : existing['id'] as int;
        if (existing != null) {
          await txn.update(
            'words',
            content,
            where: 'id = ?',
            whereArgs: [wordId],
          );
        }
        await txn.insert('vocab_entry_aliases', {
          'pack_id': packId,
          'entry_id': entryId,
          'word_id': wordId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        wordIds[entryId] = wordId;
      }

      for (final rawTheme in themes) {
        final theme = Map<String, dynamic>.from(rawTheme as Map);
        final themeId = theme['id'] as String;
        final entries = theme['entries'] as List<dynamic>;
        final ids = <String>[
          ...entries.map((entry) => (entry as Map)['id'] as String),
          ...(theme['include'] as List<dynamic>? ?? const []).cast<String>(),
        ];
        for (final entryId in ids.toSet()) {
          await txn.insert('word_theme_links', {
            'pack_id': packId,
            'theme_id': themeId,
            'word_id': wordIds[entryId],
          });
        }
      }

      final grammar = pack['grammar'] as List<dynamic>;
      final grammarIds = grammar
          .map((item) => (item as Map)['id'] as String)
          .toList();
      if (grammarIds.isEmpty) {
        await txn.delete('rules', where: 'pack_id = ?', whereArgs: [packId]);
      } else {
        await txn.delete(
          'rules',
          where:
              'pack_id = ? AND pack_rule_id NOT IN (${List.filled(grammarIds.length, '?').join(',')})',
          whereArgs: [packId, ...grammarIds],
        );
      }
      for (final rawRule in grammar) {
        final rule = Map<String, dynamic>.from(rawRule as Map);
        final examples = (rule['examples'] as List<dynamic>)
            .map((item) {
              final example = item as Map;
              return '${example['en']} - ${example['fr']}';
            })
            .join('\n');
        final themeId = rule['theme'] as String?;
        final linkedTheme = themes
            .where((item) => (item as Map)['id'] == themeId)
            .cast<Map>()
            .firstOrNull;
        final values = <String, Object?>{
          'title': rule['title'],
          'theme': linkedTheme?['title'] ?? meta['title'],
          'explanation': rule['rule'],
          'examples': examples,
          'pack_id': packId,
          'pack_rule_id': rule['id'],
          'structure': rule['structure'],
          'mistakes': jsonEncode(rule['mistakes'] ?? const []),
          'tags': jsonEncode(rule['tags'] ?? const []),
        };
        final prior = await txn.query(
          'rules',
          columns: ['id'],
          where: 'pack_id = ? AND pack_rule_id = ?',
          whereArgs: [packId, rule['id']],
          limit: 1,
        );
        if (prior.isEmpty) {
          await txn.insert('rules', values);
        } else {
          await txn.update(
            'rules',
            values,
            where: 'id = ?',
            whereArgs: [prior.single['id']],
          );
        }
      }
      return _entries(pack).length;
    });
  }

  static Map<String, Object?> _wordContent(
    Map<String, dynamic> entry,
    String theme,
  ) => {
    'en': entry['term'],
    'fr': entry['translation'],
    'theme': theme,
    'term_key': entry['term_key'],
    'sense': entry['sense'],
    'stress': entry['stress'],
    'pos': entry['pos'],
    'context': entry['context'],
    'highlight': entry['highlight'],
    'note': entry['note'],
    'tags': jsonEncode(entry['tags'] ?? const []),
  };

  static String _primaryTheme(Map<String, dynamic> pack, String entryId) {
    for (final rawTheme in pack['themes'] as List<dynamic>) {
      final theme = rawTheme as Map;
      final entries = theme['entries'] as List<dynamic>;
      if (entries.any((entry) => (entry as Map)['id'] == entryId)) {
        return theme['title'] as String;
      }
    }
    return (pack['themes'] as List).first['title'] as String;
  }

  static VocabPackPreview _preview(
    Map<String, dynamic> pack,
    int duplicateCount,
  ) {
    return VocabPackPreview(
      pack: pack,
      newWords: _entries(pack).length,
      updatedWords: 0,
      identicalWords: 0,
      mergedWords: 0,
      duplicateWords: duplicateCount,
    );
  }

  static bool _hasSameContent(
    Map<String, Object?> existing,
    Map<String, dynamic> entry,
  ) {
    final pairs = <String, Object?>{
      'en': entry['term'],
      'fr': entry['translation'],
      'term_key': entry['term_key'],
      'sense': entry['sense'],
      'stress': entry['stress'],
      'pos': entry['pos'],
      'context': entry['context'],
      'highlight': entry['highlight'],
      'note': entry['note'],
      'tags': jsonEncode(entry['tags'] ?? const []),
    };
    return pairs.entries.every((pair) => existing[pair.key] == pair.value);
  }

  static List<Map<String, dynamic>> _entries(Map<String, dynamic> pack) =>
      (pack['themes'] as List<dynamic>)
          .expand((theme) => (theme as Map)['entries'] as List<dynamic>)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList();

  static void _validatePack(dynamic value) {
    if (value is! Map) {
      throw const VocabPackFormatException(
        'Le document doit être un objet JSON.',
      );
    }
    _required(value, 'format', 'vocab-pack', '');
    _required(value, 'version', '1.0', '');
    final meta = _object(value['meta'], 'meta');
    for (final field in ['id', 'title', 'source_lang', 'target_lang']) {
      _string(meta[field], 'meta.$field');
    }
    for (final field in ['course', 'source_file', 'created']) {
      if (meta.containsKey(field)) _stringValue(meta[field], 'meta.$field');
    }
    final themes = value['themes'];
    if (themes is! List || themes.isEmpty) {
      throw const VocabPackFormatException(
        'themes doit être une liste non vide.',
      );
    }
    final themeIds = <String>{};
    for (var index = 0; index < themes.length; index++) {
      final path = 'themes[$index]';
      final theme = _object(themes[index], path);
      _string(theme['id'], '$path.id');
      if (!themeIds.add(theme['id'] as String)) {
        throw VocabPackFormatException('$path.id dupliqué.');
      }
      _string(theme['title'], '$path.title');
      if (theme['order'] is! int) {
        throw VocabPackFormatException('$path.order doit être un entier.');
      }
      if (theme['entries'] is! List) {
        throw VocabPackFormatException('$path.entries doit être une liste.');
      }
      if (theme.containsKey('color')) {
        _stringValue(theme['color'], '$path.color');
      }
      final entries = theme['entries'] as List;
      for (var entryIndex = 0; entryIndex < entries.length; entryIndex++) {
        final entryPath = '$path.entries[$entryIndex]';
        final entry = _object(entries[entryIndex], entryPath);
        for (final field in ['id', 'term', 'term_key', 'translation']) {
          _string(entry[field], '$entryPath.$field');
        }
        for (final field in ['pos', 'context', 'highlight']) {
          if (entry.containsKey(field)) {
            _stringValue(entry[field], '$entryPath.$field');
          }
        }
        for (final field in ['stress', 'sense', 'note']) {
          if (entry.containsKey(field)) {
            _stringValue(entry[field], '$entryPath.$field');
          }
        }
        if (entry.containsKey('context') &&
            entry.containsKey('highlight') &&
            !(entry['context'] as String).contains(
              entry['highlight'] as String,
            )) {
          throw VocabPackFormatException(
            '$entryPath.highlight doit être présent dans context.',
          );
        }
        if (entry.containsKey('tags')) {
          _stringList(entry['tags'], '$entryPath.tags');
        }
      }
      if (theme.containsKey('include')) {
        _stringList(theme['include'], '$path.include');
      }
      if (theme.containsKey('read_aloud')) {
        final lines = theme['read_aloud'];
        if (lines is! List) {
          throw VocabPackFormatException(
            '$path.read_aloud doit être une liste.',
          );
        }
        for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
          final line = _object(
            lines[lineIndex],
            '$path.read_aloud[$lineIndex]',
          );
          for (final field in ['written', 'fr', 'en']) {
            _string(line[field], '$path.read_aloud[$lineIndex].$field');
          }
        }
      }
    }
    if (!value.containsKey('grammar')) {
      throw const VocabPackFormatException('grammar manquant.');
    }
    final grammar = value['grammar'];
    if (grammar is! List) {
      throw const VocabPackFormatException('grammar doit être une liste.');
    }
    final grammarIds = <String>{};
    for (var index = 0; index < grammar.length; index++) {
      final path = 'grammar[$index]';
      final rule = _object(grammar[index], path);
      for (final field in ['id', 'title', 'rule']) {
        _string(rule[field], '$path.$field');
      }
      if (!grammarIds.add(rule['id'] as String)) {
        throw VocabPackFormatException('$path.id dupliqué.');
      }
      if (rule.containsKey('theme')) {
        _string(rule['theme'], '$path.theme');
        if (!themeIds.contains(rule['theme'])) {
          throw VocabPackFormatException(
            '$path.theme référence un thème inconnu.',
          );
        }
      }
      if (rule.containsKey('structure')) {
        _stringValue(rule['structure'], '$path.structure');
      }
      for (final field in ['examples', 'mistakes']) {
        if (rule[field] is! List) {
          throw VocabPackFormatException('$path.$field doit être une liste.');
        }
      }
      for (
        var exampleIndex = 0;
        exampleIndex < (rule['examples'] as List).length;
        exampleIndex++
      ) {
        final example = _object(
          (rule['examples'] as List)[exampleIndex],
          '$path.examples[$exampleIndex]',
        );
        for (final field in ['en', 'fr']) {
          _string(example[field], '$path.examples[$exampleIndex].$field');
        }
      }
      if (rule.containsKey('tags')) _stringList(rule['tags'], '$path.tags');
      if (rule.containsKey('mistakes')) {
        for (
          var mistakeIndex = 0;
          mistakeIndex < (rule['mistakes'] as List).length;
          mistakeIndex++
        ) {
          final mistakePath = '$path.mistakes[$mistakeIndex]';
          final mistake = _object(
            (rule['mistakes'] as List)[mistakeIndex],
            mistakePath,
          );
          for (final field in ['wrong', 'right', 'explanation']) {
            _string(mistake[field], '$mistakePath.$field');
          }
        }
      }
    }
  }

  static Map _object(dynamic value, String path) {
    if (value is! Map) {
      throw VocabPackFormatException('$path doit être un objet.');
    }
    return value;
  }

  static void _required(Map value, String key, String expected, String path) {
    if (value[key] != expected) {
      throw VocabPackFormatException(
        '${path.isEmpty ? key : '$path.$key'} doit valoir "$expected".',
      );
    }
  }

  static void _string(dynamic value, String path) {
    if (value is! String || value.trim().isEmpty) {
      throw VocabPackFormatException('$path manquant ou invalide.');
    }
  }

  static void _stringValue(dynamic value, String path) {
    if (value is! String) {
      throw VocabPackFormatException('$path doit être un texte.');
    }
  }

  static void _stringList(dynamic value, String path) {
    if (value is! List) {
      throw VocabPackFormatException('$path doit être une liste de textes.');
    }
    for (var index = 0; index < value.length; index++) {
      _stringValue(value[index], '$path[$index]');
    }
  }
}
