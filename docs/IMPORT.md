# Importer un pack de vocabulaire

Dans l’onglet **Vocabulaire**, utilisez l’icône d’import pour choisir un fichier `.vocab.json`
ou `.json`. L’application vérifie son contenu avant d’afficher un aperçu ; rien n’est écrit
dans la base avant le bouton **Confirmer**.

L’aperçu indique les thèmes, les entrées nouvelles, modifiées, identiques ou fusionnées avec
un mot existant de même `term_key` et de même `sense`, ainsi que les doublons détectés et les
points de grammaire.

En cas d’erreur, le message précise le chemin JSON fautif, par exemple
`themes[2].entries[14].translation manquant ou invalide`. L’import est transactionnel : un pack
invalide ou une erreur pendant l’écriture ne laisse aucune importation partielle.

Réimporter le même `meta.id` met à jour son contenu. Les entrées partagées entre thèmes sont
stockées une seule fois ; leurs révisions et leur progression restent communes. Les mises à
jour de contenu ne changent pas les scores, intervalles, répétitions, oublis ni dates de révision.
Les fiches de grammaire liées à un thème sont affichées sous le nom de ce thème.

Dans **Vocabulaire**, modifiez une fiche pour lui ajouter des labels séparés par des virgules
ou activez **Mot difficile à revoir**. Les écrans **Test de vocabulaire** et **Révision de
vocabulaire** permettent ensuite de filtrer par thème, par un ou plusieurs labels, et/ou par
mots marqués. Plusieurs labels sélectionnés fonctionnent en « au moins un » ; sans label
sélectionné, aucun filtre de label n’est appliqué. Un test prend jusqu’à 10 mots du groupe
filtré ; une révision parcourt toutes les cartes correspondantes.

Le format est décrit dans [`../lib/vocab_choix/FORMAT_vocab-pack.md`](../lib/vocab_choix/FORMAT_vocab-pack.md)
et son schéma se trouve dans [`../lib/vocab_choix/vocab-pack.schema.json`](../lib/vocab_choix/vocab-pack.schema.json).
