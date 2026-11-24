# 16 - lib/screens/grammar_test_screen.dart

## Prompt
Crée `lib/screens/grammar_test_screen.dart` : `GrammarTestScreen({String? theme})` (StatefulWidget).
1. `initState` : récupère les thèmes faibles (`StatsRepo.accuracyByTheme()`, ceux < 70 %), appelle `GeminiService.generateGrammarExercises(theme: theme, weakThemes: ...)` avec `FutureBuilder`. Pendant le chargement : indicateur de progression simple + texte "Génération des exercices...". En cas d'erreur : message d'erreur lisible + bouton "Réessayer" + bouton "Retour".
2. Affichage : liste de 10 exercices numérotés. Chaque phrase est affichée avec le trou "___" remplacé visuellement par un `TextField` compact en ligne (utilise `Wrap` ou `Row` avec `Text` avant/après le champ, largeur fixe ~110). Petit tag du thème à côté du numéro. Bouton "Valider" en bas.
3. Validation : comparaison insensible à la casse, trim, contre `answer` ET `accepted`. Mode résultat sur la même page : ligne verte/rouge, bonne réponse affichée si faux, `explanation` de Gemini affichée sous chaque exercice.
4. Note "N/10". Enregistre via `StatsRepo.addResult(TestResult(type:'grammar', theme: theme, ...))` et `SrsService.applyThemeReviews(...)` (une review par question, ref = thème). Bouton "Terminer" / "Nouveau test".
Même style sobre que `vocab_test_screen.dart`.
