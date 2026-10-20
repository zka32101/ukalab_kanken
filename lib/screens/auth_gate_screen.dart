import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firebase_provider.dart' as fb;
import '../viewmodels/user_viewmodel.dart' as vm;
import '../views/kanken_shell.dart';
import 'login_choice_screen.dart';
import 'nickname_setup_screen.dart';

/// アプリ起動時の認証ゲート
///
/// 未ログインならログイン方法選択画面（ゲスト or Google）を表示し、
/// サインイン済みで初回ならニックネーム設定画面を、設定済みなら下部5タブの Shell（ホーム／学ぶ／模擬／記録／設定）を表示する。
class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUserAsync = ref.watch(fb.currentUserProvider);

    return authUserAsync.when(
      data: (authUser) {
        if (authUser == null) {
          return const LoginChoiceScreen();
        }

        final profileAsync = ref.watch(vm.currentUserProvider);
        return profileAsync.when(
          data: (user) {
            if (user == null) {
              return NicknameSetupScreen(onComplete: () {});
            }
            return const KankenShell();
          },
          loading: () => const _LoadingScaffold(),
          error: (_, __) => const _ErrorScaffold(),
        );
      },
      loading: () => const _LoadingScaffold(),
      error: (_, __) => const _ErrorScaffold(),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('読み込みに失敗しました')),
    );
  }
}
