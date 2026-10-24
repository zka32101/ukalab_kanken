import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_stroke_count_data.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/data/stroke_order_sample_data.dart';

/// 画数データ（KANJIDIC2 由来）の検査。
/// 画数が無い字・複数値の字は docs/data_verification/stroke_count_review.md に
/// 列挙してあり、データ側は未設定（null）のままにしている。
void main() {
  const levels = [
    'LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5',
    'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1',
  ];
  final allKanji = [for (final l in levels) ...LevelKanjiData.forLevel(l)];

  // 要確認一覧の表（| 級 | 字 | ...）から字を取り出す。
  final reviewKanji = <String>{};
  final row = RegExp(r'^\| (?:\d+|\d_PRE) \| (\S+) \|');
  for (final line in File('docs/data_verification/stroke_count_review.md').readAsLinesSync()) {
    final m = row.firstMatch(line);
    if (m != null) reviewKanji.add(m.group(1)!);
  }

  test('全12区分の配当漢字は計5,874字', () {
    expect(allKanji.length, 5874);
    expect(allKanji.toSet().length, 5874);
  });

  test('画数は1〜33の範囲（最大は麤の33画。30画超は麤だけ）', () {
    expect(kKanjiStrokeCount, isNotEmpty);
    for (final e in kKanjiStrokeCount.entries) {
      expect(e.value, inInclusiveRange(1, 33), reason: e.key);
    }
  });

  test('代表字の画数', () {
    expect(kanjiStrokeCount('一'), 1);
    expect(kanjiStrokeCount('草'), 9);
    expect(kanjiStrokeCount('慣'), 14);
    expect(kanjiStrokeCount('鬱'), 29);
    expect(kanjiStrokeCount('麤'), 33);
    expect(kKanjiStrokeCount.entries.where((e) => e.value > 30).map((e) => e.key), ['麤']);
    expect(kanjiStrokeCount('配当表にない字Z'), isNull);
  });

  test('未設定の字は要確認一覧と一致する（自動で入れていない）', () {
    final unset = allKanji.where((k) => kanjiStrokeCount(k) == null).toSet();
    expect(unset, reviewKanji);
    expect(unset.length, 328); // 画数なし25 + 複数値303
    expect(kKanjiStrokeCount.length, 5546);
    expect(kKanjiStrokeCount.length + unset.length, allKanji.length);
  });

  test('画数データは配当漢字以外を含まない', () {
    final set = allKanji.toSet();
    for (final k in kKanjiStrokeCount.keys) {
      expect(set.contains(k), isTrue, reason: k);
    }
  });

  test('書き順データ（KanjiVG）の線数と、画数データが食い違う字は無い（慣=14線=14画）', () {
    final mismatched = <String>[];
    for (final k in StrokeOrderSampleData.availableKanji) {
      final n = kanjiStrokeCount(k);
      if (n == null) continue;
      if (n != StrokeOrderSampleData.getStrokeOrder(k)!.strokeCount) mismatched.add(k);
    }
    expect(mismatched, isEmpty);
  });
}
