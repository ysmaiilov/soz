import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/word_model.dart';
import '../models/word_progress_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';

enum GameStatus {
  initial,
  loading,
  ready,
  roundCompleted,
  empty,
  error,
  completed,
}

class GameProvider extends ChangeNotifier {
  GameProvider({
    required this.hiveService,
    required this.firestoreService,
    required this.authService,
  });

  static const int maxActiveWords = 10;
  static const int masteryStreak = 5;

  final HiveService hiveService;
  final FirestoreService firestoreService;
  final AuthService authService;
  final Random _random = Random();

  GameStatus status = GameStatus.initial;
  String? errorMessage;
  String? sectionId;
  String? sectionTitle;
  WordModel? currentWord;
  WordProgressModel? currentProgress;
  String? selectedWordId;
  bool? selectedAnswerIsCorrect;
  bool isAnswerLocked = false;
  int sessionXp = 0;
  int sessionCorrectAnswers = 0;
  int sessionWrongAnswers = 0;
  int roundCorrectAnswers = 0;
  int roundWrongAnswers = 0;

  final List<WordModel> _allWords = [];
  final List<WordModel> _activePool = [];
  final Set<String> _solvedWordIds = <String>{};

  List<WordModel> get activePool => List.unmodifiable(_activePool);

  bool isDisabledDistractor(WordModel word) {
    return _isMastered(word);
  }

  bool isSolvedAnswer(WordModel word) {
    return _solvedWordIds.contains(word.id);
  }

  Future<void> startSection({
    required String sectionId,
    required String sectionTitle,
  }) async {
    _clearRuntimeState();
    this.sectionId = sectionId;
    this.sectionTitle = sectionTitle;
    status = GameStatus.loading;
    notifyListeners();

    try {
      final requestedSectionId = sectionId;
      final snapshot = await firestoreService.firestore
          .collection('words')
          .where('sectionId', isEqualTo: requestedSectionId)
          .get();

      if (this.sectionId != requestedSectionId) {
        return;
      }

      _allWords
        ..clear()
        ..addAll(
          snapshot.docs
              .map(WordModel.fromFirestore)
              .where((word) => word.sectionId == requestedSectionId)
              .where(
                (word) => word.turkish.isNotEmpty && word.kyrgyz.isNotEmpty,
              ),
        );

      if (_allWords.isEmpty) {
        status = GameStatus.empty;
        notifyListeners();
        return;
      }

      if (_isSectionCompleted()) {
        status = GameStatus.completed;
      } else {
        _rebuildActivePool();
        _pickNextWord();
        status = GameStatus.ready;
      }
      notifyListeners();
    } catch (error) {
      errorMessage = error.toString();
      status = GameStatus.error;
      notifyListeners();
    }
  }

  void loadProgress(String wordId) {
    currentProgress = hiveService.getWordProgress(wordId);
    notifyListeners();
  }

  Future<void> updateProgress(
    String wordId, {
    int? streak,
    bool? mastered,
  }) async {
    final savedProgress = hiveService.getWordProgress(wordId);
    final updatedProgress = savedProgress.copyWith(
      streak: streak,
      mastered: mastered,
    );

    await hiveService.saveWordProgress(
      wordId: updatedProgress.wordId,
      streak: updatedProgress.streak,
      mastered: updatedProgress.mastered,
    );

    currentProgress = updatedProgress;
    notifyListeners();
  }

  Future<void> resetProgress() async {
    if (_allWords.isEmpty) {
      await hiveService.clearProgress();
      currentProgress = null;
      notifyListeners();
      return;
    }

    await hiveService.resetWordProgress(_allWords.map((word) => word.id));
    _rebuildActivePool();
    _solvedWordIds.clear();
    _pickNextWord();
    status = _activePool.isEmpty ? GameStatus.empty : GameStatus.ready;
    selectedWordId = null;
    selectedAnswerIsCorrect = null;
    isAnswerLocked = false;
    sessionXp = 0;
    sessionCorrectAnswers = 0;
    sessionWrongAnswers = 0;
    roundCorrectAnswers = 0;
    roundWrongAnswers = 0;
    notifyListeners();
  }

  Future<void> selectAnswer(WordModel selectedWord) async {
    final word = currentWord;
    if (word == null || isAnswerLocked || status != GameStatus.ready) {
      return;
    }
    if (isDisabledDistractor(selectedWord) || isSolvedAnswer(selectedWord)) {
      return;
    }

    final isCorrect = selectedWord.id == word.id;
    selectedWordId = selectedWord.id;
    selectedAnswerIsCorrect = isCorrect;
    isAnswerLocked = true;
    notifyListeners();

    if (isCorrect) {
      await HapticFeedback.lightImpact();
    } else {
      await HapticFeedback.mediumImpact();
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));

    try {
      if (isCorrect) {
        await _handleCorrectAnswer(word);
      } else {
        await _handleWrongAnswer(word);
      }
    } catch (error) {
      errorMessage = error.toString();
      status = GameStatus.error;
    }

    selectedWordId = null;
    selectedAnswerIsCorrect = null;
    isAnswerLocked = false;
    notifyListeners();
  }

  Future<void> restartSection() async {
    await resetProgress();
  }

  void playAgain() {
    if (_allWords.isEmpty) {
      status = GameStatus.empty;
      notifyListeners();
      return;
    }

    if (_isSectionCompleted()) {
      status = GameStatus.completed;
      notifyListeners();
      return;
    }

    selectedWordId = null;
    selectedAnswerIsCorrect = null;
    isAnswerLocked = false;
    roundCorrectAnswers = 0;
    roundWrongAnswers = 0;
    _solvedWordIds.clear();
    _rebuildActivePool();
    _pickNextWord();
    status = GameStatus.ready;
    notifyListeners();
  }

  void resetGameState() {
    _clearRuntimeState();
    notifyListeners();
  }

  void _clearRuntimeState() {
    status = GameStatus.initial;
    errorMessage = null;
    sectionId = null;
    sectionTitle = null;
    currentWord = null;
    currentProgress = null;
    selectedWordId = null;
    selectedAnswerIsCorrect = null;
    isAnswerLocked = false;
    sessionXp = 0;
    sessionCorrectAnswers = 0;
    sessionWrongAnswers = 0;
    roundCorrectAnswers = 0;
    roundWrongAnswers = 0;
    _allWords.clear();
    _activePool.clear();
    _solvedWordIds.clear();
  }

  Future<void> _handleCorrectAnswer(WordModel word) async {
    sessionXp += 4;
    sessionCorrectAnswers += 1;
    roundCorrectAnswers += 1;
    await _updateUserStats(xpDelta: 4, correctDelta: 1, wrongDelta: 0);

    final progress = hiveService.getWordProgress(word.id);
    final nextStreak = progress.streak + 1;
    final mastered = nextStreak >= masteryStreak;

    await hiveService.saveWordProgress(
      wordId: word.id,
      streak: nextStreak,
      mastered: mastered,
    );
    currentProgress = WordProgressModel(
      wordId: word.id,
      streak: nextStreak,
      mastered: mastered,
    );

    final masteredWordIndex = mastered
        ? _activePool.indexWhere((poolWord) => poolWord.id == word.id)
        : -1;

    if (_isSectionCompleted()) {
      currentWord = null;
      status = GameStatus.completed;
      return;
    }

    if (masteredWordIndex != -1) {
      _solvedWordIds.remove(word.id);
      _replaceActivePoolSlot(masteredWordIndex);
    } else {
      _solvedWordIds.add(word.id);
    }
    _pickNextWord(previousWordId: word.id);
  }

  Future<void> _handleWrongAnswer(WordModel word) async {
    sessionXp -= 1;
    sessionWrongAnswers += 1;
    roundWrongAnswers += 1;
    await _updateUserStats(xpDelta: -1, correctDelta: 0, wrongDelta: 1);

    await hiveService.saveWordProgress(
      wordId: word.id,
      streak: 0,
      mastered: false,
    );
    currentProgress = WordProgressModel(
      wordId: word.id,
      streak: 0,
      mastered: false,
    );
  }

  Future<void> _updateUserStats({
    required int xpDelta,
    required int correctDelta,
    required int wrongDelta,
  }) async {
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      return;
    }

    await firestoreService.firestore.collection('users').doc(uid).update({
      'xp': FieldValue.increment(xpDelta),
      'correctAnswers': FieldValue.increment(correctDelta),
      'wrongAnswers': FieldValue.increment(wrongDelta),
    });
  }

  void _rebuildActivePool() {
    final nonMastered =
        _allWords.where((word) => !_isMastered(word)).toList(growable: false)
          ..shuffle(_random);

    _activePool
      ..clear()
      ..addAll(nonMastered.take(maxActiveWords));

    _solvedWordIds.clear();
    _fillActivePool();
  }

  void _fillActivePool() {
    while (_activePool.length < maxActiveWords &&
        _activePool.length < _allWords.length) {
      final replacement =
          _findReplacement(preferMastered: false) ??
          _findReplacement(preferMastered: true);
      if (replacement == null) {
        return;
      }

      _activePool.add(replacement);
    }
  }

  void _replaceActivePoolSlot(int index) {
    final replacement =
        _findReplacement(preferMastered: false, ignoredActiveIndex: index) ??
        _findReplacement(preferMastered: true, ignoredActiveIndex: index);

    if (replacement == null) {
      _activePool.removeAt(index);
      return;
    }

    _solvedWordIds.remove(_activePool[index].id);
    _activePool[index] = replacement;
  }

  WordModel? _findReplacement({
    required bool preferMastered,
    int? ignoredActiveIndex,
  }) {
    final activeIds = <String>{};
    for (var index = 0; index < _activePool.length; index++) {
      if (index == ignoredActiveIndex) {
        continue;
      }
      activeIds.add(_activePool[index].id);
    }
    final candidates =
        _allWords
            .where((word) => !activeIds.contains(word.id))
            .where((word) => _isMastered(word) == preferMastered)
            .toList(growable: false)
          ..shuffle(_random);

    return candidates.isEmpty ? null : candidates.first;
  }

  void _pickNextWord({String? previousWordId}) {
    var candidates = _availableQuestionWords();

    if (candidates.isEmpty) {
      currentWord = null;
      currentProgress = null;
      status = _isSectionCompleted()
          ? GameStatus.completed
          : GameStatus.roundCompleted;
      return;
    }

    final nextCandidates = candidates.length == 1
        ? candidates
        : candidates
              .where((word) => word.id != previousWordId)
              .toList(growable: false);
    currentWord = nextCandidates[_random.nextInt(nextCandidates.length)];
    currentProgress = hiveService.getWordProgress(currentWord!.id);
  }

  List<WordModel> _availableQuestionWords() {
    return _activePool
        .where((word) => !_isMastered(word))
        .where((word) => !_solvedWordIds.contains(word.id))
        .toList(growable: false);
  }

  bool _isMastered(WordModel word) {
    return hiveService.getWordProgress(word.id).mastered;
  }

  bool _isSectionCompleted() {
    return _allWords.isNotEmpty &&
        _allWords.every(
          (word) => hiveService.getWordProgress(word.id).mastered,
        );
  }
}
