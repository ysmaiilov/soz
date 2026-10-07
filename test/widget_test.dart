import 'package:flutter_test/flutter_test.dart';

import 'package:soz/models/user_model.dart';

void main() {
  test('UserModel stores user profile values', () {
    const user = UserModel(
      id: 'uid-1',
      username: 'test_user',
      email: 'user@example.com',
      xp: 25,
      correctAnswers: 3,
      wrongAnswers: 1,
      role: 'user',
    );

    expect(user.id, 'uid-1');
    expect(user.username, 'test_user');
    expect(user.email, 'user@example.com');
    expect(user.xp, 25);
    expect(user.isAdmin, isFalse);
  });
}
