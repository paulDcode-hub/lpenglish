import 'package:sqflite/sqflite.dart';

const List<Map<String, String>> _wordSeeds = [
  {'en': 'wake up', 'fr': 'se réveiller', 'theme': 'Quotidien'},
  {'en': 'get dressed', 'fr': "s'habiller", 'theme': 'Quotidien'},
  {
    'en': 'have breakfast',
    'fr': 'prendre le petit-déjeuner',
    'theme': 'Quotidien',
  },
  {'en': 'leave home', 'fr': 'quitter la maison', 'theme': 'Quotidien'},
  {'en': 'arrive', 'fr': 'arriver', 'theme': 'Quotidien'},
  {'en': 'chores', 'fr': 'tâches ménagères', 'theme': 'Quotidien'},
  {'en': 'clean', 'fr': 'nettoyer', 'theme': 'Quotidien'},
  {'en': 'tidy', 'fr': 'ranger', 'theme': 'Quotidien'},
  {'en': 'appointment', 'fr': 'rendez-vous', 'theme': 'Quotidien'},
  {'en': 'neighbourhood', 'fr': 'quartier', 'theme': 'Quotidien'},
  {'en': 'colleague', 'fr': 'collègue', 'theme': 'Travail'},
  {'en': 'meeting', 'fr': 'réunion', 'theme': 'Travail'},
  {'en': 'deadline', 'fr': 'date limite', 'theme': 'Travail'},
  {'en': 'task', 'fr': 'tâche', 'theme': 'Travail'},
  {'en': 'report', 'fr': 'rapport', 'theme': 'Travail'},
  {'en': 'customer', 'fr': 'client', 'theme': 'Travail'},
  {'en': 'salary', 'fr': 'salaire', 'theme': 'Travail'},
  {'en': 'interview', 'fr': 'entretien', 'theme': 'Travail'},
  {'en': 'shift', 'fr': 'poste de travail', 'theme': 'Travail'},
  {'en': 'improve', 'fr': 'améliorer', 'theme': 'Travail'},
  {'en': 'ticket', 'fr': 'billet', 'theme': 'Voyage'},
  {'en': 'luggage', 'fr': 'bagages', 'theme': 'Voyage'},
  {'en': 'passport', 'fr': 'passeport', 'theme': 'Voyage'},
  {'en': 'departure', 'fr': 'départ', 'theme': 'Voyage'},
  {'en': 'arrival', 'fr': 'arrivée', 'theme': 'Voyage'},
  {'en': 'platform', 'fr': 'quai', 'theme': 'Voyage'},
  {'en': 'accommodation', 'fr': 'hébergement', 'theme': 'Voyage'},
  {'en': 'reservation', 'fr': 'réservation', 'theme': 'Voyage'},
  {'en': 'map', 'fr': 'carte', 'theme': 'Voyage'},
  {'en': 'journey', 'fr': 'trajet', 'theme': 'Voyage'},
  {'en': 'meal', 'fr': 'repas', 'theme': 'Nourriture'},
  {'en': 'ingredient', 'fr': 'ingrédient', 'theme': 'Nourriture'},
  {'en': 'recipe', 'fr': 'recette', 'theme': 'Nourriture'},
  {'en': 'snack', 'fr': 'encas', 'theme': 'Nourriture'},
  {'en': 'spicy', 'fr': 'épicé', 'theme': 'Nourriture'},
  {'en': 'fresh', 'fr': 'frais', 'theme': 'Nourriture'},
  {'en': 'hungry', 'fr': 'avoir faim', 'theme': 'Nourriture'},
  {'en': 'boil', 'fr': 'faire bouillir', 'theme': 'Nourriture'},
  {'en': 'bake', 'fr': 'cuire au four', 'theme': 'Nourriture'},
  {'en': 'order', 'fr': 'commander', 'theme': 'Nourriture'},
  {'en': 'worried', 'fr': 'inquiet', 'theme': 'Émotions'},
  {'en': 'proud', 'fr': 'fier', 'theme': 'Émotions'},
  {'en': 'disappointed', 'fr': 'déçu', 'theme': 'Émotions'},
  {'en': 'excited', 'fr': 'enthousiaste', 'theme': 'Émotions'},
  {'en': 'calm', 'fr': 'calme', 'theme': 'Émotions'},
  {'en': 'nervous', 'fr': 'nerveux', 'theme': 'Émotions'},
  {'en': 'lonely', 'fr': 'seul', 'theme': 'Émotions'},
  {'en': 'confident', 'fr': 'confiant', 'theme': 'Émotions'},
  {'en': 'surprised', 'fr': 'surpris', 'theme': 'Émotions'},
  {'en': 'relieved', 'fr': 'soulagé', 'theme': 'Émotions'},
  {'en': 'choose', 'fr': 'choisir', 'theme': 'Verbes courants'},
  {'en': 'forget', 'fr': 'oublier', 'theme': 'Verbes courants'},
  {'en': 'remember', 'fr': 'se souvenir', 'theme': 'Verbes courants'},
  {'en': 'decide', 'fr': 'décider', 'theme': 'Verbes courants'},
  {'en': 'explain', 'fr': 'expliquer', 'theme': 'Verbes courants'},
  {'en': 'happen', 'fr': 'arriver, se produire', 'theme': 'Verbes courants'},
  {
    'en': 'spend',
    'fr': 'dépenser, passer du temps',
    'theme': 'Verbes courants',
  },
  {'en': 'save', 'fr': 'économiser, sauvegarder', 'theme': 'Verbes courants'},
  {'en': 'reach', 'fr': 'atteindre', 'theme': 'Verbes courants'},
  {'en': 'avoid', 'fr': 'éviter', 'theme': 'Verbes courants'},
];

const List<Map<String, String>> _ruleSeeds = [
  {
    'title': 'Present simple et present continuous',
    'theme': 'Temps',
    'explanation': 'Le present simple décrit une habitude ou un fait. Le present continuous décrit une action en cours.',
    'examples': 'I work from home every Friday - Je travaille chez moi chaque vendredi.\nShe is talking on the phone now - Elle parle au téléphone en ce moment.\nWe usually eat at six, but today we are eating at seven - Nous mangeons d’habitude à six heures, mais aujourd’hui à sept heures.',
  },
  {
    'title': 'Past simple',
    'theme': 'Temps',
    'explanation': 'Le past simple exprime une action terminée dans le passé, souvent avec une date ou un moment précis.',
    'examples': 'I visited my aunt yesterday - J’ai rendu visite à ma tante hier.\nThey didn’t watch the match - Ils n’ont pas regardé le match.\nDid you call Sam last night? - As-tu appelé Sam hier soir ?',
  },
  {
    'title': 'Present perfect',
    'theme': 'Temps',
    'explanation': 'Le present perfect relie une expérience ou une action passée à la situation présente.',
    'examples': 'I have lost my keys - J’ai perdu mes clés.\nShe has lived here for three years - Elle habite ici depuis trois ans.\nHave you ever tried sushi? - As-tu déjà goûté des sushis ?',
  },
  {
    'title': 'Futur avec will',
    'theme': 'Temps',
    'explanation': 'Will sert notamment aux décisions spontanées, aux promesses et aux prédictions.',
    'examples': 'I’ll help you with those bags - Je vais t’aider avec ces sacs.\nI think it will rain later - Je pense qu’il pleuvra plus tard.\nWill you open the window, please? - Pourrais-tu ouvrir la fenêtre, s’il te plaît ?',
  },
  {
    'title': 'Futur avec going to',
    'theme': 'Temps',
    'explanation': 'Going to exprime un projet déjà décidé ou une prédiction fondée sur un indice présent.',
    'examples': 'We are going to visit Rome - Nous allons visiter Rome.\nLook at those clouds: it is going to rain - Regarde ces nuages : il va pleuvoir.\nHe isn’t going to buy a car this year - Il ne va pas acheter de voiture cette année.',
  },
  {
    'title': 'Conditionnels de type 1 et 2',
    'theme': 'Temps',
    'explanation': 'Le type 1 décrit une possibilité réelle (if + présent, will). Le type 2 décrit une situation imaginaire (if + past simple, would).',
    'examples': 'If it rains, we will stay at home - S’il pleut, nous resterons à la maison.\nIf she studied more, she would pass the exam - Si elle étudiait davantage, elle réussirait l’examen.\nWhat would you do if you won the lottery? - Que ferais-tu si tu gagnais à la loterie ?',
  },
  {
    'title': 'Can et could',
    'theme': 'Modaux',
    'explanation': 'Can exprime une capacité ou une demande simple. Could exprime souvent une capacité passée ou une demande plus polie.',
    'examples': 'I can swim - Je sais nager.\nCould you help me, please? - Pourrais-tu m’aider, s’il te plaît ?\nWhen I was five, I could read - À cinq ans, je savais lire.',
  },
  {
    'title': 'Must et should',
    'theme': 'Modaux',
    'explanation': 'Must exprime une obligation forte ou une interdiction avec mustn’t. Should sert à donner un conseil.',
    'examples': 'You must wear a seat belt - Tu dois porter une ceinture de sécurité.\nYou should see a doctor - Tu devrais consulter un médecin.\nYou mustn’t touch this wire - Tu ne dois pas toucher ce fil.',
  },
  {
    'title': 'Comparatif',
    'theme': 'Comparatifs',
    'explanation': 'Le comparatif oppose deux éléments : adjectif en -er ou more + adjectif, suivi de than.',
    'examples': 'This bag is lighter than mine - Ce sac est plus léger que le mien.\nThe train is faster than the bus - Le train est plus rapide que le bus.\nToday is more humid than yesterday - Aujourd’hui, il fait plus humide qu’hier.',
  },
  {
    'title': 'Superlatif',
    'theme': 'Comparatifs',
    'explanation': 'Le superlatif désigne le degré le plus élevé : the + adjectif en -est ou the most + adjectif.',
    'examples': 'Mount Everest is the highest mountain in the world - Le mont Everest est la plus haute montagne du monde.\nThis is the most expensive restaurant in town - C’est le restaurant le plus cher de la ville.\nShe is the best player on the team - C’est la meilleure joueuse de l’équipe.',
  },
  {
    'title': 'A, an et the',
    'theme': 'Articles',
    'explanation': 'A et an introduisent un nom singulier non spécifique. The désigne quelque chose de connu ou précis.',
    'examples': 'I saw a dog in the park - J’ai vu un chien dans le parc.\nShe ate an apple - Elle a mangé une pomme.\nThe sun is bright today - Le soleil brille aujourd’hui.',
  },
  {
    'title': 'In, on et at',
    'theme': 'Prépositions',
    'explanation': 'In s’emploie pour un espace ou une période, on pour une surface ou un jour, et at pour un point précis.',
    'examples': 'The keys are in my bag - Les clés sont dans mon sac.\nThe meeting is on Monday - La réunion est lundi.\nWe arrived at the station at noon - Nous sommes arrivés à la gare à midi.',
  },
];

class Seed {
  static Future<void> insertAll(Database db) async {
    final now = DateTime.now().toIso8601String();

    final batch = db.batch();
    for (final word in _wordSeeds) {
      batch.insert('words', {
        'en': word['en']!,
        'fr': word['fr']!,
        'theme': word['theme']!,
        'ease': 2.5,
        'interval': 0,
        'reps': 0,
        'lapses': 0,
        'due': now,
        'created': now,
      });
    }
    for (final rule in _ruleSeeds) {
      batch.insert('rules', {
        'title': rule['title']!,
        'theme': rule['theme']!,
        'explanation': rule['explanation']!,
        'examples': rule['examples']!,
      });
    }
    await batch.commit(noResult: true);
  }
}
