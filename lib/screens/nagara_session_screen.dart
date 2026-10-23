import 'dart:async';

import 'package:app_common_kit/app_common_kit.dart';
import 'package:app_common_kit/hands_free_tts.dart' show NagaraSessionView;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exam_prep_data.dart' show historyProvider;
import '../models/index.dart';
import '../providers/spaced_repetition_provider.dart';
import '../services/oshi_progress_store.dart';
import '../theme/app_theme.dart';
import '../viewmodels/index.dart';
import 'package:ukalab_core/ui.dart' show HomeMenuItem, HomeMenuTile;
import 'package:kanken/widgets/text_fit.dart';

/// 学習メニューの項目名。
const String kNagaraMenuLabel = 'ながら\n学習';

/// ホームの「ながら学習」の入口（無料。新しい権限は使わない）。
HomeMenuItem nagaraMenuItem(BuildContext context) => HomeMenuItem(
      icon: Icons.headphones,
      title: kNagaraMenuLabel.replaceAll('\n', ''),
      iconColor: AppColors.study,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NagaraSessionScreen()),
      ),
    );

/// 単独で置くとき用の 1 列版（[nagaraMenuItem] と同じ入口）。
class NagaraMenuCard extends StatelessWidget {
  const NagaraMenuCard({super.key});

  @override
  Widget build(BuildContext context) {
    final it = nagaraMenuItem(context);
    return HomeMenuTile(
        icon: it.icon, title: it.title, iconColor: it.iconColor, onTap: it.onTap);
  }
}

/// 子ども向けに、終わりの声かけをやさしい調子にする（責めない）。
final NagaraStrings kNagaraKidsStrings = NagaraStrings(
  positionLabel: NagaraStrings.ja.positionLabel,
  remainingLabel: NagaraStrings.ja.remainingLabel,
  phaseReadingQuestion: NagaraStrings.ja.phaseReadingQuestion,
  phaseWaitingAnswer: NagaraStrings.ja.phaseWaitingAnswer,
  phaseReadingAnswer: NagaraStrings.ja.phaseReadingAnswer,
  phasePausedBetween: NagaraStrings.ja.phasePausedBetween,
  phasePaused: NagaraStrings.ja.phasePaused,
  phaseFinished: NagaraStrings.ja.phaseFinished,
  pause: NagaraStrings.ja.pause,
  resume: NagaraStrings.ja.resume,
  skip: NagaraStrings.ja.skip,
  stop: NagaraStrings.ja.stop,
  close: NagaraStrings.ja.close,
  tapHint: NagaraStrings.ja.tapHint,
  speechUnavailable: NagaraStrings.ja.speechUnavailable,
  chosenLabel: NagaraStrings.ja.chosenLabel,
  correctSpoken: NagaraStrings.ja.correctSpoken,
  checkSpoken: NagaraStrings.ja.checkSpoken,
  unansweredSpoken: NagaraStrings.ja.unansweredSpoken,
  answerIsSpoken: NagaraStrings.ja.answerIsSpoken,
  explanationSpoken: NagaraStrings.ja.explanationSpoken,
  finishedSummary: NagaraStrings.ja.finishedSummary,
  restSuggestion: 'がんばったね。ひと休みしよう',
  settingsThinkSeconds: NagaraStrings.ja.settingsThinkSeconds,
  settingsBetweenSeconds: NagaraStrings.ja.settingsBetweenSeconds,
  settingsAutoAdvance: NagaraStrings.ja.settingsAutoAdvance,
  secondsOption: NagaraStrings.ja.secondsOption,
);

/// 演習の1問を、ながらセッションの1問にする。
NagaraQuestion toNagaraQuestion(PracticeQuestion q) {
  final example = q.source.example;
  final head = switch (q.actualMode) {
    PracticeMode.reading => '「${q.source.kanji}」は「${q.correctAnswer}」と読みます。',
    PracticeMode.strokeCount => '「${q.source.kanji}」の画数は${q.correctAnswer}です。',
    PracticeMode.strokeOrder => '赤い画は「${q.source.kanji}」の${q.correctAnswer}です。',
    PracticeMode.okurigana => '正しくは「${q.correctAnswer}」です。',
    PracticeMode.yoji => '空欄には「${q.correctAnswer}」が入ります。',
    PracticeMode.antonym => '「${q.prompt}」の対義語は「${q.correctAnswer}」です。',
    PracticeMode.synonym => '「${q.prompt}」の類義語は「${q.correctAnswer}」です。',
    PracticeMode.homophone => '正しくは「${q.correctAnswer}」です。',
    PracticeMode.errorCorrection => '正しくは「${q.correctAnswer}」です。',
    PracticeMode.radicalName => '「${q.source.kanji}」の部首名は「${q.correctAnswer}」です。',
    _ => '「${q.correctAnswer}」と書きます。',
  };
  return NagaraQuestion(
    id: q.source.id,
    prompt: '${q.instruction} ${q.prompt}',
    choices: q.choices,
    correctIndex: q.choices.indexOf(q.correctAnswer),
    explanation: (example != null && example.isNotEmpty) ? '$head 例、$example' : head,
  );
}

/// ながら学習でのタップ解答（正答・誤答）を、通常の解答と同じ記録（履歴→間違いノート・推しの成長・解答ログ・復習リスト）に載せる。
/// 記録に失敗しても学習は止めない。
Future<void> recordNagaraAnswer(
    WidgetRef ref, PracticeQuestion q, String level, bool correct) async {
  try {
    await ref.read(historyProvider.notifier).recordAnswer(
          questionId: q.source.id,
          level: level,
          correct: correct,
        );
  } catch (_) {}
  String profileId = 'default';
  try {
    profileId = (await ref.read(currentUserProvider.future))?.profileId ?? 'default';
  } catch (_) {}
  try {
    await OshiProgressStore.markAnswered(
      profileId: profileId,
      level: level,
      questionId: q.source.id,
    );
  } catch (_) {}
  try {
    final uid = ref.read(currentUserIdProvider);
    if (uid != null) {
      // 待つとオフラインで進まなくなるので、待たずに書く。
      unawaited(ref.read(firestoreServiceProvider).addAnswerLog(UserAnswerLog(
            id: '',
            uid: uid,
            profileId: profileId,
            questionId: q.source.id,
            isCorrect: correct,
            mode: AnswerMode.normal,
            answeredAt: DateTime.now(),
            level: level,
          )).catchError((_) {}));
    }
  } catch (_) {}
  if (correct) return;
  try {
    unawaited(addToSpacedRepetition(
      ref,
      questionId: q.source.id,
      kanji: q.source.kanji,
      category: q.actualMode.toString().split('.').last,
      question: q.instruction,
      options: q.choices,
      correctAnswer: q.correctAnswer,
    ).catchError((_) {}));
  } catch (_) {}
}

/// ながら学習。画面を点けたまま、問題と選択肢を読み、考える時間のあと答えと解説を読んで次へ進む。
/// 10問ほどで「ひと休みしよう」と声をかける。バックグラウンドや画面ロック中は読み上げない。
class NagaraSessionScreen extends ConsumerWidget {
  const NagaraSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(currentLevelProvider);
    final async = ref.watch(nagaraQuestionsProvider(level));
    return Scaffold(
      appBar: AppBar(title: const FitTitle('ながら学習')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('問題をよみこめませんでした')),
          data: (questions) {
            if (questions.isEmpty) {
              return const Center(child: Text('いまは出せる問題がありません'));
            }
            final byId = {for (final q in questions) q.source.id: q};
            return KitStringsScope(
              strings: KitStrings.of(context).copyWith(nagara: kNagaraKidsStrings),
              child: NagaraSessionView(
                questions: [for (final q in questions) toNagaraQuestion(q)],
                maxQuestions: nagaraSessionSize,
                // 正答・誤答とも onAnswered に一本化（未回答・スキップは呼ばれず、記録しない）。
                onAnswered: (nq, _, correct) {
                  final q = byId[nq.id];
                  if (q != null) unawaited(recordNagaraAnswer(ref, q, level, correct));
                },
                onClose: () => Navigator.of(context).pop(),
              ),
            );
          },
        ),
      ),
    );
  }
}
