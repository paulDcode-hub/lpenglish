# Format `.vocab.json` (vocab-pack v1.0)

Un fichier = un « pack » d'apprentissage (ex. : « Vocabulaire du Test 1 »).
Un pack contient des **thèmes** (listes de vocabulaire), des **points de grammaire**
et des **expressions à lire à voix haute**. L'application crée une liste par thème.

## Règles que je (Claude) respecterai à chaque génération

1. Extension : `NomDuPack.vocab.json`, encodage UTF-8, JSON valide (pas de commentaires).
2. `format` = `"vocab-pack"` et `version` = `"1.0"` toujours présents.
3. Un **thème** par section du document source (ex. TA1, Capacitors, Trigonometry, KiCad, WIMS, NPR).
4. Chaque entrée a un `id` **stable et unique** : `<theme.id>.<slug-du-terme>` (ex. `cap.parallel-plate-capacitor`).
5. `term_key` = terme en minuscules, sans accents ni ponctuation, espaces → `-`. Sert à détecter les doublons.
6. Un mot présent dans plusieurs sections :
   - même sens → défini UNE fois, les autres thèmes le citent via `include`;
   - sens différent (ex. `tangent` courbe vs fonction) → deux entrées distinctes, champ `sense` renseigné.
7. `context` = phrase d'exemple ; `highlight` = la partie de la phrase à mettre en gras (texte exact contenu dans `context`).
8. `stress` = schéma accentuel tel que dans le source (1 = principal, 2 = secondaire, 0 = inaccentué ; mots séparés par un espace ; variantes par ` / `). Chaîne vide si absent.
9. Aucune donnée inventée : un champ inconnu est omis (jamais `null`).
10. La grammaire n'est générée que si le document en contient (sinon `grammar: []`).

## Structure

```jsonc
{
  "format": "vocab-pack",
  "version": "1.0",
  "meta": {
    "id": "geii1-test1",              // slug unique du pack (sert à la ré-importation)
    "title": "Vocabulaire du Test 1",
    "source_lang": "en",
    "target_lang": "fr",
    "course": "Anglais – BUT GEII 1re année",
    "source_file": "Vocabulaire_Test_1.pdf",
    "created": "2026-11-02"
  },
  "themes": [
    {
      "id": "ta1",
      "title": "TA1 – Théorèmes de base de l'électronique (TP)",
      "order": 1,
      "color": "#2563eb",              // optionnel
      "include": ["cap.capacitance"],   // optionnel : entrées définies ailleurs
      "entries": [
        {
          "id": "ta1.voltage",
          "term": "voltage",
          "term_key": "voltage",
          "translation": "tension",
          "pos": "noun",                // optionnel : noun|verb|adj|adv|phrase|symbol|idiom
          "stress": "10",
          "context": "Set the voltage to 5 V before connecting the resistor.",
          "highlight": "voltage",
          "sense": "",                  // optionnel : désambiguïsation
          "note": "",                   // optionnel : remarque (faux ami, variante UK/US…)
          "tags": ["mesure"]            // optionnel
        }
      ],
      "read_aloud": [                   // optionnel : expressions à lire à voix haute
        { "written": "W = ½ CU²", "fr": "W égale un demi C U au carré", "en": "W equals one half C U squared." }
      ]
    }
  ],
  "grammar": [
    {
      "id": "gram.first-conditional",
      "theme": "ta1",                   // optionnel : thème lié
      "title": "…",
      "rule": "…",                      // explication en français
      "structure": "If + present simple, will + base verb",
      "examples": [ { "en": "…", "fr": "…" } ],
      "mistakes": [ { "wrong": "…", "right": "…", "explanation": "…" } ],
      "tags": []
    }
  ]
}
```

## Comportement attendu à l'import

- Ré-importer un pack de même `meta.id` **met à jour** (jamais de doublons).
- Une entrée est identifiée par son `id`. Si `id` inconnu mais `term_key` + `sense` identiques → fusion proposée.
- Les entrées d'un thème = ses `entries` + celles listées dans `include`.
