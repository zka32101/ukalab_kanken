#!/usr/bin/env python3
"""10級〜5級の用例の品質を機械的に数える(修正はしない)。
  python3 -I scripts/analyze_example_quality.py
出力: 標準出力に集計。docs/data_verification/example_quality_note.md の元数字。
"""
import re

def kata2hira(s):
    return ''.join(chr(ord(c) - 0x60) if 'ァ' <= c <= 'ヶ' else c for c in s)

src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
lv = {}
for m in re.finditer(r"'LEVEL_(\d+)':\s*'([^']*)'", src):
    if m.group(1) in ('10', '9', '8', '7', '6', '5'):
        for c in m.group(2):
            lv[c] = m.group(1)
info = open('lib/data/kanji_info_data.dart', encoding='utf-8').read()
data = {}
for m in re.finditer(r"^    '(.)': KanjiInfo\(readings: \[(.*?)\], examples: \[(.*?)\]\)", info, re.M):
    data[m.group(1)] = ([x for x in re.findall(r"'([^']*)'", m.group(2))],
                        [x for x in re.findall(r"'([^']*)'", m.group(3))])
ex_re = re.compile(r'^(.*?)（(.*?)）$')
missing_info = [c for c in lv if c not in data]
only_char = []     # 「字（読み）」だけの用例を含む字
no_example = []
uncovered = []     # 読みを含む用例が無い読みがある字
per_level = {}
for c, l in lv.items():
    if c not in data:
        continue
    rs, es = data[c]
    st = per_level.setdefault(l, [0, 0, 0, 0])
    st[0] += 1
    if not es:
        no_example.append(c); st[1] += 1
    solo = [e for e in es if (ex_re.match(e) or [None, ''])[1] == c]
    if solo:
        only_char.append((c, solo)); st[2] += 1
    yomis = [kata2hira(ex_re.match(e).group(2)) for e in es if ex_re.match(e)]
    bad = []
    for r in rs:
        stem = kata2hira(re.sub(r'（.*?）', '', r))
        if not any(stem in y for y in yomis):
            bad.append(r)
    if bad:
        uncovered.append((c, bad)); st[3] += 1
print('字数', len(lv), 'KanjiInfoなし', missing_info)
print('用例なし', len(no_example), no_example)
print('字(読み)だけの用例を含む字', len(only_char), [f'{c}:{s}' for c, s in only_char][:60])
print('読みを網羅しない字(機械判定)', len(uncovered))
for c, b in uncovered:
    print(lv[c], c, b)
print('級別[字数, 用例なし, 字だけ用例, 未網羅]', per_level)
