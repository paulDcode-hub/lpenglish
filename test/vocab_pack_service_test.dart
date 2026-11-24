import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'package:lpenglis/data/database.dart';
import 'package:lpenglis/data/word_repo.dart';
import 'package:lpenglis/services/vocab_pack_service.dart';

void main() {
  late String fixture;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final separator = Platform.pathSeparator;
    fixture = File(
      'lib${separator}vocab_choix${separator}Exemple_Test1.vocab.json',
    ).readAsStringSync();
  });

  setUp(() async {
    await AppDatabase.reset();
  });

  tearDown(() async {
    await AppDatabase.reset();
  });

  test('valide l’exemple et signale les chemins de champs invalides', () {
    final preview = VocabPackService.parseAndPreview(fixture);
    expect(preview.title, 'Vocabulaire du Test 1');
    expect(preview.themeCount, 6);
    expect(preview.wordCount, 11);

    final invalid = fixture.replaceFirst('"translation": "tension",', '');
    expect(
      () => VocabPackService.parseAndPreview(invalid),
      throwsA(
        isA<VocabPackFormatException>().having(
          (error) => error.message,
          'message',
          contains('themes[0].entries[0].translation'),
        ),
      ),
    );
  });

  test(
    'importe une fois les mots partagés et réimporte sans doublon',
    () async {
      final preview = await VocabPackService.readAndPreview(fixture);
      expect(preview.newWords, 11);
      await VocabPackService.importPack(preview);

      final capWords = await WordRepo.all(theme: 'Capacitors – Vocabulary');
      expect(capWords.where((word) => word.en == 'resistor'), hasLength(1));
      expect(capWords.where((word) => word.en == 'voltage'), hasLength(1));

      final secondPreview = await VocabPackService.readAndPreview(fixture);
      expect(secondPreview.identicalWords, 11);
      await VocabPackService.importPack(secondPreview);

      final tangentWords = await WordRepo.all(search: 'tangent');
      expect(tangentWords, hasLength(2));
      expect(tangentWords.map((word) => word.sense).toSet(), {
        'tangente à une courbe',
        'fonction tangente',
      });
    },
  );

  test('met à jour le contenu sans modifier la progression', () async {
    final preview = await VocabPackService.readAndPreview(fixture);
    await VocabPackService.importPack(preview);

    final voltage = (await WordRepo.all()).singleWhere(
      (word) => word.en == 'voltage',
    );
    final due = DateTime.now().add(const Duration(days: 12));
    await WordRepo.update(
      voltage.copyWith(ease: 2.9, interval: 30, reps: 8, lapses: 2, due: due),
    );

    final modified = fixture.replaceFirst(
      '"translation": "tension"',
      '"translation": "tension électrique"',
    );
    final modifiedPreview = await VocabPackService.readAndPreview(modified);
    expect(modifiedPreview.updatedWords, 1);
    await VocabPackService.importPack(modifiedPreview);

    final updated = (await WordRepo.all()).singleWhere(
      (word) => word.en == 'voltage',
    );
    expect(updated.fr, 'tension électrique');
    expect(updated.ease, 2.9);
    expect(updated.interval, 30);
    expect(updated.reps, 8);
    expect(updated.lapses, 2);
    expect(updated.due, due);
  });

  test(
    'filtre les tests et les flashcards par thème, labels et mots marqués',
    () async {
      final preview = await VocabPackService.readAndPreview(fixture);
      await VocabPackService.importPack(preview);

      final words = await WordRepo.all();
      final voltage = words.singleWhere((word) => word.en == 'voltage');
      final resistor = words.singleWhere((word) => word.en == 'resistor');
      await WordRepo.update(
        voltage.copyWith(marked: true, tags: ['difficile']),
      );
      await WordRepo.update(resistor.copyWith(tags: ['électronique']));

      final labels = await WordRepo.labels();
      expect(labels, containsAll(['difficile', 'électronique']));

      final labelFiltered = await WordRepo.all(
        labels: {'difficile', 'électronique'},
      );

      expect(
        labelFiltered.map((word) => word.en),
        containsAll(['voltage', 'resistor']),
      );

      final marked = await WordRepo.all(markedOnly: true);
      expect(marked.map((word) => word.en), ['voltage']);

      final testWords = await WordRepo.pickForTest(
        10,
        theme: 'Capacitors – Vocabulary',
        labels: {'difficile'},
        markedOnly: true,
      );
      expect(testWords.map((word) => word.en), ['voltage']);
    },
  );

  test('rejette un JSON tronqué sans modifier la base', () async {
    final preview = VocabPackService.parseAndPreview(fixture);
    expect(
      () => VocabPackService.parseAndPreview('{"format":'),
      throwsA(isA<VocabPackFormatException>()),
    );
    expect(await WordRepo.countAll(), greaterThan(0));
    expect(preview.themeCount, greaterThan(0));
  });

  test('migra les données existantes sans perdre leur progression', () async {
    final databasePath = path.join(
      await databaseFactory.getDatabasesPath(),
      'flashcards.db',
    );
    final legacyDb = await databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE words (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              en TEXT NOT NULL,
              fr TEXT NOT NULL,
              theme TEXT NOT NULL,
              ease REAL NOT NULL DEFAULT 2.5,
              interval INTEGER NOT NULL DEFAULT 0,
              reps INTEGER NOT NULL DEFAULT 0,
              lapses INTEGER NOT NULL DEFAULT 0,
              due TEXT NOT NULL,
              created TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE rules (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              theme TEXT NOT NULL,
              explanation TEXT NOT NULL,
              examples TEXT NOT NULL
            )
          ''');
          await db.insert('words', {
            'en': 'legacy',
            'fr': 'existant',
            'theme': 'Ancien thème',
            'ease': 3.1,
            'interval': 24,
            'reps': 7,
            'lapses': 1,
            'due': '2026-11-20T12:00:00.000',
            'created': '2026-01-01T10:00:00.000',
          });
        },
      ),
    );
    await legacyDb.close();

    final migrated = (await WordRepo.all()).singleWhere(
      (word) => word.en == 'legacy',
    );
    expect(migrated.fr, 'existant');
    expect(migrated.ease, 3.1);
    expect(migrated.interval, 24);
    expect(migrated.reps, 7);
    expect(migrated.lapses, 1);
    expect(migrated.termKey, isNull);
  });
}
