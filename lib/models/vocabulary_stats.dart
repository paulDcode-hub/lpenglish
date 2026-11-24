class VocabularyStats {
  const VocabularyStats({
    required this.flashcardXp,
    required this.reviewCount,
    required this.correctCount,
    required this.reviewedWordCount,
    required this.totalWordCount,
  });

  final int flashcardXp;
  final int reviewCount;
  final int correctCount;
  final int reviewedWordCount;
  final int totalWordCount;

  double get accuracy =>
      reviewCount == 0 ? 0 : correctCount * 100 / reviewCount;

  double get vocabularyCoverage =>
      totalWordCount == 0 ? 0 : reviewedWordCount * 100 / totalWordCount;
}

class FlashcardPerformance {
  const FlashcardPerformance({
    required this.id,
    required this.en,
    required this.fr,
    required this.reviewCount,
    required this.correctCount,
  });

  final int id;
  final String en;
  final String fr;
  final int reviewCount;
  final int correctCount;

  double get accuracy =>
      reviewCount == 0 ? 0 : correctCount * 100 / reviewCount;

  factory FlashcardPerformance.fromMap(Map<String, Object?> map) =>
      FlashcardPerformance(
        id: map['id'] as int,
        en: map['en'] as String,
        fr: map['fr'] as String,
        reviewCount: (map['review_count'] as num).toInt(),
        correctCount: (map['correct_count'] as num).toInt(),
      );
}
