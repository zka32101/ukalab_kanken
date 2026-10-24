#!/usr/bin/env python3
"""準1級・1級の配当漢字を含む二字熟語を、ウィクショナリー(日本語版)から集める。

  python3 -I scripts/extract_wiktionary_upper_jukugo.py <jawiktionary-pages-articles.xml.bz2> <kanjidic2.xml>

出力: scripts/data/upper_jukugo_candidates.tsv
  列: 語<TAB>読み<TAB>意味(原文)<TAB>最難級<TAB>検査

条件:
  ・題名が漢字2字で、2字とも level_kanji_data.dart の配当漢字（10級〜1級）にある
  ・少なくとも1字が準1級・1級の字
  ・読みを KANJIDIC2 の各字の読みに分けられる（音読みの熟語。濁音化・促音化を許す）
  ・固有名詞（人名・地名・姓）、子ども向けに不適切な語を含む意味のものは除く
意味はこのアプリでは使わない（読み・書き取りの問題だけ）。語と読みだけを使う。
語彙の出典: ウィクショナリー日本語版 (CC BY-SA 4.0)。
"""
import bz2
import re
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, 'scripts')
from wiktionary_idiom_common import (RANK_NAME, check_reading, glosses, headline_reading,
                                     kanjidic, kanji_levels)

SENSITIVE = ['性交', '性器', '陰茎', '陰部', '陰毛', '膣', '自慰', '強姦', '売春', '娼', '淫', '猥', '糞', '尿',
             '殺人', '自殺', '死体', '屠', '賤', '差別', '蔑称', '卑語', '俗語', '隠語', '蔑み', '罵']
PROPER = ['固有名詞', '人名', '姓', '地名', '地域', '駅名', '企業', '会社名', '旧国名', '氏名']

RANK = None


def main(dump, kd_path):
    kd = kanjidic(kd_path)
    kl = kanji_levels()
    rows = []
    with bz2.open(dump, 'rb') as f:
        for ev, el in ET.iterparse(f, events=('end',)):
            if el.tag.rsplit('}', 1)[-1] != 'page':
                continue
            title = el.findtext('{*}title') or ''
            if (el.findtext('{*}ns') == '0' and re.fullmatch(r'[一-鿿]{2}', title)
                    and all(c in kl for c in title) and min(kl[c] for c in title) <= 1.5):
                text = el.findtext('{*}revision/{*}text') or ''
                if '日本語' in text:
                    raw = headline_reading(text)
                    reading, check = check_reading(raw, title, kd)
                    gl = glosses(text, 2)
                    gtext = ' / '.join(gl)
                    if check == 'OK' and gl and not any(s in text[:3000] for s in PROPER) \
                            and not any(s in gtext for s in SENSITIVE):
                        rows.append((title, reading, gtext, RANK_NAME[min(kl[c] for c in title)], check))
            el.clear()
    rows.sort(key=lambda r: (r[1], r[0]))
    with open('scripts/data/upper_jukugo_candidates.tsv', 'w', encoding='utf-8', newline='') as out:
        out.write('語\t読み\t意味(原文)\t最難級\t検査\n')
        for r in rows:
            out.write('\t'.join(x.replace('\t', ' ') for x in r) + '\n')
    print(len(rows), 'words')


main(sys.argv[1], sys.argv[2])
