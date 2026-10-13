import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../models/kanji_question.dart' as k;
import '../providers/purchases_provider.dart';
import '../viewmodels/services_provider.dart';
import '../viewmodels/user_viewmodel.dart';

/// ukalab_core の「試験に向けて」共通機能（10分プラン・試験直前・当日チェックリスト・
/// 更新ログ・履歴の書き出し）をこのアプリのデータにつなぐ部分。画面・文言は core 側。
/// 子ども向けのため、保存・共有など端末外へ出す操作は付けない（書き出しはコピーのみ）。

const String kExamId = 'kanken';

const String updateLogAsset = 'assets/features/update_log.jsonl';
const String checklistAsset = 'assets/features/checklist.jsonl';

/// 更新ログ（新しい順。未来の予定と90日より前は除く）。
Future<List<UpdateLogEntry>> loadUpdateLog(
    {DateTime? now, AssetBundle? bundle}) async {
  final text = await (bundle ?? rootBundle).loadString(updateLogAsset);
  return recentUpdates(parseUpdateLogJsonl(text).entries, now ?? DateTime.now(),
      examId: kExamId);
}

/// 当日チェックリスト（会場受験。分類順）。すべて「公式で要確認」。
Future<List<ChecklistItem>> loadChecklist({AssetBundle? bundle}) async {
  final text = await (bundle ?? rootBundle).loadString(checklistAsset);
  return checklistFor(kExamId, parseChecklistItemsJsonl(text).items,
      venue: ExamVenueKind.venue);
}

/// 漢検の1問（読み方を問う選択式）を core の [Question] にする。
/// 読みが無い問題や手書き問題は対象外（null）。選択肢は同じ一覧の他の読みから作る。
Question? examPrepQuestionFrom(k.KanjiQuestion src, List<String> readingPool) {
  final reading = src.reading;
  if (reading == null || reading.isEmpty) return null;
  final others = readingPool.where((r) => r != reading).toSet().toList()
    ..sort();
  if (others.length < 2) return null;
  final rnd = Random(src.id.hashCode);
  others.shuffle(rnd);
  final choices = [reading, ...others.take(3)]..shuffle(rnd);
  return Question(
    qid: src.id,
    examId: kExamId,
    levelId: src.level,
    subjectId: 'kanji',
    topicId: src.level,
    prompt: '「${src.kanji}」の読み方はどれ？',
    choices: choices,
    answerIndex: choices.indexOf(reading),
    explanation: src.example == null || src.example!.isEmpty
        ? '読みは「$reading」です。'
        : '読みは「$reading」。用例: ${src.example}',
    source: QuestionSource.original,
    sourceRef: '級別漢字表',
    contentVer: '${src.version}',
  );
}

List<Question> examPrepQuestions(List<k.KanjiQuestion> src) {
  final pool = [
    for (final q in src)
      if (q.reading != null && q.reading!.isNotEmpty) q.reading!,
  ];
  return [
    for (final q in src)
      if (examPrepQuestionFrom(q, pool) case final e?) e,
  ];
}

/// 今の級の問題（試験に向けて用）。取得に失敗したら空。
final examPrepQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  final level = ref.watch(currentLevelProvider);
  final service = ref.watch(firestoreServiceProvider);
  try {
    return examPrepQuestions(
        await service.getQuestionsByLevel(level, limit: 200));
  } catch (_) {
    return const [];
  }
});

/// 試験日（既存の受験予定日）。未設定は null。
final examPrepExamDateProvider = Provider<DateTime?>(
    (ref) => ref.watch(currentUserProvider).valueOrNull?.examDate);

/// premium 制限は core の [canUsePremiumFeature] に従う。
bool isPremiumFor(WidgetRef ref, PremiumFeature feature) =>
    canUsePremiumFeature(
      feature,
      isPremium: ref.watch(hasPremiumProvider).valueOrNull ?? false,
    );

/// 解答履歴（端末内。個人を特定する情報は持たない）。
class HistoryNotifier extends Notifier<List<ProgressRecord>> {
  static const _key = 'ukalab_kanken_history_v1';
  late Future<void> _loaded;

  @override
  List<ProgressRecord> build() {
    _loaded = _load();
    return const [];
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = decodeHistory(prefs.getString(_key));
      if (records.isNotEmpty) state = [...records, ...state];
    } catch (_) {}
  }

  Future<void> record(ProgressRecord r) async {
    await _loaded;
    state = appendHistory(state, r);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, encodeHistory(state));
    } catch (_) {}
  }

  /// 通常の練習の解答を1件記録する。
  Future<void> recordAnswer(
          {required String questionId,
          required String level,
          required bool correct,
          DateTime? at}) =>
      record(ProgressRecord(
          qid: questionId,
          subjectId: 'kanji',
          topicId: level,
          correct: correct,
          at: at ?? DateTime.now()));
}

final historyProvider =
    NotifierProvider<HistoryNotifier, List<ProgressRecord>>(HistoryNotifier.new);

/// 当日チェックリストのチェック状態（端末内）。
class ChecklistNotifier extends Notifier<ChecklistProgress> {
  static const _key = 'ukalab_kanken_exam_checklist_v1';
  late Future<void> _loaded;

  Future<void> get ready => _loaded;

  @override
  ChecklistProgress build() {
    _loaded = _load();
    return const ChecklistProgress();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_key);
      if (ids != null) state = ChecklistProgress({...ids, ...state.checkedIds});
    } catch (_) {}
  }

  Future<void> setProgress(ChecklistProgress p) async {
    await _loaded;
    state = p;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, p.checkedIds.toList()..sort());
    } catch (_) {}
  }

  Future<void> restore(Iterable<String> ids) =>
      setProgress(ChecklistProgress(ids.toSet()));
  Future<void> reset() => setProgress(const ChecklistProgress());
}

final checklistProvider =
    NotifierProvider<ChecklistNotifier, ChecklistProgress>(
        ChecklistNotifier.new);
