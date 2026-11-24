# 07 - lib/data/stats_repo.dart

## Prompt
Crée `lib/data/stats_repo.dart` avec une classe `StatsRepo` (méthodes statiques) :
- `Future<void> addResult(TestResult r)` et `Future<void> addReview(Review r)`.
- `Future<void> addReviews(List<Review> list)` en un seul batch/transaction.
- `Future<List<TestResult>> results({String? type, int limit = 50})` triés par date décroissante.
- `Future<double> averageScore({String? type})` : moyenne en pourcentage (score/total*100), 0 si aucun résultat.
- `Future<Map<String, double>> accuracyByTheme()` : pour reviews kind='theme' ET pour les mots (kind='word' joint à words.theme), pourcentage de bonnes réponses par thème.
- `Future<int> streakDays()` : nombre de jours consécutifs (jusqu'à aujourd'hui) avec au moins un résultat.
- `Future<List<Review>> recentReviews(int limit)` (pour l'optimisation par Gemini).
- `Future<int> testCountSinceLastOptimization()` : lit srs_params 'last_opt_result_id' et compte les results dont id supérieur.
