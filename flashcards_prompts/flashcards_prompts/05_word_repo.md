# 05 - lib/data/word_repo.dart

## Prompt
Crée `lib/data/word_repo.dart` avec une classe `WordRepo` (méthodes statiques, utilise `AppDatabase.instance`) :
- `Future<List<Word>> all({String? theme, String? search})` : tri alphabétique sur `en`, filtre thème exact, recherche LIKE sur en ou fr.
- `Future<List<String>> themes()` : thèmes distincts triés.
- `Future<int> insert(Word w)`, `Future<void> update(Word w)`, `Future<void> delete(int id)`.
- `Future<List<Word>> due(int limit)` : mots dont `due <= now`, triés par due croissant.
- `Future<List<Word>> random(int limit, {List<int> excludeIds = const []})` : ORDER BY RANDOM().
- `Future<List<Word>> pickForTest(int count)` : prend d'abord `due(count)`, complète avec `random` pour atteindre `count` sans doublon.
- `Future<int> countDue()`, `Future<int> countMastered()`, `Future<int> countAll()`.
- `Future<void> saveSrs(Word w)` : met à jour uniquement ease, interval, reps, lapses, due.
