import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_stroke_count_data.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/data/stroke_order_sample_data.dart';
import 'package:kanken/screens/stroke_order_screen.dart';

/// 「漢字の学習」は選んだ級の漢字だけを出す（下の級・上の級を混ぜない）。
void main() {
  const levels = [
    'LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3',
    'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1',
  ];

  test('どの級の一覧も、その級の配当漢字の部分集合（他の級の字を含まない）', () {
    for (final level in levels) {
      final own = LevelKanjiData.forLevel(level).toSet();
      final shown = strokeOrderKanjiForLevel(level);
      expect(shown.toSet().difference(own), isEmpty, reason: level);
      expect(shown.toSet().length, shown.length, reason: '$level に重複');
    }
  });

  test('10級〜2級は配当漢字がすべて出る', () {
    for (final level in levels.take(10)) {
      expect(strokeOrderKanjiForLevel(level).length,
          LevelKanjiData.forLevel(level).length, reason: level);
    }
  });

  test('書き順データの無い級(準1級・1級)は他の級の漢字で埋めず、空になる', () {
    for (final level in ['LEVEL_1_PRE', 'LEVEL_1']) {
      expect(strokeOrderKanjiForLevel(level), isEmpty, reason: level);
    }
    expect(strokeOrderKanjiForLevel('LEVEL_10'), isNot(contains('園')));
  });

  test('4級〜2級の書き順は画数の一覧と一致する（画数が分かる字）', () {
    for (final level in ['LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) {
      for (final k in strokeOrderKanjiForLevel(level)) {
        final expected = kanjiStrokeCount(k);
        if (expected == null) continue;
        expect(StrokeOrderSampleData.getStrokeOrder(k)!.strokeCount, expected,
            reason: '$level $k');
      }
    }
  });
}
