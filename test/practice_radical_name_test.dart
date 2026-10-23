import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_radical_data.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 漢検の「部首・部首名」のうち、部首名（きへん・さんずい など）の演習。
void main() {
  test('部首名は8級〜5級だけに出る（部首名のデータがある小学校の漢字の級）', () {
    for (final l in ['LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5']) {
      expect(availableModesForLevel(l), contains(PracticeMode.radicalName), reason: l);
    }
    for (final l in ['LEVEL_10', 'LEVEL_9', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1']) {
      expect(availableModesForLevel(l), isNot(contains(PracticeMode.radicalName)), reason: l);
    }
  });

  test('すべての漢字で、部首名の選択肢が作れる（4つ・正解を含む・重複なし）', () {
    final random = Random(5);
    for (final e in KanjiRadicalData.entries) {
      final ch = radicalNameChoices(e.key, random);
      expect(ch, isNotNull, reason: e.key);
      expect(ch!.length, 4, reason: e.key);
      expect(ch.toSet().length, 4, reason: e.key);
      expect(ch, contains(e.value.radicalName), reason: e.key);
    }
  });

  test('誤答は、別の部首の名前で、正解と前方一致しない（き／きへん のような呼び方違いを入れない）', () {
    final random = Random(11);
    final nameToRadicals = <String, Set<String>>{};
    for (final e in KanjiRadicalData.entries) {
      nameToRadicals.putIfAbsent(e.value.radicalName, () => {}).add(e.value.radical);
    }
    for (final e in KanjiRadicalData.entries) {
      final answer = e.value.radicalName;
      final ch = radicalNameChoices(e.key, random)!;
      for (final w in ch.where((w) => w != answer)) {
        expect(nameToRadicals[w]!.contains(e.value.radical), isFalse,
            reason: '${e.key}（${e.value.radical} $answer）に同じ部首の名前 $w');
        expect(w.startsWith(answer) || answer.startsWith(w), isFalse,
            reason: '${e.key}: $answer と $w');
      }
    }
  });

  test('データに無い字は選択肢を作らない（書き取りに回る）', () {
    expect(radicalNameChoices('〓', Random(1)), isNull);
  });
}
