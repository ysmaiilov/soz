import 'package:cloud_firestore/cloud_firestore.dart';

class SectionModel {
  const SectionModel({
    required this.id,
    required this.title,
    required this.order,
    this.totalWords = 0,
    this.masteredWords = 0,
    this.progressPercent = 0,
  });

  final String id;
  final String title;
  final int order;
  final int totalWords;
  final int masteredWords;
  final int progressPercent;

  SectionModel copyWith({
    int? totalWords,
    int? masteredWords,
    int? progressPercent,
  }) {
    return SectionModel(
      id: id,
      title: title,
      order: order,
      totalWords: totalWords ?? this.totalWords,
      masteredWords: masteredWords ?? this.masteredWords,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }

  factory SectionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return SectionModel(
      id: document.id,
      title: data['title'] as String? ?? 'Аталышы жок',
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }
}
