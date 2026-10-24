import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/screens/login_choice_screen.dart';

void main() {
  test('通信できないときは、つなぎ直すよう案内する', () {
    final msg = loginErrorMessage(FirebaseAuthException(code: 'network-request-failed'));
    expect(msg, contains('ネットワーク'));
  });

  test('それ以外の失敗は、これまでの文言', () {
    expect(loginErrorMessage(FirebaseAuthException(code: 'internal-error')),
        'ログインに失敗しました。もう一度お試しください');
    expect(loginErrorMessage(StateError('x')), 'ログインに失敗しました。もう一度お試しください');
  });
}
