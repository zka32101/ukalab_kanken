#!/usr/bin/env python3
"""4級〜2級の配当漢字(1,110字)の部首・部首名データ(lib/data/kanji_radical_upper_data.dart)を作る。

  python3 -I scripts/generate_radical_upper.py <kanjivg-YYYYMMDD.xml.gz> [--report]

決め方（上から順に。最初に決まったものを使う）
  1. scripts/data/radical_upper_overrides.tsv（字ごとの指定）
  2. KanjiVGの部首の形・位置を、scripts/data/radical_upper_rules.tsv で 部首・部首名 にする
  3. 既存データ（lib/data/kanji_radical_data.dart。10級〜5級・確認済み）の、同じ形・同じ位置の多数派
  どれでも決まらない字は、結果に入れずにレポートに出す（出題には使わない）。
KanjiVG (https://kanjivg.tagaini.net) (c) Ulrich Apel and contributors, CC BY-SA 3.0。
"""
import collections
import gzip
import re
import sys
import xml.etree.ElementTree as ET

NS = '{http://kanjivg.tagaini.net}'
src = sys.argv[1]
report_only = '--report' in sys.argv

level_src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
UP = []
for lv in ['LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']:
    UP += list(re.search(r"'%s':\s*'([^']*)'" % lv, level_src).group(1))

# KanjiVG: 各字の部首（general > tradit > 最初）
root = ET.fromstring(gzip.open(src, 'rb').read())
vg = {}
for k in root.iter('kanji'):
    m = re.fullmatch(r'kvg:kanji_([0-9a-f]{5})', k.get('id'))
    if not m:
        continue
    rads = []

    def walk(g):
        for c in g:
            if c.tag == 'g':
                r = c.get(NS + 'radical')
                if r:
                    rads.append((r, c.get(NS + 'element'), c.get(NS + 'position')))
                walk(c)
    walk(k)
    g = [x for x in rads if x[0] == 'general'] or [x for x in rads if x[0] == 'tradit'] or rads
    if g:
        vg[chr(int(m.group(1), 16))] = (g[0][1], g[0][2] or 'none')

# 規則表・字ごとの指定
rules = {}
for line in open('scripts/data/radical_upper_rules.tsv', encoding='utf-8'):
    if line.startswith('#') or not line.strip():
        continue
    el, pos, r, n = line.rstrip('\n').split('\t')
    rules[(el, pos)] = (r, n)
overrides = {}
try:
    for line in open('scripts/data/radical_upper_overrides.tsv', encoding='utf-8'):
        if line.startswith('#') or not line.strip():
            continue
        k, r, n = line.rstrip('\n').split('\t')[:3]
        overrides[k] = (r, n)
except FileNotFoundError:
    pass

# 既存データの多数派
exist = {}
for m in re.finditer(r"'(.)': KanjiRadicalInfo\(radical: '(.)', radicalName: '([^']*)'\)",
                     open('lib/data/kanji_radical_data.dart', encoding='utf-8').read()):
    exist[m.group(1)] = (m.group(2), m.group(3))
by_key = collections.defaultdict(collections.Counter)
for k, rn in exist.items():
    if k in vg:
        by_key[vg[k]][rn] += 1

result, how, undecided = {}, collections.Counter(), []
for k in UP:
    if k in overrides:
        result[k] = overrides[k]; how['字ごと指定'] += 1; continue
    key = vg.get(k)
    if key is None:
        undecided.append((k, None, '部首情報なし')); continue
    if key in rules:
        result[k] = rules[key]; how['規則表'] += 1; continue
    c = by_key.get(key)
    if c:
        (rn, n), = c.most_common(1)
        if n / sum(c.values()) >= 0.8 and sum(c.values()) >= 3:
            result[k] = rn; how['既存の多数派'] += 1; continue
    undecided.append((k, key, dict(c) if c else None))

print('決まった', len(result), how, ' 決まらない', len(undecided))
if '--report' in sys.argv:
    g = collections.defaultdict(list)
    for k, key, c in undecided:
        g[(key, str(c))].append(k)
    for (key, c), ks in sorted(g.items(), key=lambda x: -len(x[1])):
        print(key, ''.join(ks), c)
    sys.exit(0)

out = [
    '// GENERATED FILE - do not edit by hand. Run scripts/generate_radical_upper.py.',
    '//',
    '// 4級〜2級の配当漢字の部首・部首名。形と位置は KanjiVG 由来（CC BY-SA 3.0）。',
    '// 決め方は scripts/generate_radical_upper.py の説明を参照（規則表 radical_upper_rules.tsv と',
    '// 字ごとの指定 radical_upper_overrides.tsv）。決まらなかった字は入れていない。',
    '',
    "import 'kanji_radical_data.dart' show KanjiRadicalInfo;",
    '',
    'const Map<String, KanjiRadicalInfo> kKanjiRadicalUpper = {',
]
for k in UP:
    if k in result:
        r, n = result[k]
        out.append("  '%s': KanjiRadicalInfo(radical: '%s', radicalName: '%s')," % (k, r, n))
out += ['};', '']
open('lib/data/kanji_radical_upper_data.dart', 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('wrote', len(result))
