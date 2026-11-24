# 09 - lib/services/srs_service.dart

## Prompt
Crée `lib/services/srs_service.dart` : algorithme SM-2 modifié, paramétrable.

Paramètres globaux stockés dans `srs_params` (lus au premier appel puis mis en cache) avec valeurs par défaut :
`interval_modifier` = 1.0, `ease_min` = 1.3, `ease_max` = 3.0, `lapse_penalty` = 0.2, `first_interval` = 1, `second_interval` = 3.

Méthodes :
- `static Future<Map<String,double>> loadParams()` / `saveParams(Map<String,double>)`.
- `static Word review(Word w, bool correct, Map<String,double> p)` retourne un nouveau Word :
  - Correct : reps+1 ; reps==1 → interval=first_interval ; reps==2 → second_interval ; sinon interval = round(interval * ease * interval_modifier), minimum interval+1. ease += 0.05 (borné ease_max).
  - Faux : reps=0, lapses+1, interval=0 (à revoir dans 10 minutes : due = now+10min), ease -= lapse_penalty (borné ease_min).
  - due = now + interval jours (sauf cas faux).
- `static Future<void> applyReviews(List<(Word, bool)> answers)` : charge les params, applique `review` pour chaque, sauve via `WordRepo.saveSrs`, et ajoute les `Review` (kind 'word') via `StatsRepo.addReviews`.
- `static Future<void> applyThemeReviews(Map<String,(int ok,int total)> perTheme)` : ajoute des Review kind 'theme' (une par question) pour la grammaire.
- `static Future<void> applyOptimization(Map<String,dynamic> json)` : lit la réponse de Gemini (format défini dans le prompt 10) : met à jour les params (en les bornant : interval_modifier entre 0.6 et 1.6, lapse_penalty entre 0.1 et 0.4), et pour chaque id de `priority_word_ids` met due = now (mot à revoir en priorité). Sauvegarde `last_opt_result_id` = id du dernier résultat.
Code pur et testable, commentaires courts.
