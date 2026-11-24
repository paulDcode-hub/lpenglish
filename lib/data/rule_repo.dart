import '../models/rule.dart';
import 'database.dart';

class RuleRepo {
  static Future<List<Rule>> all({String? theme}) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'rules',
      where: theme == null ? null : 'theme = ?',
      whereArgs: theme == null ? null : [theme],
      orderBy: 'theme COLLATE NOCASE ASC, title COLLATE NOCASE ASC',
    );
    return rows.map(Rule.fromMap).toList();
  }

  static Future<List<String>> themes() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'rules',
      columns: ['theme'],
      distinct: true,
      orderBy: 'theme COLLATE NOCASE ASC',
    );
    return rows.map((row) => row['theme'] as String).toList();
  }

  static Future<int> insert(Rule rule) async {
    final db = await AppDatabase.instance;
    return db.insert('rules', rule.toMap());
  }

  static Future<void> update(Rule rule) async {
    final id = rule.id;
    if (id == null) throw ArgumentError('Rule.id ne peut pas être null.');

    final db = await AppDatabase.instance;
    await db.update('rules', rule.toMap(), where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> delete(int id) async {
    final db = await AppDatabase.instance;
    await db.delete('rules', where: 'id = ?', whereArgs: [id]);
  }
}