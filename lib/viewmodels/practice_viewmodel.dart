import 'dart:async';
import 'dart:math';
import 'package:ukalab_core/ui.dart' show CoinEvent, coinProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/compound_structure_data.dart';
import '../data/exam_prep_data.dart' show historyProvider;
import '../data/level_kanji_data.dart';
import '../data/kanji_radical_data.dart';
import '../models/index.dart';
import '../providers/learning_goal_provider.dart';
import '../providers/spaced_repetition_provider.dart';
import '../providers/level_progress_provider.dart';
import '../services/oshi_progress_store.dart';
import 'services_provider.dart';
import 'user_viewmodel.dart';

// 1回の演習セッションの問題数（達成感を出すため小さく区切る）
const int practiceSessionSize = 10;

/// 漢検の出題形式に合わせた演習モード
/// - reading: 漢字を見て読み方を答える（読みがな）
/// - writing: 読み方を見て漢字を答える（書き取り）
/// - radical: 漢字を見て部首を答える（9級以上で出題）
/// - compoundStructure: 二字熟語の構成（似た意味／対の意味／修飾／目的語）を答える（8級以下で出題）
/// - mixed: 問題ごとにその級で出題可能な形式からランダムに出題
enum PracticeMode { reading, writing, radical, compoundStructure, mixed }

/// 級ごとに実際の漢検で出題される形式に合わせた、選択可能な出題形式一覧
/// （mixedを除く）。10級は読み/書き取りのみ、9級から部首が加わり、
/// 8級以下では熟語の構成も加わる。
List<PracticeMode> availableModesForLevel(String level) {
  switch (level) {
    case 'LEVEL_10':
      return const [PracticeMode.reading, PracticeMode.writing];
    case 'LEVEL_9':
      return const [PracticeMode.reading, PracticeMode.writing, PracticeMode.radical];
    default: // LEVEL_8, LEVEL_7, LEVEL_6, LEVEL_5
      return const [
        PracticeMode.reading,
        PracticeMode.writing,
        PracticeMode.radical,
        PracticeMode.compoundStructure,
      ];
  }
}

/// 選択中の演習モード（ホーム画面の演習開始ダイアログで選ぶ）
final practiceModeProvider = StateProvider<PracticeMode>((ref) => PracticeMode.mixed);

/// 実際に画面に表示する1問分のデータ。
/// 元のKanjiQuestion(source)から、演習モードに応じて
/// 「何を大きく表示するか」「選択肢に何を並べるか」を作り分ける。
class PracticeQuestion {
  final KanjiQuestion source;
  final PracticeMode actualMode; // mixed選択時に実際に割り当てられたモード
  final String prompt; // 大きく表示する文字（漢字 or 読み方）
  final String instruction; // 「この漢字の読み方は？」等の指示文
  final List<String> choices;
  final String correctAnswer;

  const PracticeQuestion({
    required this.source,
    required this.actualMode,
    required this.prompt,
    required this.instruction,
    required this.choices,
    required this.correctAnswer,
  });
}

/// KanjiQuestionの一覧から、指定モードに沿ったPracticeQuestionを組み立てる。
/// readingモードの選択肢（読み方）は、同じ一覧内の他の問題のreadingから
/// ランダムに抽出して作る（Firestore側のchoicesは漢字の選択肢のため使えない）。
/// radical/compoundStructureも同様に、他の問題や級内のデータから選択肢を組み立てる。
List<PracticeQuestion> _buildPracticeQuestions(
  List<KanjiQuestion> questions,
  PracticeMode mode,
  String level, {
  List<KanjiQuestion>? distractorPool,
}) {
  final random = Random();
  // 選択肢の紛らわしい候補は distractorPool（無ければ questions）から作る。
  final pool = distractorPool ?? questions;
  final allReadings = pool
      .expand((q) => q.allReadings)
      .map((r) => r.reading)
      .where((r) => r.isNotEmpty)
      .toSet()
      .toList();
  final radicalsInSet = pool
      .map((q) => KanjiRadicalData.get(q.kanji)?.radical)
      .whereType<String>()
      .toSet()
      .toList();
  final compoundPool = CompoundStructureData.forLevel(level);
  final singleModes = availableModesForLevel(level);

  return questions.map((question) {
    var actualMode = mode;
    if (mode == PracticeMode.mixed) {
      actualMode = singleModes[random.nextInt(singleModes.length)];
    }

    // 読み方データが無い問題はreading出題ができないため書き取りにフォールバック
    if (actualMode == PracticeMode.reading &&
        (question.reading == null || question.reading!.isEmpty)) {
      actualMode = PracticeMode.writing;
    }

    if (actualMode == PracticeMode.reading) {
      // 複数の読みを持つ漢字は、出題のたびにどれか1つを正解として選ぶ。
      final picked = question.allReadings[random.nextInt(question.allReadings.length)];
      final correctReading = picked.reading;
      // 同じ漢字の他の読みは紛らわしい不正解になるため選択肢から除く。
      final ownReadings = question.allReadings.map((r) => r.reading).toSet();
      final distractors = allReadings.where((r) => !ownReadings.contains(r)).toList()
        ..shuffle(random);
      final choices = [correctReading, ...distractors.take(3)]..shuffle(random);

      return PracticeQuestion(
        // 解説（読み方・用例）が出題した読みと一致するよう差し替える。
        source: question.copyWith(reading: picked.reading, example: picked.example),
        actualMode: actualMode,
        prompt: question.kanji,
        instruction: 'この漢字の読み方はどれ？',
        choices: choices,
        correctAnswer: correctReading,
      );
    }

    if (actualMode == PracticeMode.radical) {
      final info = KanjiRadicalData.get(question.kanji);
      final radicalPool = radicalsInSet.length >= 4 ? radicalsInSet : KanjiRadicalData.allRadicals;
      if (info == null || radicalPool.length < 4) {
        actualMode = PracticeMode.writing;
      } else {
        final distractors = radicalPool.where((r) => r != info.radical).toList()
          ..shuffle(random);
        final choices = [info.radical, ...distractors.take(3)]..shuffle(random);

        return PracticeQuestion(
          source: question,
          actualMode: actualMode,
          prompt: question.kanji,
          instruction: 'この漢字の部首はどれ？',
          choices: choices,
          correctAnswer: info.radical,
        );
      }
    }

    if (actualMode == PracticeMode.compoundStructure) {
      if (compoundPool.isEmpty) {
        actualMode = PracticeMode.writing;
      } else {
        final compound = compoundPool[random.nextInt(compoundPool.length)];
        final choices = compoundStructureLabels.values.toList()..shuffle(random);

        return PracticeQuestion(
          source: question,
          actualMode: actualMode,
          prompt: '${compound.jukugo}（${compound.reading}）',
          instruction: 'この熟語の構成として正しいものはどれ？',
          choices: choices,
          correctAnswer: compound.correctLabel,
        );
      }
    }

    // 書き取り: 読み方を見て正しい漢字を選ぶ
    final prompt = (question.reading != null && question.reading!.isNotEmpty)
        ? question.reading!
        : question.kanji;
    return PracticeQuestion(
      source: question,
      actualMode: PracticeMode.writing,
      prompt: prompt,
      instruction: 'この読み方の漢字はどれ？',
      // Firestore上のchoicesは正解位置が問題ごとに固定されているため、
      // 同じ問題を再度出題した際に「位置で覚えてしまう」ことがないよう
      // 表示のたびにシャッフルする。
      choices: List<String>.from(question.choices)..shuffle(random),
      correctAnswer: question.correctAnswer,
    );
  }).toList();
}

/// 間違いノートの「解き直す」用。非 null のあいだ、演習の出題はこの問題だけになる。
/// 通常の演習を始めるとき・解き直しから戻るときに null へ戻す。
final practiceRetryQuestionsProvider =
    StateProvider<List<PracticeQuestion>?>((ref) => null);

/// 間違いノートの1問 [target] を、既存の演習画面で出題できる形にする。
/// 選択肢の候補は [pool]（同じ級の問題）から作る。出題形式は読み取り→書き取りの順で選ぶ。
List<PracticeQuestion> buildRetryPracticeQuestions(
  KanjiQuestion target,
  List<KanjiQuestion> pool,
  String level,
) {
  final hasReading = target.reading != null && target.reading!.isNotEmpty;
  return _buildPracticeQuestions(
    [target],
    hasReading ? PracticeMode.reading : PracticeMode.writing,
    level,
    distractorPool: [target, ...pool.where((q) => q.id != target.id)],
  );
}

/// ながら学習（自動で進む読み上げ学習）の1回の問題数。子ども向けに短く区切る。
const int nagaraSessionSize = 10;

/// ながら学習用の問題を作る。選択式の「読み」「書き取り」だけ（手書き・部首・熟語の構成は含めない）。
/// 読みと書き取りを半々にまぜる。
List<PracticeQuestion> buildNagaraPracticeQuestions(
  List<KanjiQuestion> all,
  String level, {
  int size = nagaraSessionSize,
}) {
  final choice = all.where((q) => q.questionType == QuestionType.multipleChoice).toList();
  final levelKanji = LevelKanjiData.forLevel(level).toSet();
  final inLevel = levelKanji.isEmpty ? choice : choice.where((q) => levelKanji.contains(q.kanji)).toList();
  inLevel.shuffle();
  final selected = inLevel.take(size).toList();
  final half = (selected.length + 1) ~/ 2;
  final built = [
    ..._buildPracticeQuestions(selected.take(half).toList(), PracticeMode.reading, level, distractorPool: choice),
    ..._buildPracticeQuestions(selected.skip(half).toList(), PracticeMode.writing, level, distractorPool: choice),
  ]..shuffle();
  return built;
}

/// ながら学習の問題セット（その級の問題から。「覚えた」・マスター済みは除く）。
final nagaraQuestionsProvider =
    FutureProvider.autoDispose.family<List<PracticeQuestion>, String>((ref, level) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final uid = ref.watch(currentUserIdProvider);
  final user = await ref.watch(currentUserProvider.future);
  final all = await firestoreService.getQuestionsByLevel(
    level,
    limit: 100,
    uid: uid,
    profileId: user?.profileId ?? 'default',
    masteryThreshold: user?.masteryThreshold ?? 3,
  );
  return buildNagaraPracticeQuestions(all, level);
});

// 現在の問題セット（その級の問題からランダムに10問だけ出題する。
// 「覚えた」チェック済み・連続正解でマスター済みの問題は除外される）
final practiceQuestionsProvider =
    FutureProvider.family<List<PracticeQuestion>, String>((ref, level) async {
  final retry = ref.watch(practiceRetryQuestionsProvider);
  if (retry != null) return retry;
  final firestoreService = ref.watch(firestoreServiceProvider);
  final uid = ref.watch(currentUserIdProvider);
  final user = await ref.watch(currentUserProvider.future);
  final mode = ref.watch(practiceModeProvider);
  // その級で新しく習う漢字（公式級別漢字表の配当漢字）の問題だけに絞る。
  // 下の級の漢字が混ざらないようにするため。配当表が無い級は絞り込まない。
  final levelKanji = LevelKanjiData.forLevel(level);
  final List<KanjiQuestion> all;
  if (levelKanji.length > 100) {
    // limit(100) だとID順の先頭100字しか出ないため、級内の全字から
    // ランダムに選んだ字をID指定で取得する（読み取り量は数十件）。
    all = await firestoreService.getQuestionsByLevelSampled(
      level,
      levelKanji,
      need: practiceSessionSize,
      uid: uid,
      profileId: user?.profileId ?? 'default',
      masteryThreshold: user?.masteryThreshold ?? 3,
    );
  } else {
    all = await firestoreService.getQuestionsByLevel(
      level,
      limit: 100,
      uid: uid,
      profileId: user?.profileId ?? 'default',
      masteryThreshold: user?.masteryThreshold ?? 3,
    );
  }
  final levelSet = levelKanji.toSet();
  final inLevel = levelSet.isEmpty
      ? all
      : all.where((q) => levelSet.contains(q.kanji)).toList();
  inLevel.shuffle();
  final selected = inLevel.take(practiceSessionSize).toList();
  return _buildPracticeQuestions(selected, mode, level);
});

// 現在解いている問題インデックス
final currentQuestionIndexProvider = StateProvider<int>((ref) => 0);

// 正解数（セッション内）
final correctCountProvider = StateProvider<int>((ref) => 0);

// 回答済み問題数（セッション内）
final answeredCountProvider = StateProvider<int>((ref) => 0);

// 現在のコンボ数
final comboCountProvider = StateProvider<int>((ref) => 0);

// Aha Moment到達フラグ（初回3問正解）
final ahaMomentReachedProvider = StateProvider<bool>((ref) => false);

class PracticeViewModel extends StateNotifier<PracticeState> {
  final Ref ref;

  PracticeViewModel(this.ref)
      : super(const PracticeState(
          isLoading: false,
          currentQuestion: null,
          lastAnswerIsCorrect: null,
          isAnswering: false,
        ));

  Future<void> answerQuestion(bool isCorrect) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    state = state.copyWith(isAnswering: true);

    try {
      final level = ref.read(currentLevelProvider);
      final questions = ref.read(practiceQuestionsProvider(level)).valueOrNull;
      final index = ref.read(currentQuestionIndexProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final user = await ref.read(currentUserProvider.future);

      final PracticeQuestion? question =
          (questions != null && index < questions.length) ? questions[index] : null;

      if (question != null) {
        // 答ログを保存
        final log = UserAnswerLog(
          id: '',
          uid: uid,
          profileId: user?.profileId ?? 'default',
          questionId: question.source.id,
          isCorrect: isCorrect,
          mode: AnswerMode.normal,
          answeredAt: DateTime.now(),
          level: level,
        );
        await firestoreService.addAnswerLog(log);

        // 推しの成長（網羅率）に使う、解いた問題IDの端末内記録。
        // 失敗しても学習フローは止めない。
        try {
          await OshiProgressStore.markAnswered(
            profileId: user?.profileId ?? 'default',
            level: level,
            questionId: question.source.id,
          );
        } catch (_) {}

        // 試験に向けて（10分プラン・書き出し）用の端末内の解答履歴。失敗しても止めない。
        try {
          await ref.read(historyProvider.notifier).recordAnswer(
                questionId: question.source.id,
                level: level,
                correct: isCorrect,
              );
        } catch (_) {}

        // 学習コイン：初めて解く問題で付与（同じ問題は二度付与されない）。
        // コインは付加機能なので、未設定・失敗しても学習フローは止めない。
        try {
          unawaited(ref
              .read(coinProvider.notifier)
              .grant(CoinEvent.newQuestion(question.source.id))
              .catchError((_) => null));
        } catch (_) {}

        // 状態を更新
        if (isCorrect) {
          ref.read(correctCountProvider.notifier).state++;
          ref.read(comboCountProvider.notifier).state++;
        } else {
          ref.read(comboCountProvider.notifier).state = 0;
          // 誤答時のみ苦手漢字リストを再分析（次の問題表示をブロックしないよう
          // 完了を待たずバックグラウンドで実行）。
          ref
              .read(aiWeakAnalysisServiceProvider)
              .analyzeWeakKanjis(uid, profileId: user?.profileId ?? 'default')
              .catchError((_) {});

          // 不正解だった問題を間隔反復（スペースドリピティション）の
          // 復習リストに追加する（完了を待たずバックグラウンドで実行）。
          addToSpacedRepetitionWithRef(
            ref,
            questionId: question.source.id,
            kanji: question.source.kanji,
            category: question.actualMode.toString().split('.').last,
            question: question.instruction,
            options: question.choices,
            correctAnswer: question.correctAnswer,
          ).catchError((_) {});
        }

        ref.read(answeredCountProvider.notifier).state++;

        // 日次問題数の学習目標を1問分進める（完了を待たずバックグラウンドで実行）
        incrementDailyQuestionGoalFromRef(ref).catchError((_) {});

        // 級ごとの正答率集計を更新したので再取得させる
        // （次の級までのカウントダウン・クリア判定に使う）
        ref.invalidate(levelProgressProvider);

        // 演習で1問以上回答した = 「今日学習した」とみなしストリークを更新
        // （完了を待たずバックグラウンドで実行）。
        recordStudyActivityWithRef(ref).catchError((_) {});

        // Aha Moment判定：初回3問正解
        final correctCount = ref.read(correctCountProvider);
        if (correctCount >= 3 && !ref.read(ahaMomentReachedProvider)) {
          ref.read(ahaMomentReachedProvider.notifier).state = true;
          // Analytics event: aha_moment_reached
        }

        state = state.copyWith(
          lastAnswerIsCorrect: isCorrect,
          isAnswering: false,
        );

        // 次の問題へ遷移（自動は呼ばない、UIが制御）
      }
    } catch (e) {
      state = state.copyWith(isAnswering: false);
      rethrow;
    }
  }

  void moveToNextQuestion() {
    final currentIndex = ref.read(currentQuestionIndexProvider);
    ref.read(currentQuestionIndexProvider.notifier).state = currentIndex + 1;
    state = state.copyWith(lastAnswerIsCorrect: null);
  }

  void reset() {
    ref.read(currentQuestionIndexProvider.notifier).state = 0;
    ref.read(correctCountProvider.notifier).state = 0;
    ref.read(answeredCountProvider.notifier).state = 0;
    ref.read(comboCountProvider.notifier).state = 0;
    ref.read(ahaMomentReachedProvider.notifier).state = false;
    // 次の練習の終了画面に、そのセッションの分だけコイン内訳が出るようにする。
    try {
      ref.read(coinProvider.notifier).takeRecent();
    } catch (_) {}
    state = const PracticeState(
      isLoading: false,
      currentQuestion: null,
      lastAnswerIsCorrect: null,
      isAnswering: false,
    );
  }
}

class PracticeState {
  final bool isLoading;
  final PracticeQuestion? currentQuestion;
  final bool? lastAnswerIsCorrect;
  final bool isAnswering;

  const PracticeState({
    required this.isLoading,
    required this.currentQuestion,
    required this.lastAnswerIsCorrect,
    required this.isAnswering,
  });

  PracticeState copyWith({
    bool? isLoading,
    PracticeQuestion? currentQuestion,
    bool? lastAnswerIsCorrect,
    bool? isAnswering,
  }) {
    return PracticeState(
      isLoading: isLoading ?? this.isLoading,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      lastAnswerIsCorrect: lastAnswerIsCorrect ?? this.lastAnswerIsCorrect,
      isAnswering: isAnswering ?? this.isAnswering,
    );
  }
}

final practiceViewModelProvider =
    StateNotifierProvider<PracticeViewModel, PracticeState>((ref) {
  return PracticeViewModel(ref);
});
