# 13 - lib/screens/grammar_tab.dart

## Prompt
Crée `lib/screens/grammar_tab.dart` : `GrammarTab` (StatefulWidget).
- Filtre par thème en haut (`DropdownButton`, option "Tous").
- Liste de règles : `ExpansionTile` simple par règle (titre + thème en petit). Déplié : explication, puis les exemples (`exampleList`) en lignes, phrase anglaise en couleur principale, traduction en couleur secondaire (split sur " - ").
- Ajout / modification / suppression comme dans `vocab_tab.dart` : FAB carré, dialogue avec champs titre, thème, explication (multiligne), exemples (multiligne, un par ligne, format "anglais - français"), appui long pour supprimer avec confirmation.
- Pas d'animations personnalisées, pas d'ombres.
