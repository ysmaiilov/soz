import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({required this.firestoreService});

  final FirestoreService firestoreService;

  Stream<UserModel?> watchCurrentUser(String uid) {
    return firestoreService.firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return null;
          }

          return UserModel.fromFirestore(snapshot);
        });
  }

  Stream<List<UserModel>> watchLeaderboard() {
    return firestoreService.firestore
        .collection('users')
        .orderBy('xp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(UserModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> resetUserStatistics(String uid) {
    return firestoreService.firestore.collection('users').doc(uid).update({
      'xp': 0,
      'correctAnswers': 0,
      'wrongAnswers': 0,
    });
  }
}
