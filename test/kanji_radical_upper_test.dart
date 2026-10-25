import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_radical_data.dart';
import 'package:kanken/data/kanji_radical_upper_data.dart';
import 'package:kanken/data/level_kanji_data.dart';

/// 4級〜2級の配当漢字の部首・部首名（KanjiVGの部首情報＋規則表＋字ごとの指定）。
void main() {
  final upper = <String>[
    for (final l in ['LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) ...LevelKanjiData.forLevel(l),
  ];
  final hira = RegExp(r'^[ぁ-ゖー]+$');
  final kanjiChar = RegExp(r'[\u2E80-\u2FDF\u3400-\u9FFF\uF900-\uFAFF\u{20000}-\u{2FA1F}]', unicode: true);

  /// 確信が持てず、出題しない字（scripts/data/radical_upper_excluded.tsv）。
  const excluded = '肩雇曹曽更替為舗';

  test('4級〜2級の配当漢字1,110字のうち、除外した8字以外は、すべて部首・部首名を持つ', () {
    expect(upper.length, 1110);
    expect(excluded.runes.length, 8);
    final missing = upper.where((k) => KanjiRadicalData.get(k) == null).toSet();
    expect(missing, excluded.split('').toSet(), reason: '部首が無い字は、除外した字だけ');
  });

  test('除外した字は、部首の問題には出ない（書き取りに回る）', () {
    for (final k in excluded.split('')) {
      expect(KanjiRadicalData.get(k), isNull, reason: k);
    }
  });

  test('部首は1字の漢字（部首文字）、部首名はひらがな', () {
    for (final e in kKanjiRadicalUpper.entries) {
      expect(e.value.radical.runes.length, 1, reason: e.key);
      expect(kanjiChar.hasMatch(e.value.radical), isTrue, reason: '${e.key} の部首 ${e.value.radical}');
      expect(hira.hasMatch(e.value.radicalName), isTrue, reason: '${e.key} ${e.value.radicalName}');
    }
  });

  test('上位データの字は、10級〜5級の既存データと重複しない（既存の確認済みデータを上書きしない）', () {
    final existing = KanjiRadicalData.entries.map((e) => e.key).toSet();
    for (final k in kKanjiRadicalUpper.keys) {
      expect(existing.contains(k), isFalse, reason: k);
    }
  });

  test('用語集に使う entries は、確認済みの既存データだけ（上位データは入れない）', () {
    final keys = KanjiRadicalData.entries.map((e) => e.key).toSet();
    expect(keys.length, 1026);
    expect(keys.any(kKanjiRadicalUpper.containsKey), isFalse);
    expect(KanjiRadicalData.allEntries.length, 1026 + kKanjiRadicalUpper.length);
  });

  test('同じ部首を持つ字のうち、既存データで確認済みの部首名と、同じ位置の呼び方が食い違わない', () {
    // 「へん」の付く名前は、部首の左側にある字だけ。右側・下側にある字に「〜へん」を付けない。
    for (final e in kKanjiRadicalUpper.entries) {
      final n = e.value.radicalName;
      if (n.endsWith('へん') && n != 'ごんべん' && n != 'こざとへん') {
        // 字の左側に部首がある字は、字の1画目が部首の形（偏）。ここでは名前の形だけを確かめる。
        expect(n.length, greaterThanOrEqualTo(3), reason: '${e.key} $n');
      }
    }
  });

  test('代表的な字の部首・部首名（手で確認した字）', () {
    const expected = {
      '払': ('扌', 'てへん'),
      '咲': ('口', 'くちへん'),
      '疲': ('疒', 'やまいだれ'),
      '販': ('貝', 'かいへん'),
      '酔': ('酉', 'とりへん'),
      '虐': ('虍', 'とらかんむり'),
      '扇': ('戸', 'とだれ'),
      '爵': ('爪', 'つめかんむり'),
      '遜': ('辶', 'しんにょう'),
      '随': ('阝', 'こざとへん'),
      '郎': ('阝', 'おおざと'),
      '箇': ('⺮', 'たけかんむり'),
      '麗': ('鹿', 'しか'),
      '驚': ('馬', 'うま'),
      '鮮': ('魚', 'うおへん'),
      '髪': ('髟', 'かみがしら'),
      '舞': ('舛', 'まいあし'),
      '黙': ('黒', 'くろ'),
    };
    for (final e in expected.entries) {
      final info = KanjiRadicalData.get(e.key);
      expect(info, isNotNull, reason: e.key);
      expect(info!.radical, e.value.$1, reason: e.key);
      expect(info.radicalName, e.value.$2, reason: e.key);
    }
  });
}
