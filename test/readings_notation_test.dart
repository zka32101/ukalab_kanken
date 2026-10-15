import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_info_data.dart';
import 'package:kanken/data/level_kanji_data.dart';

/// readings の表記規約(全級: 10級〜1級)。
/// 音読みはカタカナ、訓読みはひらがな(送り仮名は「た（べる）」のように全角括弧)。
String _fold(String s) => String.fromCharCodes(s.runes.map((c) => c >= 0x30A1 && c <= 0x30F6 ? c - 0x60 : c));

void main() {
  const levels = [
    'LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5',
    'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1',
  ];
  final onYomi = RegExp(r'^[ァ-ヶー]+$');
  final kunYomi = RegExp(r'^[ぁ-ゟ]+(（[ぁ-ゟ]+）)?$');
  final forbidden = RegExp(r'[\s　()（）・、。,.，]|[｡-ﾟ]');
  final all = <String, String>{
    for (final l in levels) for (final k in LevelKanjiData.forLevel(l)) k: l,
  };

  test('全級の字に読みがあり、読みは音(カタカナ)か訓(ひらがな+全角括弧)の形', () {
    expect(all.length, greaterThan(5800));
    for (final e in all.entries) {
      final info = KanjiInfoData.get(e.key);
      expect(info, isNotNull, reason: '${e.value} ${e.key}');
      expect(info!.readings, isNotEmpty, reason: e.key);
      for (final r in info.readings) {
        expect(onYomi.hasMatch(r) || kunYomi.hasMatch(r), isTrue,
            reason: '${e.key}: 「$r」');
      }
    }
  });

  test('括弧の外側(語幹・音読み)に禁止文字(空白・半角カナ・句読点・半角括弧)が無い', () {
    for (final e in all.entries) {
      for (final r in KanjiInfoData.get(e.key)!.readings) {
        final body = r.replaceAll('（', '').replaceAll('）', '');
        expect(forbidden.hasMatch(body), isFalse, reason: '${e.key}: 「$r」');
      }
    }
  });

  test('読みの重複が無い(ひらがな/カタカナの違いだけの重複も不可)', () {
    for (final e in all.entries) {
      final rs = KanjiInfoData.get(e.key)!.readings;
      expect(rs.toSet().length, rs.length, reason: e.key);
      final folded = rs.map(_fold).toList();
      expect(folded.toSet().length, folded.length, reason: '${e.key}: $rs');
    }
  });

  test('修正した読み(気=き・町=ちょう の重複削除、便=ビン)', () {
    expect(KanjiInfoData.get('気')!.readings, ['キ', 'ケ']);
    expect(KanjiInfoData.get('町')!.readings, ['チョウ', 'まち']);
    expect(KanjiInfoData.get('便')!.readings, ['ベン', 'ビン', 'たよ（り）']);
  });
}
