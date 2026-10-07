import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.authService})
    : currentUser = authService.currentUser;

  final AuthService authService;
  firebase_auth.User? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return _runAuthAction(
      () => authService.register(
        username: username,
        email: email,
        password: password,
      ),
    );
  }

  Future<bool> login({required String email, required String password}) async {
    return _runAuthAction(
      () => authService.login(email: email, password: password),
    );
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await authService.logout();
      currentUser = null;
      errorMessage = null;
    } on firebase_auth.FirebaseAuthException catch (error) {
      errorMessage = _messageForAuthError(error);
    } catch (_) {
      errorMessage = 'Күтүлбөгөн ката кетти. Кайра аракет кылып көрүңүз.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _runAuthAction(
    Future<firebase_auth.User?> Function() action,
  ) async {
    _setLoading(true);
    try {
      currentUser = await action();
      errorMessage = null;
      return currentUser != null;
    } on firebase_auth.FirebaseAuthException catch (error) {
      errorMessage = _messageForAuthError(error);
      return false;
    } catch (_) {
      errorMessage = 'Күтүлбөгөн ката кетти. Кайра аракет кылып көрүңүз.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  String _messageForAuthError(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Бул электрондук почта мурун катталган.';
      case 'invalid-email':
        return 'Электрондук почта туура эмес жазылды.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Электрондук почта же сырсөз туура эмес.';
      case 'weak-password':
        return 'Сырсөз кеминде 6 белгиден турушу керек.';
      case 'network-request-failed':
        return 'Интернет байланышын текшериңиз.';
      default:
        return error.message ??
            'Кирүү ишке ашкан жок. Кайра аракет кылып көрүңүз.';
    }
  }
}
