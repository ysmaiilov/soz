import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  AuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  firebase_auth.User? get currentUser => firebaseAuth.currentUser;

  Future<firebase_auth.User?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-created',
        message: 'Колдонуучу аккаунтун түзүү мүмкүн болгон жок.',
      );
    }

    await user.updateDisplayName(username);
    await firestore.collection('users').doc(user.uid).set({
      'username': username,
      'email': email,
      'xp': 0,
      'correctAnswers': 0,
      'wrongAnswers': 0,
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return user;
  }

  Future<firebase_auth.User?> login({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return credential.user;
  }

  Future<void> logout() {
    return firebaseAuth.signOut();
  }
}
