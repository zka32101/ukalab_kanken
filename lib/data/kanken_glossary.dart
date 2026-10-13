import 'package:ukalab_core/ukalab_core.dart'
    show ChapterReading, QuestionSource, Term;

import 'compound_structure_data.dart';
import 'kanji_info_data.dart';
import 'kanji_radical_data.dart';

/// 用語集の分野ID。
const String kGlossaryRadical = 'radical';
const String kGlossaryCompound = 'compound';
const String kGlossaryReading = 'reading';

/// 用語集の分野（表示順）。
const Map<String, String> kGlossarySubjects = {
  kGlossaryRadical: '部首',
  kGlossaryCompound: '熟語・用例',
  kGlossaryReading: '読み物の用語',
};

const String _examId = 'kanken';
const String _contentVer = '1';

/// 部首1つにつき、説明に載せる漢字の例の上限。
const int kRadicalExampleLimit = 8;

/// 用例1つにつき、説明に載せる元の漢字の上限。
const int kCompoundOriginLimit = 4;

/// 部首の用語（termId は `radical:<部首文字>`）。
/// 部首名と例の漢字は kanji_radical_data.dart にある内容だけを使う。
List<Term> buildRadicalTerms() {
  final names = <String, List<String>>{};
  final kanjiOf = <String, List<String>>{};
  for (final e in KanjiRadicalData.entries) {
    final r = e.value.radical;
    final n = names.putIfAbsent(r, () => []);
    if (!n.contains(e.value.radicalName)) n.add(e.value.radicalName);
    kanjiOf.putIfAbsent(r, () => []).add(e.key);
  }
  return [
    for (final r in names.keys)
      () {
        final nameText = names[r]!.map((n) => '「$n」').join('');
        final list = kanjiOf[r]!;
        final shown = list.take(kRadicalExampleLimit).join('・');
        final rest = list.length - kRadicalExampleLimit;
        return Term(
          termId: 'radical:$r',
          examId: _examId,
          subjectId: kGlossaryRadical,
          term: r,
          headline: '部首の「$r」。よび名は$nameText。',
          definition: 'よび名: ${names[r]!.join('・')}\n'
              'この部首をもつ漢字の例: $shown${rest > 0 ? '　ほか$rest字' : ''}',
          source: QuestionSource.original,
          sourceRef: 'アプリ内の部首データ（kanji_radical_data.dart）から生成',
          contentVer: _contentVer,
        );
      }(),
  ];
}

final RegExp _exampleRe = RegExp(r'^([^（）]+)（([^（）]+)）$');
final RegExp _jukugoRe = RegExp(r'^[一-鿿々〆]{2,}$');

/// 熟語・用例の用語（termId は `compound:<熟語>`）。
/// 漢字ごとの用例のうち漢字だけでできた語（送り仮名つきを除く）と、
/// 熟語の構成問題の熟語を集める。説明は読み・元の漢字・構成の種類だけ。
List<Term> buildCompoundTerms() {
  final readingOf = <String, String>{};
  final origins = <String, List<String>>{};
  for (final e in KanjiInfoData.entries) {
    for (final ex in e.value.examples) {
      final m = _exampleRe.firstMatch(ex);
      if (m == null) continue;
      final word = m.group(1)!;
      if (!_jukugoRe.hasMatch(word)) continue;
      readingOf.putIfAbsent(word, () => m.group(2)!);
      final o = origins.putIfAbsent(word, () => []);
      if (!o.contains(e.key)) o.add(e.key);
    }
  }
  final structure = <String, CompoundQuestion>{};
  for (final q in CompoundStructureData.all) {
    structure.putIfAbsent(q.jukugo, () => q);
    readingOf.putIfAbsent(q.jukugo, () => q.reading);
  }
  return [
    for (final w in readingOf.keys)
      () {
        final lines = <String>['読み: ${readingOf[w]}'];
        final o = origins[w];
        if (o != null) {
          final shown = o.take(kCompoundOriginLimit).map((k) => '「$k」').join('');
          lines.add('用例にのっている漢字: $shown');
        }
        final s = structure[w];
        if (s != null) lines.add('熟語の成り立ち: ${s.correctLabel}');
        return Term(
          termId: 'compound:$w',
          examId: _examId,
          subjectId: kGlossaryCompound,
          term: w,
          headline: '読みは「${readingOf[w]}」。',
          definition: lines.join('\n'),
          source: QuestionSource.original,
          sourceRef: 'アプリ内の漢字データ（kanji_info_data.dart / '
              'compound_structure_data.dart）から生成',
          contentVer: _contentVer,
        );
      }(),
  ];
}

/// 読み物の用語。自動での語の切り出しはせず、読み物の節の見出しだけを
/// 用語として使う（termId は `reading:<読み物ID>:<節の番号>`、説明は節の本文）。
List<Term> buildReadingTerms(List<ChapterReading> readings) {
  return [
    for (final r in readings)
      if (!r.disabled)
        for (var i = 0; i < r.sections.length; i++)
          Term(
            termId: 'reading:${r.readingId}:${i + 1}',
            examId: _examId,
            subjectId: kGlossaryReading,
            term: r.sections[i].heading,
            headline: '「${r.title.replaceFirst(RegExp(r'^\d+\s*'), '')}」の話',
            definition: r.sections[i].body,
            source: r.source,
            sourceRef: r.sourceRef,
            contentVer: r.contentVer,
          ),
  ];
}

/// 用語集に出すすべての用語（部首 → 熟語・用例 → 読み物の順）。
List<Term> buildKankenGlossary(List<ChapterReading> readings) => [
      ...buildRadicalTerms(),
      ...buildCompoundTerms(),
      ...buildReadingTerms(readings),
    ];
