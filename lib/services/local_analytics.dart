import 'package:ukalab_core/ukalab_core.dart';

import '../models/analytics.dart';
import '../models/weak_area.dart';

/// 端末内の解答履歴（[ProgressRecord]）から、分析画面用のデータを作る。
///
/// 解答の記録は端末内にしかなく、Firestore には書かれていない。
/// そのため分析画面は、この関数で履歴から集計する。

/// 解答どうしの間隔がこれ以下なら、続けて学習していたとみなす。
const _sessionGap = Duration(minutes: 10);

/// 1回の解答に数える時間の上限。
const _perAnswerCap = Duration(minutes: 2);

/// 続けた学習の最初の1問に数える時間。
const _firstAnswerTime = Duration(seconds: 30);

/// 級の情報がない記録のまとめ先。
const _unknownTopic = 'unknown';

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// 解答の間隔から、学習時間(分)を見積もる。
/// 履歴には「解いていた時間」がないので、近い解答どうしの間隔から数える。
int estimateStudyMinutes(List<ProgressRecord> records) {
  if (records.isEmpty) return 0;
  final sorted = [...records]..sort((a, b) => a.at.compareTo(b.at));
  var total = _firstAnswerTime;
  for (var i = 1; i < sorted.length; i++) {
    final gap = sorted[i].at.difference(sorted[i - 1].at);
    if (gap <= _sessionGap) {
      total += gap > _perAnswerCap ? _perAnswerCap : gap;
    } else {
      total += _firstAnswerTime;
    }
  }
  return (total.inSeconds / 60).round();
}

/// 連続して学習した日数。今日か昨日までつながっていれば、その日数。
int currentStreakDays(List<ProgressRecord> records, DateTime now) {
  final days = {for (final r in records) _dayOf(r.at)};
  var day = _dayOf(now);
  if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
  var count = 0;
  while (days.contains(day)) {
    count++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return count;
}

/// これまでで最も長く続いた日数。
int longestStreakDays(List<ProgressRecord> records) {
  final days = {for (final r in records) _dayOf(r.at)}.toList()..sort();
  var longest = 0;
  var run = 0;
  DateTime? prev;
  for (final d in days) {
    run = (prev != null && DateTime(d.year, d.month, d.day - 1) == prev)
        ? run + 1
        : 1;
    if (run > longest) longest = run;
    prev = d;
  }
  return longest;
}

/// 学習分析(成長)の全体の数字。履歴が空なら null。
LearningAnalytics? analyticsFromHistory(
  List<ProgressRecord> records, {
  DateTime? now,
  String userId = 'local',
}) {
  if (records.isEmpty) return null;
  final at = now ?? DateTime.now();
  final correct = records.where((r) => r.correct).length;
  final last =
      records.map((r) => r.at).reduce((a, b) => a.isAfter(b) ? a : b);
  final byTopic = <String, int>{};
  for (final r in records) {
    final topic = r.topicId ?? _unknownTopic;
    byTopic[topic] = (byTopic[topic] ?? 0) + 1;
  }
  return LearningAnalytics(
    userId: userId,
    totalStudyMinutes: estimateStudyMinutes(records),
    averageAccuracy: correct / records.length,
    totalQuestionsAttempted: records.length,
    correctAnswers: correct,
    currentStreak: currentStreakDays(records, at),
    longestStreak: longestStreakDays(records),
    lastStudyDate: last,
    categoryStats: byTopic,
  );
}

/// 過去[days]日の、日ごとの成長。解答のない日は含めない。
List<GrowthData> growthFromHistory(
  List<ProgressRecord> records, {
  DateTime? now,
  int days = 30,
}) {
  final today = _dayOf(now ?? DateTime.now());
  final from = DateTime(today.year, today.month, today.day - (days - 1));
  final byDay = <DateTime, List<ProgressRecord>>{};
  for (final r in records) {
    final d = _dayOf(r.at);
    if (d.isBefore(from) || d.isAfter(today)) continue;
    byDay.putIfAbsent(d, () => []).add(r);
  }
  final dates = byDay.keys.toList()..sort();
  return [
    for (final d in dates)
      GrowthData(
        date: d,
        accuracy: byDay[d]!.where((r) => r.correct).length / byDay[d]!.length,
        correctCount: byDay[d]!.where((r) => r.correct).length,
        totalCount: byDay[d]!.length,
        studyMinutes: estimateStudyMinutes(byDay[d]!),
      ),
  ];
}

/// 級ごとの正答率から、苦手分野の分析を作る。
/// [nameOf] は級のID(例: LEVEL_2)を画面に出す名前にする関数。
WeakAreaAnalysis weakAreasFromHistory(
  List<ProgressRecord> records, {
  required String Function(String levelId) nameOf,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final byTopic = <String, List<ProgressRecord>>{};
  for (final r in records) {
    byTopic.putIfAbsent(r.topicId ?? _unknownTopic, () => []).add(r);
  }
  final areas = <WeakArea>[
    for (final e in byTopic.entries)
      () {
        final correct = e.value.where((r) => r.correct).length;
        final rate = correct / e.value.length;
        final last =
            e.value.map((r) => r.at).reduce((a, b) => a.isAfter(b) ? a : b);
        return WeakArea(
          categoryId: e.key,
          categoryName: e.key == _unknownTopic ? 'その他' : nameOf(e.key),
          totalAttempts: e.value.length,
          correctAnswers: correct,
          accuracyRate: rate,
          level: weakLevelFromAccuracy(rate),
          recentStreakDays: currentStreakDays(e.value, at),
          lastAttemptAt: last,
        );
      }(),
  ]..sort((a, b) => a.accuracyRate.compareTo(b.accuracyRate));
  final total = records.length;
  final correctAll = records.where((r) => r.correct).length;
  return WeakAreaAnalysis(
    allAreas: areas,
    overallAccuracy: total == 0 ? 0.0 : correctAll / total,
    analyzedAt: at,
  );
}
