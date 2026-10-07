import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.xp,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String username;
  final String email;
  final int xp;
  final int correctAnswers;
  final int wrongAnswers;
  final String role;
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    final createdAt = data['createdAt'];

    return UserModel(
      id: document.id,
      username: data['username'] as String? ?? 'Колдонуучу',
      email: data['email'] as String? ?? '',
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      correctAnswers: (data['correctAnswers'] as num?)?.toInt() ?? 0,
      wrongAnswers: (data['wrongAnswers'] as num?)?.toInt() ?? 0,
      role: data['role'] as String? ?? 'user',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}
