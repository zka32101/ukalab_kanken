import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/services_provider.dart';
import 'package:kanken/widgets/text_fit.dart';

/// ログイン方法を選ぶ画面（ゲスト or Google）
class LoginChoiceScreen extends ConsumerStatefulWidget {
  const LoginChoiceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginChoiceScreen> createState() => _LoginChoiceScreenState();
}

class _LoginChoiceScreenState extends ConsumerState<LoginChoiceScreen> {
  bool _isLoading = false;
  String? _errorText;

  Future<void> _handle(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'ログインに失敗しました。もう一度お試しください');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: MinHeightScroll(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '漢字',
                style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'うかラボ 漢字検定',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'はじめかたをえらんでください',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              if (_errorText != null) ...[
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Googleでログイン'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading
                    ? null
                    : () => _handle(() => authService.signInWithGoogle()),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text('ゲストとしてはじめる'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading
                    ? null
                    : () => _handle(() => authService.ensureSignedIn()),
              ),
              const SizedBox(height: 8),
              const Text(
                '※ ゲストで始めた場合、端末を変えるとデータが\n引き継げません。あとからGoogleと連携できます。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),

              if (_isLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }
}
