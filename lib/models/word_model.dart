import 'package:cloud_firestore/cloud_firestore.dart';

class WordModel {
  const WordModel({
    required this.id,
    required this.sectionId,
    required this.turkish,
    required this.kyrgyz,
  });

  final String id;
  final String sectionId;
  final String turkish;
  final String kyrgyz;

  factory WordModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return WordModel(
      id: document.id,
      sectionId: data['sectionId'] as String? ?? '',
      turkish: data['turkish'] as String? ?? '',
      kyrgyz: data['kyrgyz'] as String? ?? '',
    );
  }
}
