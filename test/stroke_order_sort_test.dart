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

  test('並びは毎回同じ（同じ画数は読み順で決まる）', () {
    for (final level in levels) {
      expect(strokeOrderKanjiForLevel(level), strokeOrderKanjiForLevel(level));
    }
  });

  test('10級の先頭は画数の少ない漢字（一・二・十・人 など）で、最後は画数の多い漢字', () {
    final l = strokeOrderKanjiForLevel('LEVEL_10');
    expect(strokeCountOf(l.first), 1);
    expect(strokeCountOf(l.first)!, lessThan(strokeCountOf(l.last)!));
    expect(l.take(3).every((k) => strokeCountOf(k)! <= 2), isTrue);
  });

  test('sortByStrokeCount: 画数が分からない漢字は最後。同じ画数は読み順', () {
    final r = sortByStrokeCount(['三', '〓', '一', '二', '十']);
    expect(r, ['一', '十', '二', '三', '〓']);
  });

  test('sortByStrokeCount: 2画は読み順（きゅう・しち・じゅう・じん・に・にゅう・はち・りょく）', () {
    final r = sortByStrokeCount(['人', '七', '九', '二', '十', '入', '力', '八']);
    expect(r, ['九', '七', '十', '人', '二', '入', '八', '力']);
  });
}
