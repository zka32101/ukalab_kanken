import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 熟語の読み・書き取り（漢検の「読み」「書き取り」の熟語）。
void main() {
  const levels = [
    'LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3',
    'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1',
  ];
  final hira = RegExp(r'^[ぁ-ゖー]+$');
  final kanjiOnly = RegExp(r'^[一-鿿]{2,4}$');

  test('データ: 熟語は漢字だけ・読みはひらがな・重複なし・数が十分', () {
    final seen = <String>{};
    for (final j in allJukugo) {
      expect(kanjiOnly.hasMatch(j.word), isTrue, reason: j.word);
      expect(hira.hasMatch(j.reading), isTrue, reason: '${j.word} ${j.reading}');
      expect(seen.add(j.word), isTrue, reason: '${j.word} が重複');
    }
    expect(allJukugo.length, greaterThan(4000));
  });

  test('その級の熟語は、その級以下の字だけでできている。上の級ほど増える', () {
    final counts = <int>[];
    for (final l in levels) {
      final pool = jukugoForLevel(l);
      counts.add(pool.length);
      final ok = <String>{
        for (final k in levels.sublist(0, levels.indexOf(l) + 1)) ...LevelKanjiData.forLevel(k),
      };
      for (final j in pool) {
        expect(ok.containsAll(j.word.split('')), isTrue, reason: '$l ${j.word}');
      }
    }
    for (var i = 1; i < counts.length; i++) {
      expect(counts[i], greaterThanOrEqualTo(counts[i - 1]));
    }
    expect(counts.first, greaterThanOrEqualTo(20), reason: '10級でも出せる');
  });

  test('全ての級で、熟語の読み・書き取りを選べる', () {
    for (final l in levels) {
      expect(availableModesForLevel(l), containsAll([PracticeMode.wordReading, PracticeMode.wordWriting]), reason: l);
    }
  });

  test('読みの選択肢: 4つ・正解を含む・重複なし。書き取りの選択肢: 同じ読みの語は入らない', () {
    final random = Random(5);
    for (final l in ['LEVEL_10', 'LEVEL_5', 'LEVEL_2', 'LEVEL_1']) {
      final pool = jukugoForLevel(l);
      for (final j in (pool.toList()..shuffle(random)).take(60)) {
        final r = jukugoReadingChoices(j, pool, random)!;
        expect(r.length, 4, reason: '$l ${j.word}');
        expect(r.toSet().length, 4, reason: '$l ${j.word}');
        expect(r, contains(j.reading), reason: '$l ${j.word}');
        final w = jukugoWritingChoices(j, pool, random)!;
        expect(w.length, 4, reason: '$l ${j.word}');
        expect(w.toSet().length, 4, reason: '$l ${j.word}');
        expect(w, contains(j.word), reason: '$l ${j.word}');
        for (final c in w) {
          if (c == j.word) continue;
          final other = pool.firstWhere((x) => x.word == c);
          expect(other.reading, isNot(j.reading), reason: '$l ${j.word} と $c が同じ読み');
        }
      }
    }
  });
}
