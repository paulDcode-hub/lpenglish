import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/word.dart';
import 'database.dart';

class WordRepo {
  static Future<List<Word>> all({
    String? theme,
    String? search,
    Set<String> labels = const {},
    bool markedOnly = false,
  }) async {
    final db = await AppDatabase.instance;
    final conditions = <String>[];
    final arguments = <Object?>[];

    if (theme != null) {
      conditions.add('(words.theme = ? OR vocab_themes.title = ?)');
      arguments
        ..add(theme)
        ..add(theme);
    }
    if (search != null && search.trim().isNotEmpty) {
      conditions.add('(words.en LIKE ? OR words.fr LIKE ?)');
      final pattern = '%${search.trim()}%';
      arguments
        ..add(pattern)
        ..add(pattern);
    }
    if (markedOnly) conditions.add('words.marked = 1');

    final rows = await db.rawQuery('''
      SELECT DISTINCT words.*
      FROM words
      LEFT JOIN word_theme_links ON word_theme_links.word_id = words.id
      LEFT JOIN vocab_themes
        ON vocab_themes.pack_id = word_theme_links.pack_id
        AND vocab_themes.theme_id = word_theme_links.theme_id
      ${conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}'}
      ORDER BY words.en COLLATE NOCASE ASC
    ''', arguments);
    final words = _toWords(rows);
    if (labels.isEmpty) return words;
    return words
        .where((word) => word.tags.any(labels.contains))
        .toList();
  }

  static Future<List<String>> themes() async {
    final db = await AppDatabase.instance;
    final rows = await db.rawQuery('''
      SELECT theme FROM (
        SELECT theme, 2147483647 AS theme_order FROM words
        WHERE id NOT IN (SELECT word_id FROM word_theme_links)
        UNION
        SELECT title AS theme, MIN(display_order) AS theme_order
        FROM vocab_themes GROUP BY title
      )
      GROUP BY theme
      ORDER BY theme_order ASC, theme COLLATE NOCASE ASC
    ''');
    return rows.map((row) => row['theme'] as String).toList();
  }

  static Future<List<String>> labels() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('words', columns: ['tags']);
    final labels = <String>{};
    for (final row in rows) {
      final tags = jsonDecode(row['tags'] as String) as List<dynamic>;
      labels.addAll(tags.cast<String>());
    }
    final result = labels.toList()
      ..sort((first, second) => first.toLowerCase().compareTo(second.toLowerCase()));
    return result;
  }

  static Future<List<Map<String, String>>> readAloud(String theme) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'vocab_themes',
      columns: ['read_aloud'],
      where: 'title = ?',
      whereArgs: [theme],
      orderBy: 'display_order ASC',
    );
    final seen = <String>{};
    final result = <Map<String, String>>[];
    for (final row in rows) {
      final items = jsonDecode(row['read_aloud'] as String) as List<dynamic>;
      for (final item in items) {
        final entry = Map<String, String>.from(item as Map);
        final key = jsonEncode(entry);
        if (seen.add(key)) result.add(entry);
      }
    }
    return result;
  }

  static Future<int> insert(Word word) async {
    final db = await AppDatabase.instance;
    return db.insert('words', word.toMap());
  }

  static Future<void> update(Word word) async {
    final id = word.id;
    if (id == null) throw ArgumentError('Word.id ne peut pas être null.');

    final db = await AppDatabase.instance;
    await db.update('words', word.toMap(), where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> delete(int id) async {
    final db = await AppDatabase.instance;
    await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Word>> due(int limit) async {
    if (limit <= 0) return [];

    final db = await AppDatabase.instance;
    final rows = await db.query(
      'words',
      where: 'due <= ?',
      whereArgs: [DateTime.now().toIso8601String()],
      orderBy: 'due ASC',
      limit: limit,
    );
    return _toWords(rows);
  }

  static Future<List<Word>> random(
    int limit, {
    List<int> excludeIds = const [],
  }) async {
    if (limit <= 0) return [];

    final db = await AppDatabase.instance;
    final where = excludeIds.isEmpty
        ? null
        : 'id NOT IN (${List.filled(excludeIds.length, '?').join(', ')})';
    final rows = await db.query(
      'words',
      where: where,
      whereArgs: excludeIds.isEmpty ? null : excludeIds,
      orderBy: 'RANDOM()',
      limit: limit,
    );
    return _toWords(rows);
  }

  static Future<int> countDue() async {
    final db = await AppDatabase.instance;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM words WHERE due <= ?',
      [DateTime.now().toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<int> countMastered() async {
    final db = await AppDatabase.instance;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM words WHERE interval >= 21',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<int> countAll() async {
    final db = await AppDatabase.instance;
    final result = await db.rawQuery('SELECT COUNT(*) FROM words');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<void> saveSrs(Word word) async {
    final id = word.id;
    if (id == null) throw ArgumentError('Word.id ne peut pas être null.');

    final db = await AppDatabase.instance;
    await db.update(
      'words',
      {
        'ease': word.ease,
        'interval': word.interval,
        'reps': word.reps,
        'lapses': word.lapses,
        'due': word.due.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> setMarked(Word word, bool marked) async {
    final id = word.id;
    if (id == null) throw ArgumentError('Word.id ne peut pas être null.');

    final db = await AppDatabase.instance;
    await db.update(
      'words',
      {'marked': marked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Word>> pickForTest(
    int count, {
    String? theme,
    Set<String> labels = const {},
    bool markedOnly = false,
  }) async {
    if (count <= 0) return [];

    final candidates = await all(
      theme: theme,
      labels: labels,
      markedOnly: markedOnly,
    );
    candidates.sort((first, second) {
      final dueOrder = first.due.compareTo(second.due);
      if (dueOrder != 0) return dueOrder;
      return first.en.toLowerCase().compareTo(second.en.toLowerCase());
    });
    final dueWords = candidates.where((word) => word.isDue).toList();
    final notDueWords = candidates.where((word) => !word.isDue).toList()
      ..shuffle();
    return [...dueWords, ...notDueWords].take(count).toList();
  }

  static List<Word> _toWords(List<Map<String, Object?>> rows) =>
      rows.map(Word.fromMap).toList();
}