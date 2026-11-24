import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'seed.dart';

class AppDatabase {
  static Future<Database>? _instance;

  static Future<Database> get instance => _instance ??= _openDatabase();

  static Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'flashcards.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            en TEXT NOT NULL,
            fr TEXT NOT NULL,
            theme TEXT NOT NULL,
            marked INTEGER NOT NULL DEFAULT 0,
            term_key TEXT,
            sense TEXT,
            stress TEXT,
            pos TEXT,
            context TEXT,
            highlight TEXT,
            note TEXT,
            tags TEXT NOT NULL DEFAULT '[]',
            ease REAL NOT NULL DEFAULT 2.5,
            interval INTEGER NOT NULL DEFAULT 0,
            reps INTEGER NOT NULL DEFAULT 0,
            lapses INTEGER NOT NULL DEFAULT 0,
            due TEXT NOT NULL,
            created TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_words_due ON words(due)');
        await db.execute('CREATE INDEX idx_words_theme ON words(theme)');

        await db.execute('''
          CREATE TABLE rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            theme TEXT NOT NULL,
            explanation TEXT NOT NULL,
            examples TEXT NOT NULL,
            pack_id TEXT,
            pack_rule_id TEXT,
            structure TEXT,
            mistakes TEXT NOT NULL DEFAULT '[]',
            tags TEXT NOT NULL DEFAULT '[]'
          )
        ''');

        await db.execute('''
          CREATE TABLE results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL CHECK (type IN ('vocab', 'grammar')),
            score INTEGER NOT NULL,
            total INTEGER NOT NULL,
            theme TEXT,
            date TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kind TEXT NOT NULL CHECK (kind IN ('word', 'theme')),
            ref TEXT NOT NULL,
            correct INTEGER NOT NULL CHECK (correct IN (0, 1)),
            date TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_reviews_date ON reviews(date)');

        await _createVocabPackTables(db);

        await db.execute('''
          CREATE TABLE srs_params (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        await Seed.insertAll(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE words ADD COLUMN marked INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 2) {
          for (final column in [
            'term_key TEXT',
            'sense TEXT',
            'stress TEXT',
            'pos TEXT',
            'context TEXT',
            'highlight TEXT',
            'note TEXT',
            "tags TEXT NOT NULL DEFAULT '[]'",
          ]) {
            await db.execute('ALTER TABLE words ADD COLUMN $column');
          }
          for (final column in [
            'pack_id TEXT',
            'pack_rule_id TEXT',
            'structure TEXT',
            "mistakes TEXT NOT NULL DEFAULT '[]'",
            "tags TEXT NOT NULL DEFAULT '[]'",
          ]) {
            await db.execute('ALTER TABLE rules ADD COLUMN $column');
          }
          await _createVocabPackTables(db);
        }
      },
    );
  }

  static Future<void> _createVocabPackTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE vocab_packs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        source_lang TEXT NOT NULL,
        target_lang TEXT NOT NULL,
        metadata TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE vocab_themes (
        pack_id TEXT NOT NULL,
        theme_id TEXT NOT NULL,
        title TEXT NOT NULL,
        display_order INTEGER NOT NULL,
        read_aloud TEXT NOT NULL DEFAULT '[]',
        PRIMARY KEY (pack_id, theme_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE vocab_entry_aliases (
        pack_id TEXT NOT NULL,
        entry_id TEXT NOT NULL,
        word_id INTEGER NOT NULL,
        PRIMARY KEY (pack_id, entry_id),
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE word_theme_links (
        pack_id TEXT NOT NULL,
        theme_id TEXT NOT NULL,
        word_id INTEGER NOT NULL,
        PRIMARY KEY (pack_id, theme_id, word_id),
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE,
        FOREIGN KEY (pack_id, theme_id)
          REFERENCES vocab_themes(pack_id, theme_id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX idx_rules_pack_rule ON rules(pack_id, pack_rule_id)',
    );
  }

  static Future<void> reset() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'flashcards.db');
    final databaseFuture = _instance;
    _instance = null;

    if (databaseFuture != null) {
      await (await databaseFuture).close();
    }
    await deleteDatabase(path);
  }
}
