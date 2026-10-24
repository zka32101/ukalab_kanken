#!/usr/bin/env python3
"""対義語・類義語（2字熟語の組）の候補を、2つの資料の一致から作る。

  curl -LO https://raw.githubusercontent.com/bond-lab/wnja/master/data/wn+var_tk17.tab
  python3 -I scripts/parse_wiktionary_relations.py jawiktionary-latest-pages-articles.xml.bz2 wiktionary_relations.json
  curl -O https://www.edrdg.org/kanjidic/kanjidic2.xml.gz && gunzip kanjidic2.xml.gz
  python3 -I scripts/extract_word_relation_candidates.py wn+var_tk17.tab wiktionary_relations.json kanjidic2.xml

出力:
  scripts/data/word_relation_candidates.tsv           ... word_relations.tsv と同じ列（分野は「その他」）＋根拠
  docs/data_verification/word_relation_candidates.md  ... 確認用の一覧

類義語: 日本語WordNet の同じ synset に入っていて、かつウィクショナリーの「類義語」欄にも載っている組。
対義語: ウィクショナリーの「対義語」欄の組のうち、互いに載せ合っている（相互）か、字を1字共有している組。
候補度: A=ウィクショナリーの欄で互いに相手の語を載せ合っている組（手で見た限り誤りが無かった）。B=片方だけ載せている組
（誤りが約2〜3割混ざる。例: 歴史と由来、不便と方便）。取り込むのは A だけ。
共通の条件: 2語とも、2字熟語で、字がすべて10級〜2級の配当漢字にあり、よく使う字（KANJIDIC2 の頻度順位
1500位以内）だけ。読みは日本語WordNet の読みを、KANJIDIC2 の各字の読みに分けられるかで検査して、OKのものだけ。
すでに word_relations.tsv にある組は入れない。
出典: Japanese WordNet (c) 2009-2011 NICT, 2012-2024 Francis Bond ほか（NICT の WordNet 型ライセンス）、
Wiktionary (CC BY-SA 4.0)、KANJIDIC2 (c) EDRDG (CC BY-SA 4.0)。
"""
import itertools
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wiktionary_idiom_common import check_reading, kanjidic  # noqa: E402

RANK = {'LEVEL_10': 10, 'LEVEL_9': 9, 'LEVEL_8': 8, 'LEVEL_7': 7, 'LEVEL_6': 6, 'LEVEL_5': 5,
        'LEVEL_4': 4, 'LEVEL_3': 3, 'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2}
K2 = re.compile(r'^[一-鿿]{2}$')
MAX_FREQ = 1500


def main():
    wn_path, rel_path, kd_path = sys.argv[1:4]
    kd = kanjidic(kd_path)
    freq = {}
    for ch in ET.parse(kd_path).getroot().iter('character'):
        f = ch.findtext('misc/freq')
        if f:
            freq[ch.findtext('literal')] = int(f)
    src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
    level = {}
    for name, r in RANK.items():
        for c in re.search(r"'%s':\s*'([^']*)'" % name, src).group(1):
            level[c] = r

    def common(w):
        return bool(K2.match(w)) and all(c in level and freq.get(c, 9999) <= MAX_FREQ for c in w)

    # 日本語WordNet: synset ごとの語と、語の読み（ひらがな）
    synsets, readings = {}, {}
    for line in open(wn_path, encoding='utf-8'):
        if line.startswith('#'):
            continue
        f = line.rstrip('\n').split('\t')
        if len(f) < 2 or not K2.match(f[1]):
            continue
        synsets.setdefault(f[0], set()).add(f[1])
        if len(f) >= 7 and f[6]:
            readings.setdefault(f[1], set()).add(f[6])
    wn_pairs = set()
    for ws in synsets.values():
        for a, b in itertools.combinations(sorted(ws), 2):
            wn_pairs.add(frozenset((a, b)))

    rel = json.load(open(rel_path, encoding='utf-8'))
    wsyn, want, ant_listed, syn_listed = set(), set(), set(), set()
    for a, v in rel.items():
        for b in v['syn']:
            wsyn.add(frozenset((a, b)))
            syn_listed.add((a, b))
        for b in v['ant']:
            want.add(frozenset((a, b)))
            ant_listed.add((a, b))

    existing = set()
    for line in open('scripts/data/word_relations.tsv', encoding='utf-8'):
        f = line.rstrip('\n').split('\t')
        if len(f) > 3:
            existing.add(frozenset((f[1], f[3])))

    def reading_of(w):
        """検査OKの読みが1つに決まる語だけ（人間 = にんげん／じんかん のように複数あるときは除く）。"""
        ok = {rd for rd, check in (check_reading(raw, w, kd) for raw in readings.get(w, ())) if check == 'OK'}
        return next(iter(ok)) if len(ok) == 1 else None

    rows = []
    cand = []
    for p in wsyn & wn_pairs:
        a, b = sorted(p)
        mutual = (a, b) in syn_listed and (b, a) in syn_listed
        cand.append(('類', p, ('相互に類義語欄に載る' if mutual else '片方の類義語欄に載る') + '（ウィクショナリー）・日本語WordNetの同じ synset',
                     'A' if mutual else 'B'))
    for p in want:
        a, b = sorted(p)
        mutual = (a, b) in ant_listed and (b, a) in ant_listed
        share = len(set(a) & set(b)) == 1
        if mutual or share:
            cand.append(('対', p, ('相互に対義語欄に載る' if mutual else '片方の対義語欄に載り、字を1字共有') + '（ウィクショナリー）',
                         'A' if mutual else 'B'))
    seen = set()
    for kind, p, why, tier in cand:
        if len(p) != 2 or p in existing or (kind, p) in seen:
            continue
        a, b = sorted(p)
        if set(a) == set(b) or not (common(a) and common(b)):
            continue
        if kind == '類' and p in want:
            continue  # 対義語でもある組は除く
        ra, rb = reading_of(a), reading_of(b)
        if not ra or not rb:
            continue
        seen.add((kind, p))
        rows.append((kind, a, ra, b, rb, 'その他', why, tier))
    rows.sort(key=lambda r: (r[7], r[0], r[2]))

    with open('scripts/data/word_relation_candidates.tsv', 'w', encoding='utf-8', newline='\n') as f:
        for r in rows:
            f.write('\t'.join(r) + '\n')
    syn_n = sum(1 for r in rows if r[0] == '類' and r[7] == 'A')
    ant_n = sum(1 for r in rows if r[0] == '対' and r[7] == 'A')
    b_n = sum(1 for r in rows if r[7] == 'B')
    lines = [
        '# 対義語・類義語の候補（確認用）',
        '',
        '日本語WordNetとウィクショナリーの突き合わせで作った候補（作り方は scripts/extract_word_relation_candidates.py の先頭）。',
        '',
        '- 類義語: 日本語WordNetの同じ synset に入り、かつウィクショナリーの類義語欄にも載る組。',
        '- 対義語: ウィクショナリーの対義語欄の組のうち、相互に載る、または字を1字共有する組。',
        '- 2語とも、よく使う字（頻度順位1500位以内）で、10級〜2級の配当漢字の2字熟語。読みは検査OKのもの。',
        '- 出典: Japanese WordNet (c) NICT・Francis Bond ほか、Wiktionary (CC BY-SA 4.0)、KANJIDIC2 (c) EDRDG (CC BY-SA 4.0)。',
        '',
        '候補度A（取り込む）: 類義語 %d 組、対義語 %d 組。候補度B（取り込まない）: %d 組。' % (syn_n, ant_n, b_n),
        '',
        '| 候補度 | 種類 | 語 | 読み | 相手 | 読み | 根拠 |',
        '|---|---|---|---|---|---|---|',
    ]
    for kind, a, ra, b, rb, g, why, tier in rows:
        lines.append('| %s | %s | %s | %s | %s | %s | %s |' % (tier, '類義語' if kind == '類' else '対義語', a, ra, b, rb, why))
    open('docs/data_verification/word_relation_candidates.md', 'w', encoding='utf-8', newline='\n').write('\n'.join(lines) + '\n')
    print('類義語', syn_n, '対義語', ant_n)


main()
