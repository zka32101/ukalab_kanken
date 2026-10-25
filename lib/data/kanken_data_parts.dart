import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/glossary.dart'
    show learnedTermsDataPart;
import 'package:ukalab_core/ui.dart';

import '../views/core_features_entry.dart' show kankenMistakeNoteStore;
import '../views/core_v069_entry.dart' show kankenReviewSchedulerStore;
import '../screens/glossary_screen.dart' show kankenLearnedTermsStore;
import 'content_mistake_store.dart';
import 'exam_prep_data.dart';

/// 設定画面「データの管理」（書き出し・読み込み・リセット）の対象。
///
/// 端末内に保存している学習データ（デイリーミッションの目標・達成履歴、自分用メモ、
/// 当日チェックリスト、間違いノート、今日の復習の予定）。
/// ブックマークは整理物なので対象に含めない。コイン・衣装・学習の記録はアカウント側に保存される。
final List<DataPart> kankenDataParts = [
  DataPart(
    id: 'dailyGoal',
    export: (ref) => ref.read(dailyGoalProvider).toJson(),
    restore: (ref, json) => ref
        .read(dailyGoalProvider.notifier)
        .restore(DailyGoal.fromJson(json as Map<String, dynamic>)),
    reset: (ref) => ref.read(dailyGoalProvider.notifier).reset(),
  ),
  DataPart(
    id: 'dailyGoalHistory',
    export: (ref) =>
        [for (final e in ref.read(dailyGoalHistoryProvider)) e.toJson()],
    restore: (ref, json) => ref.read(dailyGoalHistoryProvider.notifier).restore([
      for (final j in (json as List).cast<Map<String, dynamic>>())
        DailyGoalHistoryEntry.fromJson(j),
    ]),
    reset: (ref) => ref.read(dailyGoalHistoryProvider.notifier).reset(),
  ),
  DataPart(
    id: 'questionMemo',
    export: (ref) => ref.read(questionMemoProvider),
    restore: (ref, json) => ref
        .read(questionMemoProvider.notifier)
        .restore((json as Map<String, dynamic>).cast<String, String>()),
    reset: (ref) => ref.read(questionMemoProvider.notifier).reset(),
  ),
  DataPart(
    id: 'examChecklist',
    export: (ref) => ref.read(checklistProvider).checkedIds.toList()..sort(),
    restore: (ref, json) => ref
        .read(checklistProvider.notifier)
        .restore((json as List).cast<String>()),
    reset: (ref) => ref.read(checklistProvider.notifier).reset(),
  ),
  // 間違いノート（問題ID・日時・原因・級・回数だけ。画面は開くたびに端末内から読み直す）
  mistakeNoteDataPart(kankenMistakeNoteStore),
  // 熟語系の出題で間違えた問題の控え（問題文・選択肢・正解。間違いノートの表示と解き直しに使う）
  DataPart(
    id: 'contentMistakes',
    export: (ref) async => [
      for (final s in await ContentMistakeStore.readAll()) s.toJson(),
    ],
    restore: (ref, json) async {
      final list = <ContentMistakeSnapshot>[
        if (json is List)
          for (final j in json)
            if (ContentMistakeSnapshot.fromJson(j) case final s?) s,
      ];
      await ContentMistakeStore.writeAll(list);
    },
    reset: (ref) => ContentMistakeStore.clear(),
  ),
  // 今日の復習の予定（問題ID・段・次回の日だけ。間違いノートから作り直せる）
  reviewSchedulerDataPart(kankenReviewSchedulerStore),
  // 用語集の「覚えた」（用語IDだけ）
  learnedTermsDataPart(kankenLearnedTermsStore),
];
