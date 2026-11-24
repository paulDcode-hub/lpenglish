# 12 - lib/screens/vocab_tab.dart

## Prompt
Crée `lib/screens/vocab_tab.dart` : `VocabTab` (StatefulWidget).
- En haut : champ de recherche compact + `DropdownButton` de filtre par thème (option "Tous les thèmes"), alimentés par `WordRepo`.
- Liste `ListView.separated` : chaque ligne affiche le mot anglais (gras) à gauche, sa traduction (couleur secondaire) à droite, le thème en petit dessous. Séparateur fin, pas de cartes surchargées.
- Tap sur une ligne : dialogue d'édition (en, fr, thème avec suggestions des thèmes existants). Appui long : confirmation de suppression.
- `FloatingActionButton` carré (rayon 4) pour ajouter un mot, même dialogue.
- Rechargement de la liste après chaque action. Compteur "N mots" discret. Utilise `AppTheme` pour les couleurs.
