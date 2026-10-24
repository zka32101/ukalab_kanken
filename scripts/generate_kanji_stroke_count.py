#!/usr/bin/env python3
"""KANJIDIC2 から漢字の画数データを生成する。

使い方:
  curl -O https://www.edrdg.org/kanjidic/kanjidic2.xml.gz && gunzip kanjidic2.xml.gz
  python3 -I scripts/generate_kanji_stroke_count.py kanjidic2.xml

出力:
  lib/data/kanji_stroke_count_data.dart  (画数が1つに定まる字だけ)
  docs/data_verification/stroke_count_review.md  (要確認: 画数なし / 複数値)

出典: KANJIDIC2 (c) Electronic Dictionary Research and Development Group,
CC BY-SA 4.0 (https://www.edrdg.org/edrdg/licence.html)。
採用するのは stroke_count の先頭値（日本の数え方と整合する値）。
KANJIDIC2 に無い字・複数値の字は自動採用せず、要確認一覧に出す。
"""
import re
import sys
import xml.etree.ElementTree as ET

DART = 'lib/data/kanji_stroke_count_data.dart'
REVIEW = 'docs/data_verification/stroke_count_review.md'
# 画数が複数値でも、先頭値（常用漢字表の字体の画数）を採る字。しんにょう（辶）・おおざと（阝）は
# 3画で数え、2つめの値は旧字体（辶=4画など）の数え方。乏・極・収も常用漢字表の画数が先頭値。
FIRST_VALUE_OK = set(
    '通近遠道週進遊部送追運返速都極辺達郡連選適迷造逆述過遺延郷収郵退'
    '巡巨込迎迫逃透途遅違遣避郎乏墜廊逮遂遇遭遵邦郊郭'
    '堕迅逸遮遷還邸迭逐逓逝遍')
LEVELS = ['10', '9', '8', '7', '6', '5', '4', '3', '2_PRE', '2', '1_PRE', '1']


def level_chars():
    src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
    out = {}
    for m in re.finditer(r"'LEVEL_(\w+)':\s*'([^']*)'", src):
        out[m.group(1)] = list(m.group(2))
    return out


def main(xml_path):
    root = ET.parse(xml_path).getroot()
    header = root.find('header')
    dbver = header.findtext('database_version')
    kd = {}
    for c in root.findall('character'):
        lit = c.findtext('literal')
        sc = [int(e.text) for e in c.findall('misc/stroke_count')]
        kd[lit] = sc
    levels = level_chars()
    counts, missing, multi = {}, [], []
    for lv in LEVELS:
        for ch in levels[lv]:
            sc = kd.get(ch)
            if not sc:
                missing.append((lv, ch))
            elif len(sc) > 1 and ch not in FIRST_VALUE_OK:
                multi.append((lv, ch, sc))
            elif len(sc) > 1:
                counts[ch] = sc[0]
            else:
                counts[ch] = sc[0]
    with open(DART, 'w', encoding='utf-8') as f:
        f.write(f"""// GENERATED FILE - do not edit by hand. Run scripts/generate_kanji_stroke_count.py.
//
// 漢字の画数（総画数）。
// Source: KANJIDIC2 (database_version {dbver}),
// (c) Electronic Dictionary Research and Development Group (EDRDG),
// licensed under Creative Commons Attribution-ShareAlike 4.0
// (https://www.edrdg.org/edrdg/licence.html).
// stroke_count の先頭値を採用。KANJIDIC2 に画数が無い字、画数が複数値の字は
// 自動では採用せず、ここには入れていない（docs/data_verification/stroke_count_review.md）。

/// 画数が未設定の字は null。
int? kanjiStrokeCount(String kanji) => kKanjiStrokeCount[kanji];

const Map<String, int> kKanjiStrokeCount = {{
""")
        for ch, n in counts.items():
            f.write(f"  '{ch}': {n},\n")
        f.write("};\n")
    with open(REVIEW, 'w', encoding='utf-8') as f:
        f.write(f"""# 画数の要確認一覧

`scripts/generate_kanji_stroke_count.py` が KANJIDIC2（{dbver}）から自動生成した。
ここにある字は `lib/data/kanji_stroke_count_data.dart` に**入れていない**（`kanjiStrokeCount` は null を返す）。
公的な資料（漢検の漢字表・辞典など）で確認できたら、手で追加する。

## KANJIDIC2 に画数が無い字（{len(missing)}字）

| 級 | 字 |
|---|---|
""")
        for lv, ch in missing:
            f.write(f"| {lv} | {ch} |\n")
        f.write(f"\n## 画数が複数値の字（{len(multi)}字）\n\n| 級 | 字 | KANJIDIC2 の値 |\n|---|---|---|\n")
        for lv, ch, sc in multi:
            f.write(f"| {lv} | {ch} | {', '.join(map(str, sc))} |\n")
    print(len(counts), 'filled;', len(missing), 'missing;', len(multi), 'multi')


main(sys.argv[1])
