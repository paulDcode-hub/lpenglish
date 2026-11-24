# 17 - lib/screens/stats_screen.dart

## Prompt
Crée `lib/screens/stats_screen.dart` : `StatsScreen` (StatefulWidget, `FutureBuilder` sur toutes les données, `RefreshIndicator`).
Sections, du haut vers le bas, sans cartes décoratives, séparées par des filets fins :
1. Ligne de 4 chiffres clés : moyenne vocabulaire (%), moyenne grammaire (%), série de jours (`streakDays`), mots maîtrisés / total (`countMastered` / `countAll`). Plus "À revoir aujourd'hui : N" (`countDue`).
2. Évolution : `fl_chart` `LineChart` des 20 derniers résultats (pourcentage), deux courbes (vocab en accent, grammaire en couleur secondaire), grille discrète, axe Y 0-100, pas d'animation, pas de zone remplie, points visibles. Message "Pas encore de données" si vide.
3. Précision par thème : liste de barres horizontales fines (LinearProgressIndicator plat, rayon 0 ou 2) avec le pourcentage, triées du plus faible au plus fort, couleur erreur si < 60 %.
4. Derniers tests : 10 lignes "date - type - score/total".
5. Bouton "Optimiser la répétition (Gemini)" qui appelle `SrsService.maybeOptimize(force: true)` (voir prompt 18) et affiche le commentaire renvoyé dans un `SnackBar` ; état de chargement simple.
Utilise `intl` pour les dates (dd/MM). Couleurs de `AppTheme`.
