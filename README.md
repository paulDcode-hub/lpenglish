# LP English

Application Android d’apprentissage de l’anglais, développée avec Flutter. Elle regroupe
des cartes de vocabulaire, des exercices de grammaire et des outils de révision pour suivre
sa progression.

## Fonctionnalités

- **Vocabulaire** : consulter, rechercher et gérer des mots par thème.
- **Marque-pages et labels** : marquer les mots difficiles et ajouter des labels personnalisés.
- **Tests ciblés** : choisir un thème, un ou plusieurs labels, et/ou limiter le test aux mots marqués. Un test sélectionne jusqu’à 10 mots correspondants.
- **Flashcards** : réviser les mots correspondants aux mêmes filtres, dans le sens anglais → français ou français → anglais.
- **Grammaire** : consulter les fiches et lancer des exercices générés par Gemini.
- **Répétition espacée et statistiques** : enregistrer les révisions, suivre les résultats et ajuster les intervalles.
- **Import vocab-pack** : importer un fichier JSON de vocabulaire depuis l’onglet Vocabulaire, après validation et aperçu. Voir [le guide d’import](docs/IMPORT.md) et le [format vocab-pack](lib/vocab_choix/FORMAT_vocab-pack.md).
- **Stockage local** : les mots, fiches, labels et données de révision sont stockés localement dans SQLite.

## Prérequis

- Flutter et Dart compatibles avec les versions indiquées dans [`pubspec.yaml`](pubspec.yaml).
- Android Studio ou les outils Android SDK pour compiler et exécuter l’application Android.
- Une clé API Gemini pour générer les exercices de grammaire.

## Installation et lancement

```bash
flutter pub get
flutter run
```

Pour activer les fonctionnalités Gemini, fournissez la clé au lancement sans l’ajouter au
dépôt :

```bash
flutter run --dart-define=GEMINI_KEY=VOTRE_CLE_API
```

Sans cette clé, les fonctionnalités qui interrogent Gemini ne peuvent pas fonctionner ; les
fonctions de vocabulaire et les flashcards restent disponibles.

## Tests et build Android

```bash
flutter analyze
flutter test
flutter build apk --debug
```

L’APK de débogage est généré dans :

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Organisation du code

- `lib/screens/` : écrans de vocabulaire, tests, flashcards, grammaire et statistiques.
- `lib/models/` : modèles des mots, règles, révisions et résultats.
- `lib/data/` : base SQLite, dépôts de données et données initiales.
- `lib/services/` : répétition espacée, génération Gemini et import vocab-pack.
- `test/` : tests Flutter.
