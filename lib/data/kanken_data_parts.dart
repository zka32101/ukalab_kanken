import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/ui.dart';

import '../views/core_features_entry.dart' show kankenMistakeNoteStore;
import 'exam_prep_data.dart';

/// 設定画面「データの管理」（書き出し・読み込み・リセット）の対象。
///
/// 端末内に保存している学習データ（デイリーミッションの目標・達成履歴、自分用メモ、
/// 当日チェックリスト、間違いノート）。
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
];
