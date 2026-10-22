import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/level_achievement.dart';
import '../viewmodels/index.dart';

/// 一度でも正解した問題のID（例: `LEVEL_9-毎`）。回答のたびに作り直す。
final correctQuestionIdsProvider = FutureProvider<Set<String>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return {};

  final user = await ref.watch(currentUserProvider.future);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getCorrectQuestionIds(
    uid,
    profileId: user?.profileId ?? 'default',
  );
});

/// 級ごとの達成度（漢字＝覚えた漢字、問題＝正解した漢字。どちらも配当漢字に対する割合）。
/// 読み込み中・未ログインのときは、すべて 0 の達成度を返す。
final levelAchievementProvider = Provider<Map<String, LevelAchievement>>((ref) {
  final learned =
      ref.watch(learnedKanjiIdsProvider).valueOrNull ?? const <String>{};
  final correct =
      ref.watch(correctQuestionIdsProvider).valueOrNull ?? const <String>{};
  return LevelAchievement.compute(
    levels: kKankenLevels,
    learnedIds: learned,
    correctIds: correct,
  );
});
