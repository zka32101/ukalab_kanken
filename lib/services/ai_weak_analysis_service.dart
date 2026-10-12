import '../models/index.dart';
import 'firestore_service.dart';

class AIWeakAnalysisService {
  final FirestoreService _firestoreService;

  AIWeakAnalysisService(this._firestoreService);

  /// ユーザーの誤答パターンから苦手漢字を分析・更新
  /// petit_ai経由でCloud Functionsから呼ばれる想定
  Future<void> analyzeWeakKanjis(String uid, {String profileId = 'default'}) async {
    try {
      // ユーザーの全答ログを取得
      final answerLogs =
          await _firestoreService.getUserAnswerLogs(uid, profileId: profileId);

      // 誤答のみフィルタ
      final incorrectAnswers = answerLogs.where((log) => !log.isCorrect).toList();

      // 誤答漢字のカウント
      final weakMap = <String, int>{};
      for (final log in incorrectAnswers) {
        weakMap[log.questionId] = (weakMap[log.questionId] ?? 0) + 1;
      }

      // WeakKanjiListを更新
      for (final entry in weakMap.entries) {
        final weakList =
            await _firestoreService.getWeakKanjiList(uid, profileId: profileId);
        final existingWeak = weakList.firstWhere(
          (w) => w.kanjiId == entry.key,
          orElse: () => WeakKanjiList(
            id: '',
            uid: uid,
            kanjiId: entry.key,
            missCount: 0,
            lastMissedAt: DateTime.now(),
          ),
        );

        final updatedWeak = WeakKanjiList(
          id: existingWeak.id,
          uid: uid,
          kanjiId: entry.key,
          missCount: entry.value,
          lastMissedAt: DateTime.now(),
          masteredAt: existingWeak.masteredAt,
        );

        await _firestoreService.upsertWeakKanjiList(updatedWeak, profileId: profileId);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 苦手集中モード用の問題セットを取得
  /// 最近の誤答が多い漢字から出題（学習済みを除外）
  Future<List<KanjiQuestion>> getWeakKanjiFocusQuestions(
    String uid, {
    int limit = 10,
    String profileId = 'default',
  }) async {
    try {
      final weakKanjis =
          await _firestoreService.getUserWeakKanjis(uid, profileId: profileId);

      // 学習済み漢字を取得
      final learnedKanjis =
          await _firestoreService.getUserLearnedKanjis(uid, profileId: profileId);
      final learnedKanjiIds = learnedKanjis.toSet();

      final questions = <KanjiQuestion>[];
      for (final weakKanjiId in weakKanjis.take(limit * 2)) {
        if (!learnedKanjiIds.contains(weakKanjiId)) {
          final question = await _firestoreService.getKanjiQuestion(weakKanjiId);
          if (question != null) {
            questions.add(question);
            if (questions.length >= limit) break;
          }
        }
      }

      return questions;
    } catch (e) {
      rethrow;
    }
  }

  /// 苦手漢字を習得済みとしてマーク
  Future<void> markAsMatured(
    String uid,
    String kanjiId, {
    String profileId = 'default',
  }) async {
    final weakList =
        await _firestoreService.getWeakKanjiList(uid, profileId: profileId);
    final dynamic weak = weakList.firstWhere(
      (w) => w.kanjiId == kanjiId,
      orElse: () => null as dynamic,
    );

    if (weak != null) {
      final updated = weak.copyWith(masteredAt: DateTime.now());
      await _firestoreService.upsertWeakKanjiList(updated, profileId: profileId);
    }
  }

  /// ユーザーの苦手漢字数を取得（Dashboard用）
  Future<int> getWeakKanjiCount(String uid, {String profileId = 'default'}) async {
    final weakKanjis =
        await _firestoreService.getWeakKanjiList(uid, profileId: profileId);
    final notMastered = weakKanjis.where((w) => w.masteredAt == null).length;
    return notMastered;
  }
}
