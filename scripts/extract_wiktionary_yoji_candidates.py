#!/usr/bin/env python3
"""ウィクショナリー(CC BY-SA 4.0)の四字熟語・故事成語から、準1級・1級向けの語彙データの「候補」を作る。

  python3 -I scripts/fetch_wiktionary_idioms.py wiktionary_idioms.json
  curl -O https://www.edrdg.org/kanjidic/kanjidic2.xml.gz && gunzip kanjidic2.xml.gz
  python3 -I scripts/extract_wiktionary_yoji_candidates.py wiktionary_idioms.json kanjidic2.xml

出力:
  scripts/data/upper_yoji_candidates.tsv           ... 四字熟語の候補（語・読み・意味・最難級・読みの検査）
  docs/data_verification/upper_yoji_candidates.md  ... 人が確認するための一覧

そのままアプリに入れない。ウィクショナリーの読みは旧仮名や小書きなしの表記が混ざり、意味の欄に
別の語の説明が入っていることもあるので、
  ・読みは、KANJIDIC2 の各字の読みに分けられるか（音読み・訓読み・濁音化・促音化を許す）で検査し、
    分けられたものだけ、現代仮名づかいの読みに直す（分けられないものは「要確認」）。
  ・意味は原文のまま出し、短すぎるものに印を付ける。
最終的には、人が確認した語だけを取り込む。
出典: Wiktionary (CC BY-SA 4.0), KANJIDIC2 (c) EDRDG (CC BY-SA 4.0)。
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wiktionary_idiom_common import (  # noqa: E402
    KANJI, RANK_NAME, check_reading, glosses, headline_reading, kanjidic, kanji_levels)

# 意味が、語の説明として自然な形か（文末の形・長さ）を見る。学習アプリに出すので、子どもに向かない語も除く。
ENDING = re.compile(r'(こと|さま|様子|ようす|たとえ|の意|という|ものごと|状態|のこと)[。）」]?$')
SENSITIVE = ['性欲', '性交', '殺', '死', '売春', '遊女', '遊郭', '妾', '淫', '情欲', '姦', '娼', '裸', '自害']


def tier(check, gloss, notes):
    """A: 読みOK・意味が自然な形・子ども向けに不適切な語なし。B: それ以外（人の確認が要る）。"""
    if check != 'OK' or notes:
        return 'B'
    if not (12 <= len(gloss) <= 90) or gloss.count('。') > 3 or not ENDING.search(gloss):
        return 'B'
    if any(s in gloss for s in SENSITIVE):
        return 'B'
    return 'A'


def main():
    wikt = json.load(open(sys.argv[1], encoding='utf-8'))
    kd = kanjidic(sys.argv[2])
    kl = kanji_levels()
    # 'upper'（既定）: 準1級・1級の字を含む語。'easy': 2級以下の字だけの語（すでにアプリにある語は除く）
    mode = sys.argv[3] if len(sys.argv) > 3 else 'upper'
    have = set()
    if mode == 'easy':
        have = {line.split('\t')[0] for line in open('scripts/data/yoji_jukugo.tsv', encoding='utf-8') if line.strip()}
    prefix = 'upper_yoji' if mode == 'upper' else 'yoji_easy'

    rows = []
    for title, w in wikt['yoji'].items():
        chars = [c for c in title if KANJI.match(c)]
        if len(chars) != 4 or len(title) != 4 or any(c not in kl for c in chars):
            continue
        hardest = min(kl[c] for c in chars)
        if mode == 'upper' and hardest > 1.5:
            continue  # 2級以下の字だけの語は、'easy' で扱う
        if mode == 'easy' and (hardest < 2 or title in have):
            continue  # 準1級・1級の字を含む語は 'upper' で扱う。すでにアプリにある語は除く
        raw = headline_reading(w)
        reading, check = check_reading(raw, title, kd)
        g = (glosses(w, 1) or [''])[0]
        note = []
        if len(g) < 10:
            note.append('意味が短い')
        if title in g:
            note.append('意味に語そのものが入る')
        rows.append((title, reading, raw or '', g, RANK_NAME[hardest], check, '、'.join(note),
                     tier(check, g, note)))
    rows.sort(key=lambda r: (r[7], 0 if r[4] == '準1級' else 1, r[1] or 'ん'))

    with open('scripts/data/%s_candidates.tsv' % prefix, 'w', encoding='utf-8', newline='\n') as f:
        f.write('語\t読み(整形後)\t読み(元)\t意味(原文)\t最難級\t読みの検査\t意味の印\t候補度\n')
        for r in rows:
            f.write('\t'.join(x.replace('\t', ' ') for x in r) + '\n')

    ok = [r for r in rows if r[5] == 'OK']
    tier_a = [r for r in rows if r[7] == 'A']
    lines = [
        '# %s 四字熟語の候補（確認用）' % ('準1級・1級向け' if mode == 'upper' else '2級以下の漢字だけの'),
        '',
        'ウィクショナリーの「四字熟語」から、%sを機械で取り出した候補。' % ('準1級・1級の配当漢字を含む語' if mode == 'upper' else '2級以下の配当漢字だけの語（すでにアプリにある語は除く）'),
        '**そのままアプリには入れない。** 確認して、取り込む語だけ残す。',
        '',
        '- 読み: ウィクショナリーの読みを、KANJIDIC2 の各字の読み（音・訓、濁音化・促音化を許す）に分けられるかで検査。',
        '  分けられたものは現代仮名づかいに直して「OK」。分けられない・複数に分かれるものは「要確認」。',
        '- 意味: 原文のまま。別の語の説明が混ざることがある（短い・語そのものが入るものに印）。',
        '- 級: 4字のうち最も難しい字の級（公式の出題範囲とは一致しない）。',
        '- 出典: Wiktionary（日本語版）(CC BY-SA 4.0)、KANJIDIC2 (c) EDRDG (CC BY-SA 4.0)。',
        '',
        '- 候補度: A=読みOK・意味が語の説明として自然な形・子ども向けに不適切な語なし。B=それ以外（人の確認が要る）。',
        '',
        '合計 %d 語（読みの検査OK: %d、要確認: %d）。候補度A: %d 語' % (
            len(rows), len(ok), len(rows) - len(ok), len(tier_a)),
        '',
        '| 語 | 読み | 検査 | 意味（原文） | 印 | 級 | 候補度 |',
        '|---|---|---|---|---|---|---|',
    ]
    for t, rd, raw, g, lv, ck, note, tr in rows:
        lines.append('| %s | %s | %s | %s | %s | %s | %s |' % (
            t, rd or '-', ck, g.replace('|', '／')[:80], note, lv, tr))
    open('docs/data_verification/%s_candidates.md' % prefix, 'w', encoding='utf-8', newline='\n').write('\n'.join(lines) + '\n')
    print('rows', len(rows), 'ok', len(ok))


main()
