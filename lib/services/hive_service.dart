import 'package:hive_flutter/hive_flutter.dart';

import '../models/word_progress_model.dart';

class HiveService {
  const HiveService();

  static const String wordProgressBoxName = 'word_progress';

  Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(wordProgressBoxName);
  }

  Future<void> saveWordProgress({
    required String wordId,
    required int streak,
    required bool mastered,
  }) {
    return _wordProgressBox.put(
      wordId,
      WordProgressModel(
        wordId: wordId,
        streak: streak,
        mastered: mastered,
      ).toMap(),
    );
  }

  WordProgressModel getWordProgress(String wordId) {
    final rawProgress = _wordProgressBox.get(wordId);
    if (rawProgress is Map) {
      return WordProgressModel.fromMap(rawProgress);
    }

    return WordProgressModel.empty(wordId);
  }

  List<WordProgressModel> getAllProgress() {
    return _wordProgressBox.values
        .whereType<Map>()
        .map(WordProgressModel.fromMap)
        .where((progress) => progress.wordId.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> clearProgress() {
    return _wordProgressBox.clear();
  }

  Future<void> resetWordProgress(Iterable<String> wordIds) async {
    for (final wordId in wordIds) {
      await saveWordProgress(wordId: wordId, streak: 0, mastered: false);
    }
  }

  int approximateDatabaseSizeBytes() {
    var total = 0;
    for (final key in _wordProgressBox.keys) {
      final value = _wordProgressBox.get(key);
      total += key.toString().length;
      total += value.toString().length;
    }
    return total;
  }

  Box<dynamic> get _wordProgressBox => Hive.box(wordProgressBoxName);
}
