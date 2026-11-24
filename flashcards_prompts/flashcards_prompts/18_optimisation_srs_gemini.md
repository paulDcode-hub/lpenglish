# 18 - Ajout de l'optimisation Gemini dans srs_service.dart

## Prompt
Voici mon fichier actuel `lib/services/srs_service.dart` (colle-le ici). Ajoute la méthode :
`static Future<String?> maybeOptimize({bool force = false})`
- Si `!force` et `StatsRepo.testCountSinceLastOptimization()` < 5, retourne null sans rien faire.
- Sinon : construit `wordStats` (les 60 mots ayant le plus de révisions ou de lapses : id, en, reps, lapses, ease, interval) depuis `WordRepo`, la précision par thème depuis `StatsRepo.accuracyByTheme()`, charge les params, appelle `GeminiService.optimizeSrs(...)`, puis `applyOptimization(json)` et retourne `json['comment']`.
- Toute erreur est attrapée : retourne null (l'app ne doit jamais planter à cause de Gemini) et log avec `debugPrint`.
Ensuite, indique les lignes exactes à décommenter/ajouter à la fin de `vocab_test_screen.dart` et `grammar_test_screen.dart` pour appeler `SrsService.maybeOptimize()` sans attendre (fire-and-forget, sans `await`) après l'enregistrement du résultat.
