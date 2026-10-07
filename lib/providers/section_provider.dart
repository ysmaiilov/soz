import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/section_model.dart';
import '../models/word_model.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';

class BulkAddWordsResult {
  const BulkAddWordsResult({
    required this.added,
    required this.skipped,
    required this.duplicates,
  });

  final int added;
  final int skipped;
  final int duplicates;
}

class DefaultDataResult {
  const DefaultDataResult({required this.created});

  final bool created;
}

class SectionProvider extends ChangeNotifier {
  SectionProvider({required this.firestoreService, required this.hiveService});

  final FirestoreService firestoreService;
  final HiveService hiveService;

  Stream<List<SectionModel>> watchSections() {
    late final StreamController<List<SectionModel>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sectionsListener;
    StreamSubscription<BoxEvent>? progressListener;
    final wordListeners =
        <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
    final wordsBySection = <String, List<WordModel>>{};
    var sections = <SectionModel>[];

    void emitSections() {
      if (controller.isClosed) {
        return;
      }

      controller.add(_sectionsWithStats(sections, wordsBySection));
    }

    void syncWordListeners() {
      final activeSectionIds = sections.map((section) => section.id).toSet();
      final removedSectionIds = wordListeners.keys
          .where((sectionId) => !activeSectionIds.contains(sectionId))
          .toList(growable: false);

      for (final sectionId in removedSectionIds) {
        wordListeners.remove(sectionId)?.cancel();
        wordsBySection.remove(sectionId);
      }

      for (final section in sections) {
        if (wordListeners.containsKey(section.id)) {
          continue;
        }

        wordsBySection[section.id] = const <WordModel>[];
        wordListeners[section.id] = firestoreService.firestore
            .collection('words')
            .where('sectionId', isEqualTo: section.id)
            .snapshots()
            .listen((snapshot) {
              wordsBySection[section.id] = snapshot.docs
                  .map(WordModel.fromFirestore)
                  .toList(growable: false);
              emitSections();
            }, onError: controller.addError);
      }
    }

    controller = StreamController<List<SectionModel>>(
      onListen: () {
        sectionsListener = firestoreService.firestore
            .collection('sections')
            .orderBy('order')
            .snapshots()
            .listen((snapshot) {
              sections = snapshot.docs
                  .map(SectionModel.fromFirestore)
                  .toList(growable: false);
              syncWordListeners();
              emitSections();
            }, onError: controller.addError);

        progressListener = Hive.box<dynamic>(
          HiveService.wordProgressBoxName,
        ).watch().listen((_) => emitSections(), onError: controller.addError);
      },
      onCancel: () async {
        await sectionsListener?.cancel();
        await progressListener?.cancel();
        for (final listener in wordListeners.values) {
          await listener.cancel();
        }
      },
    );

    return controller.stream;
  }

  List<SectionModel> _sectionsWithStats(
    List<SectionModel> sections,
    Map<String, List<WordModel>> wordsBySection,
  ) {
    return sections
        .map((section) {
          final words = wordsBySection[section.id] ?? const <WordModel>[];
          final totalWords = words.length;
          final masteredWords = words
              .where((word) => hiveService.getWordProgress(word.id).mastered)
              .length;
          final progressPercent = totalWords == 0
              ? 0
              : ((masteredWords / totalWords) * 100).round();

          return section.copyWith(
            totalWords: totalWords,
            masteredWords: masteredWords,
            progressPercent: progressPercent,
          );
        })
        .toList(growable: false);
  }

  Future<void> createSection({required String title, required int order}) {
    return firestoreService.firestore.collection('sections').add({
      'title': title,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSection({
    required String sectionId,
    required String title,
    required int order,
  }) {
    return firestoreService.firestore
        .collection('sections')
        .doc(sectionId)
        .update({'title': title, 'order': order});
  }

  Future<void> deleteSection(String sectionId) {
    return firestoreService.firestore
        .collection('sections')
        .doc(sectionId)
        .delete();
  }

  Stream<List<WordModel>> watchWordsForSection(String sectionId) {
    return firestoreService.firestore
        .collection('words')
        .where('sectionId', isEqualTo: sectionId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(WordModel.fromFirestore).toList(growable: false)
                ..sort(
                  (first, second) => first.turkish.toLowerCase().compareTo(
                    second.turkish.toLowerCase(),
                  ),
                ),
        );
  }

  Future<bool> wordTurkishExists({
    required String sectionId,
    required String turkish,
    String? excludingWordId,
  }) async {
    final normalizedTurkish = turkish.trim().toLowerCase();
    final snapshot = await firestoreService.firestore
        .collection('words')
        .where('sectionId', isEqualTo: sectionId)
        .get();

    return snapshot.docs.any((document) {
      if (document.id == excludingWordId) {
        return false;
      }

      final data = document.data();
      final existingTurkish = (data['turkish'] as String? ?? '')
          .trim()
          .toLowerCase();
      return existingTurkish == normalizedTurkish;
    });
  }

  Future<void> updateWord({
    required String wordId,
    required String turkish,
    required String kyrgyz,
  }) {
    return firestoreService.firestore.collection('words').doc(wordId).update({
      'turkish': turkish,
      'kyrgyz': kyrgyz,
    });
  }

  Future<void> deleteWord(String wordId) {
    return firestoreService.firestore.collection('words').doc(wordId).delete();
  }

  Future<BulkAddWordsResult> bulkAddWords({
    required String sectionId,
    required String input,
  }) async {
    final lines = input.split('\n');
    final validPairs = <({String turkish, String kyrgyz})>[];
    final existingTurkish = await _existingTurkishForSection(sectionId);
    var skipped = 0;
    var duplicates = 0;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      final separatorIndex = line.indexOf('=');
      if (separatorIndex == -1) {
        skipped++;
        continue;
      }

      final turkish = line.substring(0, separatorIndex).trim();
      final kyrgyz = line.substring(separatorIndex + 1).trim();
      if (turkish.isEmpty || kyrgyz.isEmpty) {
        skipped++;
        continue;
      }

      final normalizedTurkish = turkish.toLowerCase();
      if (existingTurkish.contains(normalizedTurkish)) {
        duplicates++;
        continue;
      }

      existingTurkish.add(normalizedTurkish);
      validPairs.add((turkish: turkish, kyrgyz: kyrgyz));
    }

    if (validPairs.isEmpty) {
      return BulkAddWordsResult(
        added: 0,
        skipped: skipped,
        duplicates: duplicates,
      );
    }

    final firestore = firestoreService.firestore;
    final wordsCollection = firestore.collection('words');

    for (var start = 0; start < validPairs.length; start += 500) {
      final end = (start + 500).clamp(0, validPairs.length);
      final batch = firestore.batch();

      for (final pair in validPairs.sublist(start, end)) {
        final document = wordsCollection.doc();
        batch.set(document, {
          'sectionId': sectionId,
          'turkish': pair.turkish,
          'kyrgyz': pair.kyrgyz,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }

    return BulkAddWordsResult(
      added: validPairs.length,
      skipped: skipped,
      duplicates: duplicates,
    );
  }

  Future<DefaultDataResult> createDefaultDataIfEmpty() async {
    final firestore = firestoreService.firestore;
    final existingSections = await firestore
        .collection('sections')
        .limit(1)
        .get();
    final existingWords = await firestore.collection('words').limit(1).get();
    if (existingSections.docs.isNotEmpty || existingWords.docs.isNotEmpty) {
      return const DefaultDataResult(created: false);
    }

    final batch = firestore.batch();
    final sections = _defaultSections();

    for (final section in sections) {
      final sectionDocument = firestore.collection('sections').doc();
      batch.set(sectionDocument, {
        'title': section.title,
        'order': section.order,
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (final word in section.words) {
        final wordDocument = firestore.collection('words').doc();
        batch.set(wordDocument, {
          'sectionId': sectionDocument.id,
          'turkish': word.turkish,
          'kyrgyz': word.kyrgyz,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
    return const DefaultDataResult(created: true);
  }

  Future<Set<String>> _existingTurkishForSection(String sectionId) async {
    final snapshot = await firestoreService.firestore
        .collection('words')
        .where('sectionId', isEqualTo: sectionId)
        .get();

    return snapshot.docs
        .map((document) => (document.data()['turkish'] as String? ?? '').trim())
        .where((turkish) => turkish.isNotEmpty)
        .map((turkish) => turkish.toLowerCase())
        .toSet();
  }
}

class _DefaultSection {
  const _DefaultSection({
    required this.title,
    required this.order,
    required this.words,
  });

  final String title;
  final int order;
  final List<_DefaultWord> words;
}

class _DefaultWord {
  const _DefaultWord({required this.turkish, required this.kyrgyz});

  final String turkish;
  final String kyrgyz;
}

List<_DefaultSection> _defaultSections() {
  return const [
    _DefaultSection(
      title: 'Негиздер',
      order: 1,
      words: [
        _DefaultWord(turkish: 'merhaba', kyrgyz: 'салам'),
        _DefaultWord(turkish: 'evet', kyrgyz: 'ооба'),
        _DefaultWord(turkish: 'hayır', kyrgyz: 'жок'),
        _DefaultWord(turkish: 'lütfen', kyrgyz: 'суранам'),
        _DefaultWord(turkish: 'teşekkürler', kyrgyz: 'рахмат'),
        _DefaultWord(turkish: 'su', kyrgyz: 'суу'),
        _DefaultWord(turkish: 'ev', kyrgyz: 'үй'),
        _DefaultWord(turkish: 'okul', kyrgyz: 'мектеп'),
        _DefaultWord(turkish: 'kitap', kyrgyz: 'китеп'),
        _DefaultWord(turkish: 'iyi', kyrgyz: 'жакшы'),
      ],
    ),
    _DefaultSection(
      title: 'Үй-бүлө',
      order: 2,
      words: [
        _DefaultWord(turkish: 'anne', kyrgyz: 'апа'),
        _DefaultWord(turkish: 'baba', kyrgyz: 'ата'),
        _DefaultWord(turkish: 'kardeş', kyrgyz: 'бир тууган'),
        _DefaultWord(turkish: 'abla', kyrgyz: 'эже'),
        _DefaultWord(turkish: 'ağabey', kyrgyz: 'ага'),
        _DefaultWord(turkish: 'çocuk', kyrgyz: 'бала'),
        _DefaultWord(turkish: 'aile', kyrgyz: 'үй-бүлө'),
        _DefaultWord(turkish: 'dede', kyrgyz: 'чоң ата'),
        _DefaultWord(turkish: 'nine', kyrgyz: 'чоң эне'),
        _DefaultWord(turkish: 'kız', kyrgyz: 'кыз'),
      ],
    ),
    _DefaultSection(
      title: 'Тамак-аш',
      order: 3,
      words: [
        _DefaultWord(turkish: 'ekmek', kyrgyz: 'нан'),
        _DefaultWord(turkish: 'yemek', kyrgyz: 'тамак'),
        _DefaultWord(turkish: 'çay', kyrgyz: 'чай'),
        _DefaultWord(turkish: 'süt', kyrgyz: 'сүт'),
        _DefaultWord(turkish: 'elma', kyrgyz: 'алма'),
        _DefaultWord(turkish: 'et', kyrgyz: 'эт'),
        _DefaultWord(turkish: 'balık', kyrgyz: 'балык'),
        _DefaultWord(turkish: 'peynir', kyrgyz: 'сыр'),
        _DefaultWord(turkish: 'çorba', kyrgyz: 'шорпо'),
        _DefaultWord(turkish: 'tuz', kyrgyz: 'туз'),
      ],
    ),
  ];
}
