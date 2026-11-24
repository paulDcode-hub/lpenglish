# 02 - lib/theme.dart

## Prompt
Crée `lib/theme.dart` avec une classe `AppTheme` exposant `static ThemeData dark`.
- Material 3 désactivé (useMaterial3: false) pour un rendu plus plat.
- Fond 0xFF121212, surface/cartes 0xFF1C1C1C, bordures 0xFF2A2A2A, texte principal 0xFFE6E6E6, texte secondaire 0xFF9A9A9A, accent unique 0xFF4FC3F7, erreur 0xFFE57373, succès 0xFF81C784. Expose ces couleurs en constantes statiques dans `AppTheme` (bg, card, border, text, muted, accent, error, ok).
- Rayon de coins 4 partout (cartes, boutons, champs, dialogues). elevation 0 partout, pas d'ombres.
- AppBar plate sans ombre, BottomNavigationBar/NavigationBar plate avec l'accent pour l'élément sélectionné.
- InputDecoration : bordure fine 1px, remplissage surface, pas d'arrondi excessif.
- ElevatedButton : fond accent, texte noir, rayon 4. TextButton : texte accent.
- Typographie : police système, tailles sobres (titre 20, corps 16, secondaire 14).
