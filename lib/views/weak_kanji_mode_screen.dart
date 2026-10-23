import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../viewmodels/index.dart';
import '../widgets/correct_feedback_widget.dart';
import 'package:kanken/widgets/text_fit.dart';
import 'package:ukalab_core/learning.dart';

/// 苦手集中モードの問題セット（ユーザーごと）。画面を閉じたら捨てて、開き直すたびに作り直す。
///
/// 以前は build() の中で `FutureProvider(...)` をその場で作って watch していた。build のたびに
/// 別のプロバイダーが新しく作られるので、読み込み中のまま止まる（画面を再描画するたびに
/// 問題の取得がやり直される）状態になっていた。
final weakKanjiFocusQuestionsProvider =
    FutureProvider.autoDispose.family<List<KanjiQuestion>, String>((ref, uid) async {
  final aiWeakService = ref.watch(aiWeakAnalysisServiceProvider);
  final user = await ref.watch(currentUserProvider.future);
  return aiWeakService.getWeakKanjiFocusQuestions(
    uid,
    limit: 20,
    profileId: user?.profileId ?? 'default',
  );
});

/// 苦手集中モード画面
class WeakKanjiModeScreen extends ConsumerWidget {
  const WeakKanjiModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const FitTitle('苦手集中トレーニング')),
        body: const Center(child: Text('ユーザーログインが必要です')),
      );
    }

    // 苦手漢字の問題セットを取得
    final weakQuestionsAsync = ref.watch(weakKanjiFocusQuestionsProvider(uid));

    return WillPopScope(
      onWillPop: () async {
        ref.read(practiceViewModelProvider.notifier).reset();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const FitTitle('苦手集中トレーニング'),
          backgroundColor: Colors.orange[300],
          leading: BackButton(
            onPressed: () {
              ref.read(practiceViewModelProvider.notifier).reset();
              Navigator.pop(context);
            },
          ),
        ),
        body: weakQuestionsAsync.when(
          data: (questions) {
            if (questions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 80, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text(
                      '苦手な漢字はありません！\nいいペースですね 🎉',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ホームに戻る'),
                    ),
                  ],
                ),
              );
            }

            final currentIndex = ref.watch(currentQuestionIndexProvider);
            if (currentIndex >= questions.length) {
              return _buildCompletionScreen(context, ref);
            }

            final question = questions[currentIndex];
            final correctCount = ref.watch(correctCountProvider);

            return _buildWeakKanjiContent(
              context,
              ref,
              question,
              currentIndex,
              questions.length,
              correctCount,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('エラー: $err')),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen(BuildContext context, WidgetRef ref) {
    // セッション(苦手集中トレーニング1回分)終了時のみ、ここで1回だけ
    // インタースティシャル表示を判定する(演習の最中には出さない方針)。
    if (!ref.read(weakKanjiSessionAdShownProvider)) {
      ref.read(weakKanjiSessionAdShownProvider.notifier).state = true;
      Future.microtask(() async {
        await AdService.gate?.maybeShowInterstitial(InterstitialTrigger.sessionEnd);
      });
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, size: 120, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            '苦手集中トレーニング完了！',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '正解数: ${ref.watch(correctCountProvider)}問',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(practiceViewModelProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: const Text('ホームに戻る'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeakKanjiContent(
    BuildContext context,
    WidgetRef ref,
    KanjiQuestion question,
    int currentIndex,
    int totalQuestions,
    int correctCount,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MinHeightScroll(
        intrinsicHeight: true,
        child: Column(
        children: [
          // 進捗バー
          LinearProgressIndicator(
            value: (currentIndex + 1) / totalQuestions,
            backgroundColor: Colors.orange[100],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[400]!),
          ),
          const SizedBox(height: 16),

          // 進捗表示
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '進捗: ${currentIndex + 1}/$totalQuestions',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '正解: $correctCount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 説明テキスト
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: const Text(
              '⚠️ この漢字は過去に間違えた漢字です。\n正確に覚えましょう！',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 24),

          // 漢字表示
          Text(
            question.kanji,
            style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // 選択肢
          if (question.questionType == QuestionType.multipleChoice)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: question.choices.map((choice) {
                  final isCorrect = choice == question.correctAnswer;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.orange[50],
                          foregroundColor: Colors.black,
                          side: BorderSide(color: Colors.orange[200]!),
                        ),
                        onPressed: () {
                          _handleAnswer(context, ref, isCorrect, question);
                        },
                        child: Text(choice),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text('手書き判定（苦手集中モード）'),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Future<void> _handleAnswer(
    BuildContext context,
    WidgetRef ref,
    bool isCorrect,
    KanjiQuestion question,
  ) async {
    final practiceVM = ref.read(practiceViewModelProvider.notifier);
    final uid = ref.read(currentUserIdProvider);
    final firestoreService = ref.read(firestoreServiceProvider);

    await practiceVM.answerQuestion(isCorrect);

    if (isCorrect) {
      await ref.read(answerFeedbackProvider).correct();

      // フィードバックウィジェットをダイアログで表示
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              child: CorrectFeedbackWidget(
                onComplete: () async {
                  Navigator.pop(dialogContext);
                  practiceVM.moveToNextQuestion();
                },
                onLearnedToggle: (isLearned) async {
                  if (isLearned && uid != null) {
                    // 学習済みとしてマーク
                    final user = await ref.read(currentUserProvider.future);
                    await firestoreService.markAsLearned(
                      uid,
                      question.id,
                      profileId: user?.profileId ?? 'default',
                    );
                    ref.invalidate(learnedKanjiIdsProvider);
                  }
                },
              ),
            );
          },
        );
      }
    } else {
      await ref.read(answerFeedbackProvider).incorrect();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('もう一度確認しましょう'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      practiceVM.moveToNextQuestion();
    }
  }
}
