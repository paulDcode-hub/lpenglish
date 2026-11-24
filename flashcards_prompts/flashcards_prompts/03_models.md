# 03 - lib/models/ (4 fichiers courts, à demander dans le même prompt)

## Prompt
Crée dans `lib/models/` les fichiers `word.dart`, `rule.dart`, `test_result.dart`, `review.dart` en respectant le schéma SQL du contexte.
Pour chaque classe : champs `final`, constructeur nommé, `factory fromMap(Map<String, Object?>)`, `Map<String, Object?> toMap()` (sans l'id quand il est null), et `copyWith` uniquement pour `Word`.
- `Word` : id, en, fr, theme, ease, interval, reps, lapses, due (DateTime), created (DateTime). Getter `isDue` (due <= maintenant) et `isMastered` (interval >= 21).
- `Rule` : id, title, theme, explanation, examples (String) + getter `exampleList` (List<String>, split sur "\n", lignes vides ignorées).
- `TestResult` : id, type, score, total, theme (nullable), date.
- `Review` : id, kind, ref, correct (bool <-> 0/1), date.
Dates stockées en ISO8601 (String) dans la base. Aucune dépendance externe.
