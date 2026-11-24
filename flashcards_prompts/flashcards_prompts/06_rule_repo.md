# 06 - lib/data/rule_repo.dart

## Prompt
Crée `lib/data/rule_repo.dart` avec une classe `RuleRepo` (méthodes statiques) :
- `Future<List<Rule>> all({String? theme})` triées par thème puis titre.
- `Future<List<String>> themes()`.
- `Future<int> insert(Rule r)`, `Future<void> update(Rule r)`, `Future<void> delete(int id)`.
Même style que `word_repo.dart`.
