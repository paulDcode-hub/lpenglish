# 14 - lib/screens/test_home.dart

## Prompt
Crée `lib/screens/test_home.dart` : `TestHome` (StatelessWidget ou Stateful).
- Écran centré, très sobre : deux gros boutons plats rectangulaires (rayon 4) "Test de vocabulaire" et "Test de grammaire", chacun avec une ligne secondaire ("10 mots - N à revoir aujourd'hui" via `WordRepo.countDue()`, et "10 exercices générés par Gemini").
- Pour la grammaire : un `DropdownButton` optionnel "Thème : Tous / Temps / Modaux..." (thèmes issus de `RuleRepo.themes()`), transmis à l'écran de test.
- Navigation via `Navigator.push` vers `VocabTestScreen()` et `GrammarTestScreen(theme: ...)`. Au retour, rafraîchit le compteur.
