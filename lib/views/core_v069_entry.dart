import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/exam_prep_data.dart' show historyProvider;
import 'core_features_entry.dart' show mistakeNotesProvider, openMistakeNote;

/// ukalab_core v0.67〜v0.69 の「模擬試験の結果分析」「今日の復習」「推しの成長演出」を
/// このアプリのデータにつなぐ部分。画面・文言は core 側。ここは入力の組み立て・保存・遷移だけ。
/// 子ども向けのため、外部共有・外部リンクは付けない。
/// premium 制限: core の PremiumFeature にこの3機能は無いため、すべて無料で表示する。

// ---------------------------------------------------------------------------
// 今日の復習（ReviewSchedulerEngine / TodayReviewCard）
// ---------------------------------------------------------------------------

const ReviewSchedulerEngine kankenReviewEngine = ReviewSchedulerEngine();

/// 復習予定の保存先（端末内。キー ukalab_kanken_review_schedule。バックアップ・リセットは kankenDataParts）。
final ReviewSchedulerStore kankenReviewSchedulerStore =
    SharedPreferencesReviewSchedulerStore('kanken');

/// 間違いノートから復習予定を同期して保存し、返す（何度呼んでも結果は同じ）。
/// 間違いノート（mistakeNotesProvider）は解答履歴から更新されるので、解答のたびに作り直される。
final reviewScheduleProvider =
    FutureProvider.autoDispose<List<ReviewItem>>((ref) async {
  final notes = await ref.watch(mistakeNotesProvider.future);
  final before = await kankenReviewSchedulerStore.read();
  final after = kankenReviewEngine.sync(before, notes.entries);
  if (!listEquals(before, after)) {
    try {
      await kankenReviewSchedulerStore.write(after);
    } catch (_) {}
  }
  return after;
});

/// 1問の解答結果を復習予定に反映する（期限が来ている問題だけ）。
/// [at] は履歴の ProgressRecord.at と同じ時刻を渡す（復習より後の間違いと見なされないため）。
/// 失敗しても学習の流れは止めない。
Future<void> recordKankenReviewResult(
  String qid, {
  required bool correct,
  required DateTime at,
  ReviewSchedulerStore? store,
}) async {
  try {
    final s = store ?? kankenReviewSchedulerStore;
    final items = await s.read();
    final target = items.where((i) => i.qid == qid).firstOrNull;
    if (target == null || !kankenReviewEngine.isDue(target, at)) return;
    await s.write(
        kankenReviewEngine.applyResult(items, qid, correct: correct, now: at));
  } catch (_) {}
}

/// ホーム「今日やること」の今日の復習カード。
/// 件数は間違いノート由来の期限分。「やってみる」は既存の間違いノート（解き直しつき）を開く。
/// （既存の「復習（間隔反復）」は Firestore の別データなので、件数と画面がずれないよう接続しない。）
class TodayReviewEntry extends ConsumerWidget {
  const TodayReviewEntry({super.key, this.clock = DateTime.now, this.onStart});

  final DateTime Function() clock;

  /// テスト用。省略時は間違いノートを開く。
  final void Function(BuildContext context)? onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(reviewScheduleProvider).valueOrNull ?? const [];
    return TodayReviewCard(
      dueCount: kankenReviewEngine.dueCount(items, clock()),
      onStart: () => (onStart ?? openMistakeNote)(context),
    );
  }
}

// ---------------------------------------------------------------------------
// 推しの成長演出（OshiGrowthBubble / OshiGrowthService）
// ---------------------------------------------------------------------------

/// 祝い済みの節目の保存先（端末内。キー ukalab_oshi_growth_kanken）。
final oshiGrowthServiceProvider = Provider<OshiGrowthService>(
  (ref) => OshiGrowthService(store: SharedPreferencesOshiGrowthStore('kanken')),
);

/// 端末内の解答履歴から、累計の回答数と学習した日数を数える（個人情報は含めない）。
/// 履歴は直近 2000 件までなので、それより古い分は数えない（節目の最大は 1000 問・100 日）。
OshiGrowthProgress oshiGrowthProgressFrom(List<ProgressRecord> history) {
  final days = <DateTime>{
    for (final r in history) DateTime(r.at.year, r.at.month, r.at.day),
  };
  return OshiGrowthProgress(totalAnswered: history.length, studyDays: days.length);
}

/// ホーム「記録」に置く、推しの成長の節目の見張り役。
/// ホームには吹き出しを出さない（常時表示は「推しの一言」だけ）。
/// 節目に届いたときは、一度だけ祝福ダイアログを出す（久しぶりでも1回だけ）。
class OshiGrowthEntry extends ConsumerStatefulWidget {
  const OshiGrowthEntry({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  ConsumerState<OshiGrowthEntry> createState() => _OshiGrowthEntryState();
}

class _OshiGrowthEntryState extends ConsumerState<OshiGrowthEntry> {
  OshiGrowthProgress? _checked;
  bool _loaded = false;

  Future<void> _check(OshiGrowthProgress progress) async {
    if (progress.totalAnswered == 0 && progress.studyDays == 0) return;
    if (_checked != null &&
        _checked!.totalAnswered == progress.totalAnswered &&
        _checked!.studyDays == progress.studyDays) {
      return;
    }
    _checked = progress;
    try {
      final svc = ref.read(oshiGrowthServiceProvider);
      if (!_loaded) {
        await svc.load();
        _loaded = true;
      }
      final milestone = await svc.checkHeadline(progress);
      if (milestone == null || !mounted) return;
      await showOshiGrowthDialog(context, milestone: milestone);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final progress = oshiGrowthProgressFrom(ref.watch(historyProvider));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check(progress);
    });
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// 模擬試験の結果分析（MockExamAnalysisEngine / MockExamAnalysisCard）
// ---------------------------------------------------------------------------

/// 模擬試験の結果画面に出す分析カード。分野＝出題形式（読み・意味・画数など）。
/// [answers] は今回の試験の1問ごとの結果。分野名は既存の categoryLabel を渡す。
class MockExamAnalysisEntry extends StatelessWidget {
  const MockExamAnalysisEntry({
    super.key,
    required this.answers,
    required this.topicLabel,
  });

  final List<MockExamAnswer> answers;
  final String Function(String topicId) topicLabel;

  @override
  Widget build(BuildContext context) {
    if (answers.isEmpty) return const SizedBox.shrink();
    return MockExamAnalysisCard(
      analysis: const MockExamAnalysisEngine().analyze(answers),
      topicLabel: topicLabel,
    );
  }
}
