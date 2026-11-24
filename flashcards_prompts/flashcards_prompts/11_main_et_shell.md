# 11 - lib/main.dart et lib/home_shell.dart

## Prompt
Crée deux fichiers :
1. `lib/main.dart` : `WidgetsFlutterBinding.ensureInitialized()`, initialise la base (`await AppDatabase.instance`), lance `MaterialApp` (titre "Flashcards EN", `AppTheme.dark`, `debugShowCheckedModeBanner: false`, home: `HomeShell`).
2. `lib/home_shell.dart` : `HomeShell` (StatefulWidget) avec `BottomNavigationBar` de 3 onglets : Cartes (icône style), Test (icône edit), Stats (icône bar_chart), labels en français. Corps : `IndexedStack` avec `CardsScreen`... `_CardsScreen` défini dans ce fichier : un `DefaultTabController` de 2 onglets (Vocabulaire, Grammaire) avec `TabBarView` contenant `VocabTab` et `GrammarTab`. Test = `TestHome`, Stats = `StatsScreen`. Recrée la clé de `StatsScreen` (ou utilise un callback) pour qu'elle se rafraîchisse quand on revient sur l'onglet Stats. Imports vers les fichiers de `screens/` (pas encore créés).
