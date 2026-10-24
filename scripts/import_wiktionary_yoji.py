#!/usr/bin/env python3
"""四字熟語の候補（ウィクショナリー由来）のうち、候補度Aの語を scripts/data/yoji_jukugo.tsv に取り込む。

  python3 -I scripts/import_wiktionary_yoji.py
  python3 -I scripts/generate_yoji_data.py

候補は extract_wiktionary_yoji_candidates.py で作る（scripts/data/yoji_easy_candidates.tsv と
upper_yoji_candidates.tsv）。候補度Aは、読みを KANJIDIC2 の各字の読みで検査済みで、意味が語の
説明として自然な形、子ども向けに不適切な語を含まないもの。すでに yoji_jukugo.tsv にある語は入れない。
意味はウィクショナリー(CC BY-SA 4.0)の文。出典表示は lib/screens/settings_screen.dart の appCredits。
"""
import sys

DEST = 'scripts/data/yoji_jukugo.tsv'
SOURCES = ['scripts/data/yoji_easy_candidates.tsv', 'scripts/data/upper_yoji_candidates.tsv']

have = set()
for line in open(DEST, encoding='utf-8'):
    if line.strip():
        have.add(line.split('\t')[0])

added = []
for path in SOURCES:
    for n, line in enumerate(open(path, encoding='utf-8')):
        if n == 0 or not line.strip():
            continue
        f = line.rstrip('\n').split('\t')
        word, reading, meaning, check, tier = f[0], f[1], f[3], f[5], f[7]
        if tier != 'A' or check != 'OK' or word in have:
            continue
        have.add(word)
        added.append((word, reading, meaning))

text = open(DEST, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in text else '\n'
if not text.endswith(nl):
    text += nl
for w, r, m in added:
    text += '\t'.join([w, r, m.replace('\t', ' ')]) + nl
open(DEST, 'w', encoding='utf-8', newline='').write(text)
print('added', len(added), 'words; total', len(have))
sys.exit(0)
