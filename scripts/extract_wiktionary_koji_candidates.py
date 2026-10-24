#!/usr/bin/env python3
"""ウィクショナリー(CC BY-SA 4.0)の「故事成語」から、準1級・1級の「故事・諺」向けの語彙データの「候補」を作る。

  python3 -I scripts/fetch_wiktionary_idioms.py wiktionary_idioms.json
  curl -O https://www.edrdg.org/kanjidic/kanjidic2.xml.gz && gunzip kanjidic2.xml.gz
  python3 -I scripts/extract_wiktionary_koji_candidates.py wiktionary_idioms.json kanjidic2.xml

出力:
  scripts/data/upper_koji_candidates.tsv           ... 候補（題名・種類・読み・意味・出典メモ・最難級・読みの検査）
  docs/data_verification/upper_koji_candidates.md  ... 人が確認するための一覧

そのままアプリに入れない（四字熟語の候補と同じ。extract_wiktionary_yoji_candidates.py 参照）。
読みは、題名の漢字を KANJIDIC2 の読みに、かなをそのまま読みに分けられるかで検査する。
明示された読み（題名のあとの「（…）」）は厳密に、並べ替え用の読み（濁点が付かないことがある）は
濁点の違いを許して検査する。表外の字（このアプリの配当漢字表に無い字）を含む題名は対象外。
出典: Wiktionary (CC BY-SA 4.0), KANJIDIC2 (c) EDRDG (CC BY-SA 4.0)。
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wiktionary_idiom_common import (  # noqa: E402
    KANJI, RANK_NAME, check_reading, clean_markup, glosses, kanjidic, kanji_levels, loose, unsmall)


def explicit_reading(w):
    from wiktionary_idiom_common import hira
    m = re.search(r"（([ぁ-ゟァ-ヺー・ 　]+)）", w)
    return hira(m.group(1)).replace('・', '').replace(' ', '').replace('　', '') if m else None


def sort_reading(w):
    m = (re.search(r'\{\{kana-DEFAULTSORT\|([ぁ-ゟ]+)', w) or re.search(r'DEFAULTSORT:([ぁ-ゟ]+)', w)
         or re.search(r'\{\{ja-idiom\|([ぁ-ゟ]+)', w))
    return m.group(1) if m else None


def origin_note(w):
    """出典・由来の1行目（短く）。"""
    m = re.search(r'^=+\s*(?:\{\{etym\}\}|由来|出典|語源)\s*=+\s*\n+(.+)$', w, re.M)
    if not m:
        return ''
    return clean_markup(m.group(1))[:70]


def main():
    wikt = json.load(open(sys.argv[1], encoding='utf-8'))
    kd = kanjidic(sys.argv[2])
    kl = kanji_levels()

    rows, skipped = [], 0
    for title, w in wikt['koji'].items():
        kanji = [c for c in title if KANJI.match(c)]
        if not kanji or any(c not in kl for c in kanji):
            skipped += 1
            continue
        hardest = min(kl[c] for c in kanji)
        if len(title) == 4 and len(kanji) == 4:
            kind = '四字熟語'
        elif len(title) <= 3 and len(kanji) == len(title):
            kind = '熟語（故事成語）'
        else:
            kind = '句・ことわざ'
        raw = explicit_reading(w)
        fold = unsmall
        if raw is None:
            raw, fold = sort_reading(w), loose
        reading, check = check_reading(raw, title, kd, fold)
        gl = glosses(w, 2)
        note = []
        if not gl or len(gl[0]) < 10:
            note.append('意味が短い')
        if any(title in g for g in gl):
            note.append('意味に題名そのものが入る')
        rows.append((title, kind, reading, raw or '', ' ／ '.join(gl), origin_note(w),
                     RANK_NAME.get(hardest, '3級以下'), check, '、'.join(note)))
    order = {'OK': 0}
    rows.sort(key=lambda r: (order.get(r[7], 1), r[1], r[2] or 'ん'))

    with open('scripts/data/upper_koji_candidates.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('題名\t種類\t読み(整形後)\t読み(元)\t意味(原文)\t出典メモ\t最難級\t読みの検査\t意味の印\n')
        for r in rows:
            f.write('\t'.join(x.replace('\t', ' ') for x in r) + '\n')

    ok = [r for r in rows if r[7] == 'OK']
    lines = [
        '# 準1級・1級向け 故事成語・諺の候補（確認用）',
        '',
        'ウィクショナリーの「故事成語」から取り出した候補。**そのままアプリには入れない。** 確認して、取り込む語だけ残す。',
        '',
        '- 「故事成語」のカテゴリには、四字熟語・ことわざ・ふつうの熟語が混ざっている（種類の列）。',
        '- 読み: 題名の漢字を KANJIDIC2 の読みに、かなをそのまま読みに分けられるかで検査（分けられたものは現代仮名づかいに直して「OK」）。',
        '- 意味: 原文のまま（最大2つ）。別の語の説明が混ざることがある。出典メモは、由来・出典の1行目。',
        '- 級: 題名の漢字のうち最も難しい字の級（公式の出題範囲とは一致しない）。',
        '- 表外の字（配当漢字表に無い字）を含む題名 %d 語は対象外。' % skipped,
        '- 出典: Wiktionary（日本語版）(CC BY-SA 4.0)、KANJIDIC2 (c) EDRDG (CC BY-SA 4.0)。',
        '',
        '合計 %d 語（読みの検査OK: %d、要確認: %d）' % (len(rows), len(ok), len(rows) - len(ok)),
        '',
        '| 題名 | 種類 | 読み | 検査 | 意味（原文） | 出典メモ | 印 | 級 |',
        '|---|---|---|---|---|---|---|---|',
    ]
    for t, kind, rd, raw, g, orig, lv, ck, note in rows:
        lines.append('| %s | %s | %s | %s | %s | %s | %s | %s |' % (
            t, kind, rd or '-', ck, g.replace('|', '／')[:90], orig.replace('|', '／'), note, lv))
    open('docs/data_verification/upper_koji_candidates.md', 'w', encoding='utf-8', newline='\n').write('\n'.join(lines) + '\n')
    print('rows', len(rows), 'ok', len(ok), 'skipped(表外字)', skipped)


main()
