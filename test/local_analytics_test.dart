import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/services/local_analytics.dart';
import 'package:ukalab_core/ukalab_core.dart';

ProgressRecord _r(DateTime at, {bool correct = true, String? level = 'LEVEL_2'}) =>
    ProgressRecord(
        qid: 'q${at.microsecondsSinceEpoch}',
        subjectId: 'kanji',
        topicId: level,
        correct: correct,
        at: at);

void main() {
  final now = DateTime(2026, 10, 26, 12);

  group('analyticsFromHistory', () {
    test('履歴が空なら null', () {
      expect(analyticsFromHistory(const [], now: now), isNull);
    });

    test('解答数・正答数・正答率・級ごとの件数を数える', () {
      final a = analyticsFromHistory([
        _r(DateTime(2026, 10, 26, 10, 0)),
        _r(DateTime(2026, 10, 26, 10, 1), correct: false),
        _r(DateTime(2026, 10, 26, 10, 2), level: 'LEVEL_3'),
        _r(DateTime(2026, 10, 26, 10, 3)),
      ], now: now)!;
      expect(a.totalQuestionsAttempted, 4);
      expect(a.correctAnswers, 3);
      expect(a.averageAccuracy, 0.75);
      expect(a.categoryStats, {'LEVEL_2': 3, 'LEVEL_3': 1});
    });

    test('級の情報がない記録は unknown にまとめる', () {
      final a = analyticsFromHistory(
          [_r(DateTime(2026, 10, 26, 10), level: null)],
          now: now)!;
      expect(a.categoryStats, {'unknown': 1});
    });
  });

  group('連続日数', () {
    test('今日まで続いていればその日数', () {
      final rs = [
        _r(DateTime(2026, 10, 24, 9)),
        _r(DateTime(2026, 10, 25, 9)),
        _r(DateTime(2026, 10, 26, 9)),
      ];
      expect(currentStreakDays(rs, now), 3);
    });

    test('今日まだ解いていなくても、昨日までつながっていれば数える', () {
      final rs = [
        _r(DateTime(2026, 10, 24, 9)),
        _r(DateTime(2026, 10, 25, 9)),
      ];
      expect(currentStreakDays(rs, now), 2);
    });

    test('一昨日より前で途切れていれば 0', () {
      expect(currentStreakDays([_r(DateTime(2026, 10, 20, 9))], now), 0);
    });

    test('最長の連続日数は途中の途切れで切れる', () {
      final rs = [
        _r(DateTime(2026, 10, 1)),
        _r(DateTime(2026, 10, 2)),
        _r(DateTime(2026, 10, 3)),
        _r(DateTime(2026, 10, 10)),
        _r(DateTime(2026, 10, 11)),
      ];
      expect(longestStreakDays(rs), 3);
    });
  });

  group('学習時間の見積もり', () {
    test('1問だけなら30秒 → 1分に丸める', () {
      expect(estimateStudyMinutes([_r(DateTime(2026, 10, 26, 9))]), 1);
    });

    test('近い間隔は2分を上限に足し、離れた学習は別の学習として数える', () {
      final rs = [
        _r(DateTime(2026, 10, 26, 9, 0, 0)),
        _r(DateTime(2026, 10, 26, 9, 1, 0)), // +60秒
        _r(DateTime(2026, 10, 26, 9, 9, 0)), // 8分あく → 上限2分
        _r(DateTime(2026, 10, 26, 15, 0, 0)), // 別の学習 → +30秒
      ];
      // 30 + 60 + 120 + 30 = 240秒 = 4分
      expect(estimateStudyMinutes(rs), 4);
    });

    test('空なら 0', () {
      expect(estimateStudyMinutes(const []), 0);
    });
  });

  group('growthFromHistory', () {
    test('日ごとにまとめ、古い日付と範囲外は含めない', () {
      final g = growthFromHistory([
        _r(DateTime(2026, 10, 25, 9)),
        _r(DateTime(2026, 10, 25, 9, 1), correct: false),
        _r(DateTime(2026, 10, 26, 9)),
        _r(DateTime(2026, 8, 1, 9)), // 30日より前
      ], now: now);
      expect(g.map((e) => e.date), [DateTime(2026, 10, 25), DateTime(2026, 10, 26)]);
      expect(g[0].totalCount, 2);
      expect(g[0].correctCount, 1);
      expect(g[0].accuracy, 0.5);
      expect(g[1].accuracy, 1.0);
    });
  });

  group('weakAreasFromHistory', () {
    test('級ごとに集計し、正答率の低い順に並べる', () {
      final a = weakAreasFromHistory([
        _r(DateTime(2026, 10, 26, 9)),
        _r(DateTime(2026, 10, 26, 9, 1)),
        _r(DateTime(2026, 10, 26, 9, 2), level: 'LEVEL_3', correct: false),
        _r(DateTime(2026, 10, 26, 9, 3), level: 'LEVEL_3'),
        _r(DateTime(2026, 10, 26, 9, 4), level: 'LEVEL_3', correct: false),
      ], nameOf: (id) => '名前:$id', now: now);
      expect(a.allAreas.map((e) => e.categoryId), ['LEVEL_3', 'LEVEL_2']);
      expect(a.allAreas.first.categoryName, '名前:LEVEL_3');
      expect(a.allAreas.first.totalAttempts, 3);
      expect(a.overallAccuracy, closeTo(3 / 5, 1e-9));
      expect(a.weakAreas.map((e) => e.categoryId), contains('LEVEL_3'));
    });

    test('履歴が空なら分野は空で正答率 0', () {
      final a = weakAreasFromHistory(const [], nameOf: (id) => id, now: now);
      expect(a.allAreas, isEmpty);
      expect(a.overallAccuracy, 0.0);
    });

    test('級の情報がない記録は「その他」', () {
      final a = weakAreasFromHistory(
          [_r(DateTime(2026, 10, 26, 9), level: null)],
          nameOf: (id) => id, now: now);
      expect(a.allAreas.single.categoryName, 'その他');
    });
  });

  group('efficiencyFromHistory', () {
    test('履歴が空なら null', () {
      expect(efficiencyFromHistory(const [], now: now), isNull);
    });

    test('効率スコアは (正答数 / 分数) × 正答率', () {
      // 4問・3正解。9:00,9:01,9:02,9:03 → 30 + 60 + 60 + 60 = 210秒 → 4分(3.5を丸め)
      final e = efficiencyFromHistory([
        _r(DateTime(2026, 10, 26, 9, 0)),
        _r(DateTime(2026, 10, 26, 9, 1)),
        _r(DateTime(2026, 10, 26, 9, 2), correct: false),
        _r(DateTime(2026, 10, 26, 9, 3)),
      ], now: now)!;
      expect(e.questionsCompleted, 4);
      expect(e.minutesStudied, 4);
      expect(e.accuracyRate, 0.75);
      expect(e.efficiencyScore, closeTo((3 / 4) * 0.75, 1e-9));
    });
  });

  group('trendsFromHistory', () {
    List<ProgressRecord> run(List<bool> results, {String level = 'LEVEL_2'}) => [
          for (var i = 0; i < results.length; i++)
            _r(DateTime(2026, 10, 1).add(Duration(minutes: i)),
                correct: results[i], level: level),
        ];

    test('解答が少ない級は出さない', () {
      expect(
          trendsFromHistory(run([true, false, true]), nameOf: (id) => id),
          isEmpty);
    });

    test('後半の正答率が高ければ up', () {
      final t = trendsFromHistory(
          run([false, false, false, true, true, true]),
          nameOf: (id) => '名:$id');
      expect(t.single.category, '名:LEVEL_2');
      expect(t.single.trend, 'up');
      expect(t.single.trendData.first, 0.0);
      expect(t.single.trendData.last, 1.0);
    });

    test('後半の正答率が低ければ down', () {
      final t = trendsFromHistory(
          run([true, true, true, false, false, false]),
          nameOf: (id) => id);
      expect(t.single.trend, 'down');
    });

    test('ほぼ同じなら stable', () {
      final t = trendsFromHistory(
          run([true, false, true, true, false, true]), nameOf: (id) => id);
      expect(t.single.trend, 'stable');
    });

    test('10問以上は5区間に分ける', () {
      final t = trendsFromHistory(run(List.filled(10, true)), nameOf: (id) => id);
      expect(t.single.trendData.length, 5);
    });
  });
}
