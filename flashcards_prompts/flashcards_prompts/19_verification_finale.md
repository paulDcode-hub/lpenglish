# 19 - Relecture et correction finale

## Prompt (à utiliser avec tous les fichiers ouverts dans VSCode, Copilot en mode Agent)
Relis l'ensemble du projet `lib/`. 
1. Liste et corrige les erreurs de compilation, imports manquants, types incohérents avec le schéma SQL du contexte.
2. Vérifie que la clé Gemini n'est jamais écrite en dur et que toute erreur réseau est gérée sans crash.
3. Vérifie qu'aucun rayon de coin > 4 ni aucune ombre n'est utilisé.
4. Vérifie que les 3 onglets fonctionnent sans état perdu et que la base est créée avec les données de départ au premier lancement.
5. Lance `flutter analyze` mentalement et corrige tous les warnings.
Ne refactorise pas l'architecture et n'ajoute aucune dépendance. Donne uniquement les fichiers modifiés, complets.
