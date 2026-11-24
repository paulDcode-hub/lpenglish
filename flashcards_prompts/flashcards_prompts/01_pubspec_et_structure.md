# 01 - Initialisation du projet (terminal + pubspec.yaml)

Commandes à lancer toi-même :
    flutter create --platforms=android --org com.moi flashcards_en
    cd flashcards_en
    mkdir lib/models lib/data lib/services lib/screens

## Prompt
Voici mon pubspec.yaml actuel (colle-le ici). Modifie uniquement la section `dependencies` pour ajouter : sqflite, path, http, fl_chart, intl (dernières versions stables compatibles). Donne-moi aussi :
1. Le bloc à ajouter dans android/app/src/main/AndroidManifest.xml pour la permission INTERNET (nécessaire pour Gemini).
2. La valeur minSdk recommandée pour sqflite dans android/app/build.gradle(.kts).
3. La commande de lancement avec la clé : `flutter run --dart-define=GEMINI_KEY=xxx`, et la configuration VSCode (.vscode/launch.json) correspondante en utilisant "toolArgs".
Ne touche à rien d'autre.
