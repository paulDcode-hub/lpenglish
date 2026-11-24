# 04 - lib/data/database.dart

## Prompt
Crée `lib/data/database.dart` avec une classe `AppDatabase` (singleton) :
- `static Future<Database> get instance` qui ouvre (ou crée) `flashcards.db` avec sqflite, version 1.
- `onCreate` : crée les 5 tables du schéma SQL du contexte (words, rules, results, reviews, srs_params) avec index sur `words(due)`, `words(theme)`, `reviews(date)`.
- Après création des tables, appelle `Seed.insertAll(db)` (fichier `seed.dart`, à créer ensuite ; importe-le simplement).
- Méthode `static Future<void> reset()` qui supprime la base (utile pour le debug).
Pas de migrations complexes : version 1, `onUpgrade` vide avec commentaire.
