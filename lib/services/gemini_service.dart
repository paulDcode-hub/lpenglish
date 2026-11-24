import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class GeminiService {
  static const String _key = String.fromEnvironment('GEMINI_KEY');
  // TODO: vérifier le nom du modèle actuel.
  static const String _model = 'gemini-2.5-flash';
  static const String _url = 
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  static const List<String> _themes = [
    'Temps',
    'Modaux',
    'Comparatifs',
    'Articles',
    'Prépositions',
  ];

  static Future<Map<String, dynamic>> _generateJson(String prompt) async {
    if (_key.isEmpty) {
      throw Exception(
        'Clé Gemini absente. Lancez l’application avec --dart-define=GEMINI_KEY=... .',
      );
    }

    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _key,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'responseMimeType': 'application/json',
                'temperature': 0.7,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw Exception('La requête Gemini a dépassé le délai de 30 secondes.');
    } on http.ClientException catch (error) {
      throw Exception(
        'Erreur réseau lors de l’appel à Gemini : ${error.message}',
      );
    } on IOException catch (error) {
      throw Exception('Erreur réseau lors de l’appel à Gemini : $error');
    } catch (error) {
      throw Exception('Impossible de contacter Gemini : $error');
    }

    if (response.statusCode != 200) {
      final details = _apiErrorMessage(response.body);
      final suffix = details.isEmpty ? '' : ' : $details';
      throw Exception(
        'Gemini a répondu avec le statut ${response.statusCode}$suffix',
      );
    }

    try {
      final responseJson = jsonDecode(response.body);
      if (responseJson is! Map) {
        throw const FormatException('La réponse HTTP n’est pas un objet JSON.');
      }
      final candidates = responseJson['candidates'];
      if (candidates is! List ||
          candidates.isEmpty ||
          candidates.first is! Map) {
        throw const FormatException('La réponse ne contient aucun candidat.');
      }
      final content = candidates.first['content'];
      if (content is! Map) {
        throw const FormatException('Le contenu généré est absent.');
      }
      final parts = content['parts'];
      if (parts is! List || parts.isEmpty || parts.first is! Map) {
        throw const FormatException('Le texte généré est absent.');
      }
      final text = parts.first['text'];
      if (text is! String || text.isEmpty) {
        throw const FormatException('Le texte généré est vide.');
      }

      final generatedJson = jsonDecode(text);
      if (generatedJson is! Map) {
        throw const FormatException(
          'Le contenu généré n’est pas un objet JSON.',
        );
      }
      return Map<String, dynamic>.from(generatedJson);
    } on FormatException catch (error) {
      throw Exception('Réponse JSON invalide de Gemini : ${error.message}');
    }
  }

  static String _apiErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final message = decoded['error']['message'];
        if (message is String) return message;
      }
    } on FormatException {
      return '';
    }
    return '';
  }

  static Future<List<GrammarExercise>> generateGrammarExercises({
    String? theme,
    List<String> weakThemes = const [],
  }) async {
    if (theme != null && !_themes.contains(theme)) {
      throw Exception('Thème de grammaire inconnu : $theme.');
    }

    final selectedWeakThemes = theme == null
        ? weakThemes.where(_themes.contains).toSet().toList()
        : <String>[];
    final themeInstruction = theme == null
        ? 'Répartis les exercices entre les thèmes autorisés.'
        : 'Les dix exercices doivent tous porter sur le thème ${jsonEncode(theme)}.';
    final weakInstruction = selectedWeakThemes.isEmpty
        ? ''
        : 'Insiste en priorité sur ces thèmes faibles : ${selectedWeakThemes.join(', ')}.';
    final prompt =
        '''
Tu es un professeur d’anglais. Génère exactement 10 exercices à trous de niveau A2-B1.
Chaque phrase doit contenir un seul trou écrit exactement "___". La réponse doit faire de 1 à 3 mots.
Les thèmes autorisés sont : Temps, Modaux, Comparatifs, Articles, Prépositions.
$themeInstruction
$weakInstruction
Retourne uniquement un JSON strict conforme à cette structure, avec les 10 exercices :
{"exercises":[{"sentence":"She ___ to school every day.","answer":"goes","accepted":["goes"],"theme":"Temps","explanation":"Présent simple, 3e personne : +s."}]}
Chaque objet doit contenir sentence, answer, accepted (liste de réponses acceptées), theme et explanation en français.
''';

    final result = await _generateJson(prompt);
    final rawExercises = result['exercises'];
    if (rawExercises is! List || rawExercises.length != 10) {
      throw Exception('Gemini doit retourner exactement 10 exercices.');
    }

    try {
      return rawExercises.map((raw) {
        if (raw is! Map) {
          throw const FormatException('Un exercice n’est pas un objet JSON.');
        }
        final exercise = GrammarExercise.fromJson(
          Map<String, dynamic>.from(raw),
        );
        final holeCount = exercise.sentence.split('___').length - 1;
        final answerWords = exercise.answer.trim().split(RegExp(r'\s+'));
        if (holeCount != 1 ||
            answerWords.isEmpty ||
            answerWords.length > 3 ||
            answerWords.first.isEmpty) {
          throw const FormatException(
            'Une phrase doit avoir un seul trou et une réponse de 1 à 3 mots.',
          );
        }
        if (!_themes.contains(exercise.theme) ||
            (theme != null && exercise.theme != theme)) {
          throw const FormatException('Un exercice utilise un thème invalide.');
        }
        return exercise;
      }).toList();
    } on FormatException catch (error) {
      throw Exception('Exercices Gemini invalides : ${error.message}');
    }
  }

  static Future<Map<String, dynamic>> optimizeSrs({
    required Map<String, double> params,
    required List<Map<String, dynamic>> wordStats,
    required Map<String, double> themeAccuracy,
  }) async {
    const statKeys = ['id', 'en', 'reps', 'lapses', 'ease', 'interval'];
    final compactStats = wordStats
        .map(
          (word) => {
            for (final key in statKeys)
              if (word.containsKey(key)) key: word[key],
          },
        )
        .toList();
    final prompt =
        '''
Tu es un spécialiste de la répétition espacée. Analyse les paramètres, les statistiques des mots et la précision par thème fournis ci-dessous.
Paramètres actuels : ${jsonEncode(params)}
Statistiques des mots (id, en, reps, lapses, ease, interval) : ${jsonEncode(compactStats)}
Précision par thème en pourcentage : ${jsonEncode(themeAccuracy)}
Si la précision globale dépasse 85 %, augmente modérément interval_modifier. Si elle est inférieure à 65 %, baisse-le. Garde interval_modifier entre 0.6 et 1.6 et lapse_penalty entre 0.1 et 0.4.
Choisis au maximum 15 priority_word_ids parmi les identifiants fournis, en privilégiant les mots avec beaucoup d’erreurs ou de lapses. Indique les thèmes faibles dans weak_themes.
Retourne uniquement un JSON strict de cette forme :
{"interval_modifier":1.1,"lapse_penalty":0.2,"priority_word_ids":[3,8],"weak_themes":["Temps"],"comment":"Explication courte"}
''';

    return _generateJson(prompt);
  }
}

class GrammarExercise {
  const GrammarExercise({
    required this.sentence,
    required this.answer,
    required this.accepted,
    required this.theme,
    required this.explanation,
  });

  final String sentence;
  final String answer;
  final List<String> accepted;
  final String theme;
  final String explanation;

  factory GrammarExercise.fromJson(Map<String, dynamic> json) {
    final accepted = json['accepted'];
    if (json['sentence'] is! String ||
        json['answer'] is! String ||
        accepted is! List ||
        accepted.isEmpty ||
        accepted.any((value) => value is! String) ||
        json['theme'] is! String ||
        json['explanation'] is! String) {
      throw const FormatException('Champs d’exercice manquants ou invalides.');
    }

    return GrammarExercise(
      sentence: json['sentence'] as String,
      answer: json['answer'] as String,
      accepted: accepted.cast<String>().toList(growable: false),
      theme: json['theme'] as String,
      explanation: json['explanation'] as String,
    );
  }
}
