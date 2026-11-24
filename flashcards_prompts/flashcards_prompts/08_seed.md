# 08 - lib/data/seed.dart

## Prompt
Crée `lib/data/seed.dart` avec `class Seed { static Future<void> insertAll(Database db) async {...} }`.
Insère dans une transaction avec batch :
- 60 mots courants d'anglais (niveau A2-B1) répartis en 6 thèmes de 10 : "Quotidien", "Travail", "Voyage", "Nourriture", "Émotions", "Verbes courants". Champs en/fr/theme, valeurs SRS par défaut, `due` = maintenant, `created` = maintenant.
- 12 règles de grammaire (title, theme, explanation en français courte et claire, examples = 3 exemples "phrase anglaise - traduction française" séparés par "\n") avec les thèmes : "Temps", "Modaux", "Comparatifs", "Articles", "Prépositions". Ex : Present simple vs continuous, Past simple, Present perfect, Futur (will / going to), Conditionnel type 1 et 2, Modaux can/could/must/should, Comparatif et superlatif, a/an/the, in/on/at.
Données en dur dans des listes const en haut du fichier.
