# Prompt à coller dans VS Code

Copie tout ce qui suit. Mets aussi dans le dossier du projet : `FORMAT_vocab-pack.md`,
`vocab-pack.schema.json` et `Exemple_Test1.vocab.json` (par ex. dans `docs/vocab-pack/`).

---

Tu travailles sur mon application d'apprentissage de vocabulaire. Je veux ajouter une
**fonction d'import de fichiers « vocab-pack »** qui crée automatiquement les listes de
vocabulaire (une par thème) et les fiches de grammaire.

## Étape 0 – Analyse avant de coder (obligatoire)
1. Explore le dépôt : langage, framework, gestion d'état, stockage (localStorage, IndexedDB,
   SQLite, backend/API…), modèle de données actuel des mots/listes, structure des écrans, tests.
2. Résume-moi en 10 lignes max ce que tu as trouvé et ton plan de modification, puis continue
   sans attendre sauf si un point bloquant nécessite ma décision.
3. Réutilise les conventions existantes (style, nommage, composants UI, librairies déjà
   installées). N'ajoute une dépendance que si c'est vraiment utile (validation JSON Schema : `ajv`
   ou `zod`), et dis-le-moi.

## Spécification du format
Lis `docs/vocab-pack/FORMAT_vocab-pack.md` (source de vérité), `vocab-pack.schema.json` et
`Exemple_Test1.vocab.json`. Résumé : un pack = `meta` + `themes[]` (chacun avec `entries[]`,
`include[]`, `read_aloud[]`) + `grammar[]`. Extension `.vocab.json`.

## Fonctionnalités à implémenter

### 1. Import
- Bouton « Importer un fichier » (sélecteur + glisser-déposer), accepte `.vocab.json` / `.json`.
- Lecture UTF-8, parsing, **validation contre le schéma**. En cas d'erreur : message clair avec
  le chemin du champ fautif (ex. `themes[2].entries[14].translation manquant`), aucun import partiel.
- **Écran de prévisualisation** avant validation : titre du pack, nombre de thèmes, mots
  nouveaux / mis à jour / identiques, doublons détectés, points de grammaire. Boutons Confirmer / Annuler.

### 2. Création des données
- Un **thème = une liste/instance** de vocabulaire, triée selon `order`, affichant le titre du thème.
- Chaque entrée devient un mot avec : terme, traduction, schéma accentuel (`stress`), phrase de
  contexte avec le `highlight` affiché en **gras**, `pos`, `note`, `sense`, `tags`.
- `include` : le mot apparaît dans plusieurs listes **sans être dupliqué** (relation, pas copie),
  et sa progression d'apprentissage reste partagée.
- `read_aloud` : section « Lecture à voix haute » dans le thème (écrit / français / anglais).
- `grammar` : section Grammaire avec règle, structure, exemples, erreurs fréquentes ; lien vers
  le thème si `theme` est renseigné.

### 3. Idempotence et fusion
- Clé du pack : `meta.id`. Ré-importer un pack existant **met à jour** sans créer de doublons.
- Clé d'une entrée : `id`. Si `id` inconnu mais même `term_key` + `sense` → proposer la fusion.
- Même `term_key` avec `sense` différent → fiches distinctes (ex. `tangent` courbe vs fonction).
- **Ne jamais écraser** la progression de l'utilisateur (scores, niveau de maîtrise, date de
  révision) lors d'une mise à jour ; seuls les champs de contenu changent.

### 4. Export (bonus, simple)
- Bouton « Exporter » qui régénère un `.vocab.json` valide à partir des données de l'application.

### 5. Migration
- Si le modèle de données actuel doit évoluer (ajout de `stress`, `sense`, `themes`, relation
  mot↔thèmes…), écris une migration non destructive et conserve les données existantes.

## Contraintes qualité
- Typage strict si TypeScript ; pas de `any`.
- Tests unitaires : validation (fichier valide / invalide), import nouveau, ré-import idempotent,
  `include`, deux sens du même terme, conservation de la progression.
- Utilise `Exemple_Test1.vocab.json` comme fixture de test.
- Accessibilité et mobile : l'import doit fonctionner sur petit écran.
- Textes de l'interface en français.

## Livrables
1. Le code (composants, services d'import/validation, migration, tests).
2. Un court `docs/IMPORT.md` expliquant comment importer un pack et le format des erreurs.
3. La liste des fichiers modifiés/créés et la commande pour lancer les tests.

Procède par petits commits logiques (schéma/validation → modèle & migration → import →
UI → export → tests). Lance les tests et le build à la fin et corrige ce qui échoue.
