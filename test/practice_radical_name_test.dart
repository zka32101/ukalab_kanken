import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_radical_data.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 漢検の「部首・部首名」のうち、部首名（きへん・さんずい など）の演習。
void main() {
  test('部首名は8級〜2級に出る（公式の出題内容）。9級以下・準1級・1級には出さない', () {
    for (final l in ['LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) {
      expect(availableModesForLevel(l), contains(PracticeMode.radicalName), reason: l);
    }
    for (final l in ['LEVEL_10', 'LEVEL_9', 'LEVEL_1_PRE', 'LEVEL_1']) {
      expect(availableModesForLevel(l), isNot(contains(PracticeMode.radicalName)), reason: l);
    }
  });

  test('すべての漢字で、部首名の選択肢が作れる（4つ・正解を含む・重複なし）', () {
    final random = Random(5);
    for (final e in KanjiRadicalData.allEntries) {
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
    for (final e in KanjiRadicalData.allEntries) {
      nameToRadicals.putIfAbsent(e.value.radicalName, () => {}).add(e.value.radical);
    }
    for (final e in KanjiRadicalData.allEntries) {
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

  test('4級〜2級の字でも、部首名・部首の選択肢が作れる（書き取りに回らない）', () {
    final random = Random(8);
    for (final l in ['LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) {
      for (final k in LevelKanjiData.forLevel(l)) {
        final info = KanjiRadicalData.get(k);
        final ch = radicalNameChoices(k, random);
        if (info == null) {
          expect(ch, isNull, reason: '$l $k（確信が持てず除外した字は、部首名の問題を作らない）');
          continue;
        }
        expect(ch, isNotNull, reason: '$l $k');
        expect(ch!.length, 4, reason: '$l $k');
        expect(ch, contains(info.radicalName), reason: '$l $k');
      }
    }
  });

  test('データに無い字は選択肢を作らない（書き取りに回る）', () {
    expect(radicalNameChoices('〓', Random(1)), isNull);
  });
}
