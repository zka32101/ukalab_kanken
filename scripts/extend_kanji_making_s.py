#!/usr/bin/env python3
"""漢字作り(S: A○・○B)の問題を、用例の熟語から増やして scripts/data/kanji_making.tsv に足す。

  python3 -I scripts/extend_kanji_making_s.py
  python3 -I scripts/generate_kanji_making_data.py

共通の字 X について、「AX」「XB」の2字熟語がどちらも用例(lib/data/kanji_info_data.dart)に
ある組を正解にする。誤答の組(A',B')は、A'X も XB' も、アプリにある熟語(用例・四字熟語・
熟語の構成・三字熟語)のどれにも出てこない字から選ぶ。すでにある問題(同じ X)は増やさない。
"""
import random
import re
import itertools

KJ = re.compile(r'^[一-鿿]{2}$')
ORDER = {'LEVEL_10': 10, 'LEVEL_9': 9, 'LEVEL_8': 8, 'LEVEL_7': 7, 'LEVEL_6': 6,
         'LEVEL_5': 5, 'LEVEL_4': 4, 'LEVEL_3': 3, 'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2}
lv = {}
src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
for m in re.finditer(r"'(LEVEL_\w+)':\s*'([^']*)'", src):
    if m.group(1) in ORDER:
        for c in m.group(2):
            lv[c] = ORDER[m.group(1)]

words = set()
info = open('lib/data/kanji_info_data.dart', encoding='utf-8').read()
for m in re.finditer(r"'([^'（）]+)（[^'）]+）'", info):
    if KJ.match(m.group(1)):
        words.add(m.group(1))
known_text = ''
for p in ['scripts/data/yoji_jukugo.tsv', 'scripts/data/compound_structure.tsv',
          'scripts/data/sanji_jukugo.tsv', 'scripts/data/word_relations.tsv',
          'scripts/data/homophones.tsv']:
    known_text += open(p, encoding='utf-8').read()
bigrams = set(words)
for run in re.findall(r'[一-鿿]+', known_text + info):
    for i in range(len(run) - 1):
        bigrams.add(run[i:i + 2])

have_x = set()
dest = 'scripts/data/kanji_making.tsv'
raw = open(dest, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in raw else '\n'
for line in raw.splitlines():
    f = line.split('\t')
    if f[0] == 'S':
        have_x.add(f[1])

pre, post = {}, {}
for w in sorted(words):
    a, x = w
    if a in lv and x in lv and a != x:
        pre.setdefault(x, []).append(a)  # a + x
    x, b = w
    if x in lv and b in lv and x != b:
        post.setdefault(x, []).append(b)  # x + b

rnd = random.Random(24)
by_level = {}
for c, r in lv.items():
    by_level.setdefault(r, []).append(c)

out = []
for x in sorted(set(pre) & set(post), key=lambda c: -lv[c]):
    if x in have_x or lv[x] < 5:  # 9〜5級配当の字を共通にする(rank>=5)
        continue
    pairs = [(a, b) for a in pre[x] for b in post[x] if a != b]
    # 易しい字どうしの組を優先
    pairs.sort(key=lambda p: (max(-lv[p[0]], -lv[p[1]]), p))
    pairs = pairs[:2]
    for a, b in pairs:
        near = [c for c, r in lv.items() if abs(r - max(lv[a], lv[b])) <= 1]
        cand_a = [c for c in near if c not in (a, b, x) and c + x not in bigrams and x + c not in bigrams]
        wrongs = []
        for _ in range(40):
            if len(wrongs) == 2:
                break
            p, q = rnd.choice(cand_a), rnd.choice(cand_a)
            if p == q or [p, q] in wrongs or {p, q} & {a, b}:
                continue
            wrongs.append([p, q])
        if len(wrongs) < 2:
            continue
        out.append('\t'.join(['S', x, a, b, ';'.join(','.join(w) for w in wrongs)]))
        have_x.add(x)
        break  # 同じ字では1問

text = raw if raw.endswith(nl) else raw + nl
text += nl.join(out) + nl
open(dest, 'w', encoding='utf-8', newline='').write(text)
print('added', len(out))
