import 'kanji_info_data.dart';
import 'level_kanji_data.dart';

/// 送りがなの演習（漢検の「送りがな」。8級〜2級で出題）の1問分の元データ。
///
/// 漢検の例題（受検級の目安チェック）と同じ形で、正しい送りがな（例: 美しい）に、送りがなを
/// 足しすぎた形（美くしい）を2つ並べて選ばせる。
class OkuriganaItem {
  final String kanji;

  /// 読みのうち、漢字だけで読む部分（例: 美しい → うつく）。
  final String stem;

  /// 送りがな（例: しい）。
  final String okuri;

  /// この字の級（例: 'LEVEL_5'）。この級以下の演習で出す。
  final String level;

  /// 正しい形の後ろから足した、誤った形2つ（例: 美くしい・美つくしい）。
  final List<String> wrong;

  const OkuriganaItem({
    required this.kanji,
    required this.stem,
    required this.okuri,
    required this.level,
    required this.wrong,
  });

  String get word => '$kanji$okuri';
  String get reading => '$stem$okuri';
}

/// 「許容」（本則とは別に認められる形）がある語。本則との違いが紛らわしいので出題しない
/// （行う／行なう、表す／表わす など。内閣告示「送り仮名の付け方」の通則1の許容）。
const Set<String> kOkuriganaAmbiguousWords = {
  '行う', '表す', '著す', '現れる', '断る', '賜る', //
};

String _toHiragana(String s) => String.fromCharCodes([
      for (final c in s.runes) c >= 0x30A1 && c <= 0x30F6 ? c - 0x60 : c,
    ]);

final RegExp _kunReading = RegExp(r'^([ぁ-ゖー]+)（([ぁ-ゖー]+)）$');

const List<String> _levelsInOrder = [
  'LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6',
  'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2',
];

List<OkuriganaItem>? _cache;

/// 漢字の読み・用例のデータ（KanjiInfoData）から作る、送りがなの問題の元データ全体。
///
/// 次の条件を満たす「漢字1字＋送りがな」の語だけを入れる。
///  ・読みに「うつく（しい）」の形（漢字だけで読む部分＋括弧の送りがな）があり、用例に
///    「美しい（うつくしい）」がそのまま載っている語
///  ・漢字だけで読む部分が2音以上（足しすぎた形を2つ作るため）で、促音（っ）で終わらない
///  ・同じ読み（stem＋okuri）が別の字にもない（暑い／熱い／厚い のように、読みだけでは
///    漢字が決まらない語を除く）。同じ語に読みが複数ある語（辛い＝からい／つらい）も除く
///  ・数え方の「つ」「か」でない
///  ・許容のある語（[kOkuriganaAmbiguousWords]）でない
List<OkuriganaItem> get kOkurigana => _cache ??= _build();

List<OkuriganaItem> _build() {
  final candidates = <({String kanji, String stem, String okuri, String level})>[];
  for (final level in _levelsInOrder) {
    for (final k in LevelKanjiData.forLevel(level)) {
      final info = KanjiInfoData.get(k);
      if (info == null) continue;
      for (final r in info.readings) {
        final m = _kunReading.firstMatch(_toHiragana(r));
        if (m == null) continue;
        final stem = m.group(1)!;
        final okuri = m.group(2)!;
        if (!info.examples.contains('$k$okuri（$stem$okuri）')) continue;
        candidates.add((kanji: k, stem: stem, okuri: okuri, level: level));
      }
    }
  }
  final readingCount = <String, int>{};
  final wordCount = <String, int>{};
  for (final c in candidates) {
    readingCount.update('${c.stem}${c.okuri}', (n) => n + 1, ifAbsent: () => 1);
    wordCount.update('${c.kanji}${c.okuri}', (n) => n + 1, ifAbsent: () => 1);
  }
  return [
    for (final c in candidates)
      if (readingCount['${c.stem}${c.okuri}'] == 1 &&
          wordCount['${c.kanji}${c.okuri}'] == 1 &&
          c.stem.runes.length >= 2 &&
          !c.stem.endsWith('っ') &&
          c.okuri != 'つ' &&
          c.okuri != 'か' &&
          !kOkuriganaAmbiguousWords.contains('${c.kanji}${c.okuri}'))
        OkuriganaItem(
          kanji: c.kanji,
          stem: c.stem,
          okuri: c.okuri,
          level: c.level,
          wrong: _wrongForms(c.kanji, c.stem, c.okuri),
        ),
  ];
}

/// 正しい形の、送りがなを足しすぎた形2つ（読みの後ろ1音・2音を送りがなの前に足す）。
List<String> _wrongForms(String kanji, String stem, String okuri) {
  final chars = stem.runes.map(String.fromCharCode).toList();
  final last1 = chars.last;
  final last2 = chars.sublist(chars.length - 2).join();
  return ['$kanji$last1$okuri', '$kanji$last2$okuri'];
}
