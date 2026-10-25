import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/bundled_questions.dart';
import 'package:kanken/data/kanji_radical_data.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 選択肢のバランス（正解の位置が偏らない）と、間違えやすさ（形が似た字・同じ種類の部首名）の点検。
void main() {
  late List<dynamic> seeds;

  setUpAll(() async {
    final b = BundledQuestions(loader: () async => File('assets/questions/kanken_questions.json').readAsString());
    seeds = (await b.forLevel('LEVEL_2')).take(60).toList();
  });

  /// 4択のとき、正解が出る位置の割合（%）。
  List<int> positionShare(PracticeMode mode, String level, {int reps = 20}) {
    final pos = List<int>.filled(4, 0);
    var n = 0;
    for (var i = 0; i < reps; i++) {
      for (final q in buildKanjiPracticeQuestions(List.from(seeds), mode, level)) {
        if (q.actualMode != mode || q.choices.length != 4) continue;
        n++;
        final k = q.choices.indexOf(q.correctAnswer);
        if (k >= 0) pos[k]++;
      }
    }
    expect(n, greaterThan(100), reason: '$mode');
    return [for (final p in pos) (p * 100 / n).round()];
  }

  test('画数の選択肢: 4つの連続した数・正解を含む・1画以上', () {
    final random = Random(1);
    for (var count = 1; count <= 30; count++) {
      for (var i = 0; i < 20; i++) {
        final c = strokeCountChoices(count, random);
        expect(c.length, 4);
        expect(c, contains(count));
        expect(c.first, greaterThanOrEqualTo(1));
        for (var j = 1; j < 4; j++) {
          expect(c[j], c[j - 1] + 1);
        }
      }
    }
  });

  test('画数: 正解の位置が毎回同じにならない（以前は必ず2番目だった）', () {
    final share = positionShare(PracticeMode.strokeCount, 'LEVEL_5');
    for (final s in share) {
      expect(s, inInclusiveRange(10, 40), reason: '$share');
    }
  });

  for (final c in [
    (PracticeMode.writing, 'LEVEL_5'),
    (PracticeMode.reading, 'LEVEL_5'),
    (PracticeMode.wordReading, 'LEVEL_5'),
    (PracticeMode.wordWriting, 'LEVEL_5'),
    (PracticeMode.radicalName, 'LEVEL_5'),
    (PracticeMode.yoji, 'LEVEL_5'),
    (PracticeMode.antonym, 'LEVEL_5'),
    (PracticeMode.koji, 'LEVEL_1'),
  ]) {
    test('${c.$1.name} ${c.$2}: 正解の位置が偏らない', () {
      final share = positionShare(c.$1, c.$2);
      for (final s in share) {
        expect(s, inInclusiveRange(15, 35), reason: '${c.$1} $share');
      }
    });
  }

  test('空欄の問題: 誤答の多くに、正解と同じ部首の字（形が似た字）が入る', () {
    var distractors = 0, same = 0;
    for (var i = 0; i < 20; i++) {
      for (final q in buildKanjiPracticeQuestions(List.from(seeds), PracticeMode.yoji, 'LEVEL_5')) {
        if (q.actualMode != PracticeMode.yoji) continue;
        final r = KanjiRadicalData.get(q.correctAnswer)?.radical;
        if (r == null) continue;
        for (final ch in q.choices) {
          if (ch == q.correctAnswer) continue;
          distractors++;
          if (KanjiRadicalData.get(ch)?.radical == r) same++;
        }
      }
    }
    expect(distractors, greaterThan(200));
    expect(same * 100 / distractors, greaterThan(30));
  });

  test('書き取り: 誤答に形が似た字が入り、正解と同じ読みの字は入らない', () {
    var distractors = 0, same = 0;
    for (var i = 0; i < 20; i++) {
      for (final q in buildKanjiPracticeQuestions(List.from(seeds), PracticeMode.writing, 'LEVEL_5')) {
        if (q.actualMode != PracticeMode.writing || q.choices.length != 4) continue;
        expect(q.choices.toSet().length, 4, reason: '${q.choices}');
        expect(q.choices, contains(q.correctAnswer));
        final r = KanjiRadicalData.get(q.correctAnswer)?.radical;
        if (r == null) continue;
        for (final ch in q.choices) {
          if (ch == q.correctAnswer) continue;
          distractors++;
          if (KanjiRadicalData.get(ch)?.radical == r) same++;
        }
      }
    }
    expect(distractors, greaterThan(200));
    expect(same * 100 / distractors, greaterThan(30));
  });

  test('部首名: 正解と同じ種類の呼び名（〜へん など）が誤答に入る', () {
    final random = Random(2);
    // 「きへん」「てへん」の字なら、〜へん の呼び名が誤答に2つ以上入る（候補が足りる限り）。
    for (final k in ['校', '植', '持']) {
      final choices = radicalNameChoices(k, random);
      expect(choices, isNotNull, reason: k);
      final answer = KanjiRadicalData.get(k)!.radicalName;
      expect(answer.endsWith('へん'), isTrue, reason: '$k $answer');
      final hen = choices!.where((c) => c != answer && c.endsWith('へん')).length;
      expect(hen, greaterThanOrEqualTo(2), reason: '$k $choices');
    }
  });
}
