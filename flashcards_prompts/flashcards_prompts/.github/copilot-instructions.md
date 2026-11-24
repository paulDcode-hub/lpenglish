# Contexte projet (lu automatiquement par Copilot)

App Android Flutter de flashcards pour apprendre l'anglais (vocabulaire + grammaire). Usage personnel, français -> anglais.

## Règles globales
- Architecture la plus simple possible : pas de Riverpod/Bloc/Provider. Uniquement StatefulWidget + setState + FutureBuilder.
- Stockage local : sqflite (SQLite). Aucune API backend.
- IA : Gemini via l'API REST avec le package `http` (clé via `--dart-define=GEMINI_KEY=...`).
- Graphiques : fl_chart.
- UI : thème sombre, minimaliste, aucune animation superflue, coins peu arrondis (rayon 4 maximum), pas d'ombres (elevation 0), une seule couleur d'accent.
- Textes de l'interface en français.
- Code commenté brièvement, null-safety, `const` quand possible, pas de dépendance inutile.
- Un fichier = une responsabilité. Ne jamais modifier un autre fichier que celui demandé sans le signaler.

## Structure
lib/main.dart, theme.dart, home_shell.dart
lib/models/ word.dart, rule.dart, test_result.dart, review.dart
lib/data/ database.dart, seed.dart, word_repo.dart, rule_repo.dart, stats_repo.dart
lib/services/ srs_service.dart, gemini_service.dart
lib/screens/ vocab_tab.dart, grammar_tab.dart, test_home.dart, vocab_test_screen.dart, grammar_test_screen.dart, stats_screen.dart
