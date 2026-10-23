import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/screens/stroke_order_screen.dart';

/// 「漢字の学習」（書く練習の入口）の漢字は、画数の少ない漢字から順に並ぶ。
void main() {
  const levels = [
    'LEVEL_10',
    'LEVEL_9',
    'LEVEL_8',
    'LEVEL_7',
    'LEVEL_6',
    'LEVEL_5',
  ];

  test('どの級の一覧も、画数が少ない順（同じ画数も含めて、後ろほど画数が小さくならない）', () {
    for (final level in levels) {
      final counts = [
        for (final k in strokeOrderKanjiForLevel(level)) strokeCountOf(k)!,
      ];
      for (var i = 1; i < counts.length; i++) {
        expect(
          counts[i],
          greaterThanOrEqualTo(counts[i - 1]),
          reason: '$level の $i 番目',
        );
      }
    }
  });

  test('並べ替えても、漢字の顔ぶれは変わらない（配当漢字がすべて出る）', () {
    for (final level in levels) {
      expect(
        strokeOrderKanjiForLevel(level).toSet(),
        LevelKanjiData.forLevel(level).toSet(),
        reason: level,
      );
    }
  });

  test('同じ画数の漢字は、配当表の順のまま（並びが毎回同じ）', () {
    for (final level in levels) {
      final original = LevelKanjiData.forLevel(level);
      final sorted = strokeOrderKanjiForLevel(level);
      for (var i = 1; i < sorted.length; i++) {
        if (strokeCountOf(sorted[i])! == strokeCountOf(sorted[i - 1])!) {
          expect(
            original.indexOf(sorted[i]),
            greaterThan(original.indexOf(sorted[i - 1])),
            reason: level,
          );
        }
      }
      expect(strokeOrderKanjiForLevel(level), sorted);
    }
  });

  test('10級の先頭は画数の少ない漢字（一・二・十・人 など）で、最後は画数の多い漢字', () {
    final l = strokeOrderKanjiForLevel('LEVEL_10');
    expect(strokeCountOf(l.first), 1);
    expect(strokeCountOf(l.first)!, lessThan(strokeCountOf(l.last)!));
    expect(l.take(3).every((k) => strokeCountOf(k)! <= 2), isTrue);
  });

  test('sortByStrokeCount: 画数が分からない漢字は最後。同じ画数は元の順', () {
    final r = sortByStrokeCount(['三', '〓', '一', '二', '十']);
    expect(r, ['一', '二', '十', '三', '〓']);
  });
}
