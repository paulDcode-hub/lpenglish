# 15 - lib/screens/vocab_test_screen.dart

## Prompt
Crée `lib/screens/vocab_test_screen.dart` : `VocabTestScreen` (StatefulWidget).
Déroulé :
1. `initState` : charge 10 mots via `WordRepo.pickForTest(10)`. S'il y en a moins de 10, teste ce qu'il y a ; s'il n'y en a aucun, affiche un message.
2. Affichage sur une seule page scrollable : pour chaque mot, une ligne avec la traduction française (à traduire en anglais) et un `TextField` pour la saisie (une ligne, `textInputAction: next`, sans correction automatique ni suggestions). Barre de progression fine en haut (N/10 remplis). Bouton "Valider" en bas.
3. À la validation : comparaison normalisée (trim, minuscules, ignore la ponctuation finale, accepte le "to " optionnel devant les verbes, plusieurs traductions séparées par "/" ou "," acceptées). Puis passage en mode résultat sur la même page : chaque ligne devient verte (correct) ou rouge (avec la bonne réponse affichée), en gardant la saisie de l'utilisateur visible.
4. Note finale "N/10" en gros en haut du résultat. Enregistre : `SrsService.applyReviews(...)`, `StatsRepo.addResult(TestResult(type:'vocab',...))`. Puis appelle `_maybeOptimize()` (voir prompt 18, laisse un `// TODO` appelant `SrsService.maybeOptimize()` en commentaire).
5. Bouton "Terminer" (retour) et "Rejouer". Sobre, pas d'animation, pas de confettis.
