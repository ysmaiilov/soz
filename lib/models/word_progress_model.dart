class WordProgressModel {
  const WordProgressModel({
    required this.wordId,
    required this.streak,
    required this.mastered,
  });

  final String wordId;
  final int streak;
  final bool mastered;

  factory WordProgressModel.empty(String wordId) {
    return WordProgressModel(wordId: wordId, streak: 0, mastered: false);
  }

  factory WordProgressModel.fromMap(Map<dynamic, dynamic> map) {
    final wordId = map['wordId'] as String? ?? '';

    return WordProgressModel(
      wordId: wordId,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      mastered: map['mastered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'wordId': wordId, 'streak': streak, 'mastered': mastered};
  }

  WordProgressModel copyWith({int? streak, bool? mastered}) {
    return WordProgressModel(
      wordId: wordId,
      streak: streak ?? this.streak,
      mastered: mastered ?? this.mastered,
    );
  }
}
