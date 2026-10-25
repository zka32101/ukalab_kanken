import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_stroke_count_data.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 漢検の「筆順・画数」に合わせた、画数の演習。
void main() {
  test('画数は、漢検で出題される10級〜5級だけに出る', () {
    for (final level in ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5']) {
      expect(availableModesForLevel(level), contains(PracticeMode.strokeCount), reason: level);
    }
    for (final level in ['LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1']) {
      expect(availableModesForLevel(level), isNot(contains(PracticeMode.strokeCount)), reason: level);
    }
  });

  test('画数の選択肢: 4つ・正解を含む・重複なし・1画以上・小さい順', () {
    for (var c = 1; c <= 30; c++) {
      final ch = strokeCountChoices(c);
      expect(ch.length, 4, reason: '$c');
      expect(ch, contains(c), reason: '$c');
      expect(ch.toSet().length, 4, reason: '$c');
      expect(ch.every((x) => x >= 1), isTrue, reason: '$c');
      expect([...ch]..sort(), ch, reason: '$c');
    }
  });

  test('1画の漢字でも、選択肢が足りなくならない', () {
    expect(strokeCountChoices(1), [1, 2, 3, 4]);
    // 2画は、窓が2通り（1〜4 か 2〜5）。どちらでも、1画以上の連続した4つで、正解を含む。
    final seen = <String>{};
    for (var i = 0; i < 100; i++) {
      final c = strokeCountChoices(2);
      expect(c, contains(2));
      expect(c.first, greaterThanOrEqualTo(1));
      seen.add(c.join(','));
    }
    expect(seen, {'1,2,3,4', '2,3,4,5'});
  });

  test('10級〜5級の配当漢字は、画数が分かる字が大半（分からない字は書き取りに回る）', () {
    for (final level in ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5']) {
      final kanji = LevelKanjiData.forLevel(level);
      final known = kanji.where((k) => kanjiStrokeCount(k) != null).length;
      expect(known / kanji.length, greaterThan(0.95), reason: level);
    }
  });
}
