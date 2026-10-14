import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../viewmodels/services_provider.dart';
import '../viewmodels/user_viewmodel.dart';
import 'package:kanken/widgets/text_fit.dart';

/// 初回起動時のニックネーム設定画面（保護者が入力する想定）
class NicknameSetupScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const NicknameSetupScreen({required this.onComplete, Key? key}) : super(key: key);

  @override
  ConsumerState<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends ConsumerState<NicknameSetupScreen> {
  final _controller = TextEditingController();
  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'ニックネームを入力してください');
      return;
    }
    if (name.length > 20) {
      setState(() => _errorText = '20文字以内で入力してください');
      return;
    }

    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      const profileId = 'default';
      await firestoreService
          .createUser(
            User(
              uid: uid,
              profileId: profileId,
              displayName: name,
              currentLevel: 'LEVEL_10',
              streakCount: 0,
              createdAt: DateTime.now(),
            ),
          )
          .timeout(const Duration(seconds: 15));
      // currentUserProvider自体をinvalidateしても、その内部でwatchしている
      // userProvider((uid, profileId)) の家族インスタンスは別途無効化しないと
      // プロフィール作成前の古いキャッシュ(null)を返し続け、AuthGateScreenが
      // ニックネーム設定画面から遷移できず無限ローディングになる
      // (updateExamDate()と同様に両方invalidateする必要がある)。
      ref.invalidate(userProvider((uid: uid, profileId: profileId)));
      ref.invalidate(currentUserProvider);
      widget.onComplete();
    } on TimeoutException {
      setState(() {
        _isSaving = false;
        _errorText = '通信がタイムアウトしました。電波状況を確認してもう一度お試しください';
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorText = '保存に失敗しました。もう一度お試しください';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: MinHeightScroll(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('📝', style: TextStyle(fontSize: 64), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                'ようこそ！',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'アプリで使うニックネームを入力してください',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                maxLength: 20,
                decoration: InputDecoration(
                  label: const FitTitle('ニックネーム'),
                  errorText: _errorText,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _handleSubmit(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('はじめる'),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
