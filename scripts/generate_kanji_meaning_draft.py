#!/usr/bin/env python3
"""漢字の「意味」下書きデータ(Dart)と要確認一覧(md)を生成する。

重要: 意味の文はすべて AI(Claude)が自分の言葉で下書きしたもの。公的データでも
検定協会の公式でもない。辞書・参考書・Wikipedia 等の文章は転載・要約していない。
人の確認が済むまで本番画面には出さない(kKanjiMeaningVisible = false)。

使い方:
  python3 -I scripts/generate_kanji_meaning_draft.py

入力:  scripts/data/kanji_meaning_draft_source.tsv  (字 / reviewStatus / 意味)
出力:  lib/data/kanji_meaning_draft_data.dart
       docs/data_verification/meaning_review.md
reviewStatus: draft=AIの下書き(未確認) / needsReview=疑わしい・多義(要確認) /
              blank=確信が持てず意味を入れていない(Dartには出さず、一覧にだけ載せる)
"""
import re

SRC = 'scripts/data/kanji_meaning_draft_source.tsv'
DART = 'lib/data/kanji_meaning_draft_data.dart'
REVIEW = 'docs/data_verification/meaning_review.md'


def level_of():
    src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
    out = {}
    for m in re.finditer(r"'LEVEL_(\d+)':\s*'([^']*)'", src):
        for c in m.group(2):
            out[c] = m.group(1)
    return out


def main():
    lv = level_of()
    rows = []
    for line in open(SRC, encoding='utf-8'):
        if line.startswith('#') or not line.strip():
            continue
        k, st, m = line.rstrip('\n').split('\t')
        assert k in lv and lv[k] in '10 9 8 7 6 5'.split(), k
        rows.append((k, st, m))
    assert len({r[0] for r in rows}) == len(rows) == 1026
    with open(DART, 'w', encoding='utf-8') as f:
        f.write('// GENERATED FILE - do not edit by hand. Run scripts/generate_kanji_meaning_draft.py.\n')
        f.write('//\n// 漢字の「意味」の下書き(10級〜5級の1,026字のうち意味を入れた字)。\n')
        f.write('// 【重要】この意味は AI(Claude)が自分の言葉で書いた下書きで、公的データでも検定協会の\n')
        f.write('// 公式でもない。人(漢検の指導者等)の確認が済むまで本番画面には出さない。\n')
        f.write('// 辞書・参考書等の文章は転載していない。入力元: scripts/data/kanji_meaning_draft_source.tsv\n')
        f.write('// 意味を入れていない字・要確認の字: docs/data_verification/meaning_review.md\n\n')
        f.write('/// 意味(AI下書き)を画面に出すか。人の確認が済むまで false のまま。\n')
        f.write('const bool kKanjiMeaningVisible = false;\n\n')
        f.write('/// draft = AIの下書き(未確認) / needsReview = 疑わしい・多義で要確認。\n')
        f.write('enum KanjiMeaningReviewStatus { draft, needsReview }\n\n')
        f.write('class KanjiMeaningDraft {\n  final String meaning;\n  final KanjiMeaningReviewStatus reviewStatus;\n')
        f.write('  const KanjiMeaningDraft(this.meaning, this.reviewStatus);\n}\n\n')
        f.write('/// 意味の下書き。無い字(意味を入れていない字・対象外の級)は null。\n')
        f.write('String? kanjiMeaningDraft(String kanji) => kKanjiMeaningDraft[kanji]?.meaning;\n\n')
        f.write('KanjiMeaningDraft? kanjiMeaningDraftEntry(String kanji) => kKanjiMeaningDraft[kanji];\n\n')
        f.write('const Map<String, KanjiMeaningDraft> kKanjiMeaningDraft = {\n')
        for k, st, m in rows:
            if st == 'blank':
                continue
            assert m and "'" not in m and '$' not in m and '\\' not in m, k
            e = 'draft' if st == 'draft' else 'needsReview'
            f.write(f"  '{k}': KanjiMeaningDraft('{m}', KanjiMeaningReviewStatus.{e}),\n")
        f.write('};\n')
    n = {s: sum(1 for r in rows if r[1] == s) for s in ('draft', 'needsReview', 'blank')}
    with open(REVIEW, 'w', encoding='utf-8') as f:
        f.write('# 漢字の意味(AI下書き)の要確認一覧\n\n')
        f.write('**この意味は AI(Claude)が書いた下書きです。公的データ・検定協会の公式ではありません。** ')
        f.write('人(漢検の指導者等)の確認が済むまで本番画面には出しません(`kKanjiMeaningVisible = false`)。\n\n')
        f.write('対象は10級〜5級の1,026字。辞書・参考書等の文章は転載せず、短い自作の言い換えで書いています。\n')
        f.write('この一覧は `scripts/generate_kanji_meaning_draft.py` が `scripts/data/kanji_meaning_draft_source.tsv` から生成します。\n\n')
        f.write(f'| 区分 | 字数 |\n|---|---|\n| draft(意味あり・未確認) | {n["draft"]} |\n')
        f.write(f'| needsReview(意味あり・疑わしい/多義) | {n["needsReview"]} |\n| 意味なし(確信が持てず空欄) | {n["blank"]} |\n')
        f.write(f'| 計 | {len(rows)} |\n\n')
        f.write('## 意味なし(空欄)\n\n| 級 | 字 | 理由 |\n|---|---|---|\n')
        for k, st, m in rows:
            if st == 'blank':
                f.write(f'| {lv[k]} | {k} | {m} |\n')
        f.write('\n## needsReview(意味は入っているが要確認)\n\n| 級 | 字 | 現在の下書き |\n|---|---|---|\n')
        for k, st, m in rows:
            if st == 'needsReview':
                f.write(f'| {lv[k]} | {k} | {m} |\n')
    print(n)


main()
