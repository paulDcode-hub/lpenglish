import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../data/stats_repo.dart';
import '../data/word_repo.dart';
import '../models/review.dart';
import '../models/word.dart';
import 'gemini_service.dart';

class SrsService {
  static const int flashcardXpPerCorrectAnswer = 10;

  static const Map<String, double> _defaultParams = {
    'interval_modifier': 1.0,
    'ease_min': 1.3,
    'ease_max': 3.0,
    'lapse_penalty': 0.2,
    'first_interval': 1.0,
    'second_interval': 3.0,
  };

  static Map<String, double>? _cachedParams;
  static Future<Map<String, double>>? _paramsLoad;

  static Future<Map<String, double>> loadParams() async {
    final cached = _cachedParams;
    if (cached != null) return Map<String, double>.from(cached);

    final pending = _paramsLoad ??= _readParams();
    final params = await pending;
    _cachedParams = Map<String, double>.from(params);
    if (identical(_paramsLoad, pending)) _paramsLoad = null;
    return Map<String, double>.from(params);
  }

  static Future<Map<String, double>> _readParams() async {
    final params = Map<String, double>.from(_defaultParams);
    final db = await AppDatabase.instance;
    final rows = await db.query('srs_params');
    for (final row in rows) {
      final key = row['key'] as String;
      final value = double.tryParse(row['value'] as String);
      if (params.containsKey(key) && value != null && value.isFinite) {
        params[key] = value;
      }
    }
    return params;
  }

  static Future<void> saveParams(Map<String, double> values) async {
    final params = await loadParams();
    for (final entry in values.entries) {
      if (entry.value.isFinite) params[entry.key] = entry.value;
    }

    final db = await AppDatabase.instance;
    await db.transaction((transaction) async {
      final batch = transaction.batch();
      for (final entry in values.entries) {
        if (!entry.value.isFinite) continue;
        batch.insert('srs_params', {
          'key': entry.key,
          'value': entry.value.toString(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
    _cachedParams = params;
  }

  static Word review(Word word, bool correct, Map<String, double> params) {
    final now = DateTime.now();
    final easeMin = params['ease_min'] ?? _defaultParams['ease_min']!;
    final easeMax = params['ease_max'] ?? _defaultParams['ease_max']!;

    if (correct) {
      final reps = word.reps + 1;
      final int interval;
      if (reps == 1) {
        interval = (params['first_interval'] ?? 1).round();
      } else if (reps == 2) {
        interval = (params['second_interval'] ?? 3).round();
      } else {
        final calculated =
            (word.interval * word.ease * (params['interval_modifier'] ?? 1.0))
                .round();
        interval = calculated < word.interval + 1
            ? word.interval + 1
            : calculated;
      }

      final ease = _clamp(word.ease + 0.05, easeMin, easeMax);
      return word.copyWith(
        ease: ease,
        interval: interval,
        reps: reps,
        due: now.add(Duration(days: interval)),
      );
    }

    final ease = _clamp(
      word.ease - (params['lapse_penalty'] ?? _defaultParams['lapse_penalty']!),
      easeMin,
      easeMax,
    );
    return word.copyWith(
      ease: ease,
      interval: 0,
      reps: 0,
      lapses: word.lapses + 1,
      due: now.add(const Duration(minutes: 10)),
    );
  }

  static Future<void> applyReviews(List<(Word, bool)> answers) async {
    if (answers.isEmpty) return;

    final params = await loadParams();
    final reviews = <Review>[];
    for (final answer in answers) {
      final word = answer.$1;
      final correct = answer.$2;
      final id = word.id;
      if (id == null) throw ArgumentError('Word.id ne peut pas être null.');

      final updated = review(word, correct, params);
      await WordRepo.saveSrs(updated);
      reviews.add(
        Review(
          kind: 'word',
          ref: id.toString(),
          correct: correct,
          date: DateTime.now(),
        ),
      );
    }
    await StatsRepo.addReviews(reviews);
  }

  static Future<void> applyFlashcardReview(Word word, bool correct) async {
    final id = word.id;
    if (id == null) throw ArgumentError('Word.id ne peut pas être null.');

    final params = await loadParams();
    final updatedWord = review(word, correct, params);
    final db = await AppDatabase.instance;
    await db.transaction((transaction) async {
      await transaction.update(
        'words',
        {
          'ease': updatedWord.ease,
          'interval': updatedWord.interval,
          'reps': updatedWord.reps,
          'lapses': updatedWord.lapses,
          'due': updatedWord.due.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await transaction.insert(
        'reviews',
        Review(
          kind: 'word',
          ref: id.toString(),
          correct: correct,
          date: DateTime.now(),
        ).toMap(),
      );

      if (correct) {
        final rows = await transaction.query(
          'srs_params',
          columns: ['value'],
          where: 'key = ?',
          whereArgs: ['flashcard_xp'],
          limit: 1,
        );
        final currentXp = rows.isEmpty
            ? 0
            : int.tryParse(rows.first['value'] as String? ?? '') ?? 0;
        await transaction.insert('srs_params', {
          'key': 'flashcard_xp',
          'value': (currentXp + flashcardXpPerCorrectAnswer).toString(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  static Future<void> applyThemeReviews(
    Map<String, (int ok, int total)> perTheme,
  ) async {
    final now = DateTime.now();
    final reviews = <Review>[];
    for (final entry in perTheme.entries) {
      final correctCount = entry.value.$1;
      final total = entry.value.$2;
      for (var index = 0; index < total; index++) {
        reviews.add(
          Review(
            kind: 'theme',
            ref: entry.key,
            correct: index < correctCount,
            date: now,
          ),
        );
      }
    }
    await StatsRepo.addReviews(reviews);
  }

  static Future<void> applyOptimization(Map<String, dynamic> json) async {
    final updatedParams = <String, double>{};
    final intervalModifier = _asDouble(json['interval_modifier']);
    final lapsePenalty = _asDouble(json['lapse_penalty']);

    if (intervalModifier != null) {
      updatedParams['interval_modifier'] = _clamp(intervalModifier, 0.6, 1.6);
    }
    if (lapsePenalty != null) {
      updatedParams['lapse_penalty'] = _clamp(lapsePenalty, 0.1, 0.4);
    }
    if (updatedParams.isNotEmpty) await saveParams(updatedParams);

    final db = await AppDatabase.instance;
    final now = DateTime.now().toIso8601String();
    final priorityIds = _priorityIds(json['priority_word_ids']);
    if (priorityIds.isNotEmpty) {
      final batch = db.batch();
      for (final id in priorityIds) {
        batch.update('words', {'due': now}, where: 'id = ?', whereArgs: [id]);
      }
      await batch.commit(noResult: true);
    }

    final resultRows = await db.rawQuery(
      'SELECT MAX(id) AS last_id FROM results',
    );
    final lastResultId = resultRows.first['last_id'] as int? ?? 0;
    await db.insert('srs_params', {
      'key': 'last_opt_result_id',
      'value': lastResultId.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String?> maybeOptimize({bool force = false}) async {
    try {
      if (!force && await StatsRepo.testCountSinceLastOptimization() < 5) {
        return null;
      }

      final words = await WordRepo.all();
      words.sort((first, second) {
        final reviewCount = (second.reps + second.lapses).compareTo(
          first.reps + first.lapses,
        );
        if (reviewCount != 0) return reviewCount;
        return second.lapses.compareTo(first.lapses);
      });
      final wordStats = words
          .where((word) => word.id != null)
          .take(60)
          .map(
            (word) => <String, dynamic>{
              'id': word.id!,
              'en': word.en,
              'reps': word.reps,
              'lapses': word.lapses,
              'ease': word.ease,
              'interval': word.interval,
            },
          )
          .toList();
      final params = await loadParams();
      final themeAccuracy = await StatsRepo.accuracyByTheme();
      final result = await GeminiService.optimizeSrs(
        params: params,
        wordStats: wordStats,
        themeAccuracy: themeAccuracy,
      );
      await applyOptimization(result);

      final comment = result['comment'];
      return comment is String ? comment : null;
    } catch (error, stackTrace) {
      debugPrint('Échec de l’optimisation SRS : $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static List<int> _priorityIds(Object? value) {
    if (value is! List) return [];

    return value
        .map((id) {
          if (id is int) return id;
          if (id is num && id.isFinite && id == id.roundToDouble()) {
            return id.toInt();
          }
          return int.tryParse('$id');
        })
        .whereType<int>()
        .where((id) => id > 0)
        .toSet()
        .take(15)
        .toList();
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.isFinite ? value.toDouble() : null;
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed != null && parsed.isFinite ? parsed : null;
    }
    return null;
  }

  static double _clamp(double value, double minimum, double maximum) =>
      value.clamp(minimum, maximum).toDouble();
}
