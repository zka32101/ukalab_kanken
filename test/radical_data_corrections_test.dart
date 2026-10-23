import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_radical_data.dart';

/// 部首データの点検で見つけた誤りの修正（部首の字と名前の食い違い・名前の不統一）。
void main() {
  test('夏の部首は「すいにょう」の字（夊 U+590A）。「ふゆがしら」の夂（U+5902）ではない', () {
    final r = KanjiRadicalData.get('夏')!;
    expect(r.radicalName, 'すいにょう');
    expect(r.radical.runes.single, 0x590A);
    // 変・処は「ふゆがしら」の夂
    expect(KanjiRadicalData.get('変')!.radical.runes.single, 0x5902);
    expect(KanjiRadicalData.get('変')!.radicalName, 'ふゆがしら');
  });

  test('服の月は「つきへん」。胃・背・育の月は「にくづき」で、名前をそろえる', () {
    expect(KanjiRadicalData.get('服')!.radicalName, 'つきへん');
    for (final k in ['胃', '背', '育', '能', '脈']) {
      expect(KanjiRadicalData.get(k)!.radicalName, 'にくづき', reason: k);
    }
  });

  test('すいにょう（夊）と ふゆがしら（夂）は、名前と字が1対1で対応する', () {
    for (final k in ['夏', '変', '処']) {
      final r = KanjiRadicalData.get(k)!;
      final isSui = r.radical.runes.single == 0x590A;
      expect(r.radicalName, isSui ? 'すいにょう' : 'ふゆがしら', reason: k);
    }
  });
}
