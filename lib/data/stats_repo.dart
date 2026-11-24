import 'package:sqflite/sqflite.dart';

import '../models/review.dart';
import '../models/test_result.dart';
import '../models/vocabulary_stats.dart';
import 'database.dart';

class StatsRepo {
  static Future<VocabularyStats> vocabularyStats() async {
    final db = await AppDatabase.instance;
    final rows = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM reviews WHERE kind = 'word') AS review_count,
        (SELECT COALESCE(SUM(correct), 0) FROM reviews WHERE kind = 'word') AS correct_count,
        (
          SELECT COUNT(DISTINCT words.id)
          FROM reviews
          INNER JOIN words ON words.id = CAST(reviews.ref AS INTEGER)
          WHERE reviews.kind = 'word'
        ) AS reviewed_word_count,
        (SELECT COUNT(*) FROM words) AS total_word_count
    ''');
    final row = rows.first;
    final pointRows = await db.query(
      'srs_params',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['flashcard_xp'],
      limit: 1,
    );
    final savedXp = pointRows.isEmpty
        ? 0
        : int.tryParse(pointRows.first['value'] as String? ?? '') ?? 0;

    return VocabularyStats(
      flashcardXp: savedXp,
      reviewCount: (row['review_count'] as num).toInt(),
      correctCount: (row['correct_count'] as num).toInt(),
      reviewedWordCount: (row['reviewed_word_count'] as num).toInt(),
      totalWordCount: (row['total_word_count'] as num).toInt(),
    );
  }

  static Future<List<FlashcardPerformance>> flashcardPerformance({
    int limit = 10,
  }) async {
    if (limit <= 0) return [];

    final db = await AppDatabase.instance;
    final rows = await db.rawQuery(
      '''
      SELECT
        words.id AS id,
        words.en AS en,
        words.fr AS fr,
        COUNT(reviews.id) AS review_count,
        COALESCE(SUM(reviews.correct), 0) AS correct_count
      FROM words
      INNER JOIN reviews
        ON words.id = CAST(reviews.ref AS INTEGER)
        AND reviews.kind = 'word'
      GROUP BY words.id
      ORDER BY
        (SUM(reviews.correct) * 1.0 / COUNT(reviews.id)) ASC,
        COUNT(reviews.id) DESC,
        words.en COLLATE NOCASE ASC
      LIMIT ?
      ''',
      [limit],
    );
    return rows.map(FlashcardPerformance.fromMap).toList();
  }

  static Future<void> addResult(TestResult result) async {
    final db = await AppDatabase.instance;
    await db.insert('results', result.toMap());
  }

  static Future<void> addReview(Review review) async {
    final db = await AppDatabase.instance;
    await db.insert('reviews', review.toMap());
  }

  static Future<void> addReviews(List<Review> reviews) async {
    if (reviews.isEmpty) return;

    final db = await AppDatabase.instance;
    final batch = db.batch();
    for (final review in reviews) {
      batch.insert('reviews', review.toMap());
    }
    await batch.commit(noResult: true);
  }

  static Future<List<TestResult>> results({
    String? type,
    int limit = 50,
  }) async {
    if (limit <= 0) return [];

    final db = await AppDatabase.instance;
    final rows = await db.query(
      'results',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null ? null : [type],
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    return rows.map(TestResult.fromMap).toList();
  }

  static Future<double> averageScore({String? type}) async {
    final db = await AppDatabase.instance;
    final conditions = <String>['total > 0'];
    final arguments = <Object?>[];
    if (type != null) {
      conditions.add('type = ?');
      arguments.add(type);
    }

    final rows = await db.rawQuery(
      'SELECT AVG(score * 100.0 / total) AS average '
      'FROM results WHERE ${conditions.join(' AND ')}',
      arguments,
    );
    return (rows.first['average'] as num?)?.toDouble() ?? 0;
  }

  static Future<Map<String, double>> accuracyByTheme() async {
    final db = await AppDatabase.instance;
    final rows = await db.rawQuery('''
      SELECT theme, SUM(correct) * 100.0 / COUNT(*) AS accuracy
      FROM (
        SELECT ref AS theme, correct
        FROM reviews
        WHERE kind = 'theme'
        UNION ALL
        SELECT words.theme AS theme, reviews.correct AS correct
        FROM reviews
        INNER JOIN words ON words.id = CAST(reviews.ref AS INTEGER)
        WHERE reviews.kind = 'word'
      ) AS theme_reviews
      GROUP BY theme
    ''');

    return {
      for (final row in rows)
        row['theme'] as String: (row['accuracy'] as num).toDouble(),
    };
  }

  static Future<int> streakDays() async {
    final db = await AppDatabase.instance;
    final rows = await db.rawQuery('''
      SELECT DISTINCT substr(date, 1, 10) AS day
      FROM results
      ORDER BY day DESC
    ''');
    if (rows.isEmpty) return 0;

    var expected = DateTime.now();
    var streak = 0;
    for (final row in rows) {
      final date = DateTime.parse(row['day'] as String);
      if (date.year != expected.year ||
          date.month != expected.month ||
          date.day != expected.day) {
        break;
      }
      streak++;
      expected = DateTime(expected.year, expected.month, expected.day - 1);
    }
    return streak;
  }

  static Future<List<Review>> recentReviews(int limit) async {
    if (limit <= 0) return [];

    final db = await AppDatabase.instance;
    final rows = await db.query(
      'reviews',
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    return rows.map(Review.fromMap).toList();
  }

  static Future<int> testCountSinceLastOptimization() async {
    final db = await AppDatabase.instance;
    final params = await db.query(
      'srs_params',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['last_opt_result_id'],
      limit: 1,
    );
    final lastId =
        int.tryParse(params.firstOrNull?['value'] as String? ?? '') ?? 0;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) FROM results WHERE id > ?',
      [lastId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
