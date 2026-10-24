#!/usr/bin/env python3
"""準1級・1級の配当漢字を含む二字熟語の候補（読み・書き取り、対義語・類義語などの素材）を作る。

  python3 -I scripts/extract_upper_jukugo_pool.py <JMdict_e.xml> <kanjidic2.xml> <jawikt候補tsv> <wnja.tab>

出力: scripts/data/upper_jukugo_pool.tsv   列: 語<TAB>読み<TAB>最難級<TAB>根拠

採る語（読みは KANJIDIC2 の漢字ごとの読みに分けられるもの）:
  ・JMdict に載り、頻度の印（ke_pri）がある語
  ・JMdict に載り、日本語WordNetにもある語
  ・JMdict とウィクショナリー（upper_jukugo_candidates.tsv）の両方に載り、読みが一致する語
    （専門語・古語・まれな語・卑語の印がある語は除く）
出典: JMdict (c) EDRDG, CC BY-SA 4.0 / ウィクショナリー日本語版 CC BY-SA 4.0 / 日本語WordNet (NICT)。
"""
import re
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, 'scripts')
from wiktionary_idiom_common import RANK_NAME, check_reading, hira, kanjidic, kanji_levels

BAD_MISC = {'&vulg;', '&sl;', '&derog;', '&obs;', '&arch;', '&obsc;', '&rare;', '&X;', '&joc;', '&col;'}
TECH = {'&physics;', '&chem;', '&med;', '&math;', '&geol;', '&zool;', '&bot;', '&engr;', '&comp;',
        '&agric;', '&biol;', '&MA;', '&food;', '&met;', '&metallurgy;', '&mil;', '&law;', '&ling;', '&astron;',
        '&anat;', '&electr;', '&geom;', '&ecol;', '&mineral;', '&archit;', '&print;', '&mus;', '&Buddh;',
        '&Shinto;', '&Christn;', '&sumo;', '&shogi;', '&go;', '&baseb;', '&econ;', '&fin;'}


def main(jmdict, kd_path, wk_path, wn_path):
    kd = kanjidic(kd_path)
    kl = kanji_levels()
    wk = {}
    for n, l in enumerate(open(wk_path, encoding='utf-8')):
        f = l.rstrip('\n').split('\t')
        if n and f[0]:
            wk[f[0]] = f[1]
    wn = set()
    for l in open(wn_path, encoding='utf-8'):
        if not l.startswith('#'):
            f = l.rstrip('\n').split('\t')
            if len(f) >= 2:
                wn.add(f[1])
    rows = {}
    for ev, el in ET.iterparse(jmdict, events=('end',)):
        if el.tag != 'entry':
            continue
        misc = {m.text for s in el.findall('sense') for m in s.findall('misc')}
        field = {m.text for s in el.findall('sense') for m in s.findall('field')}
        pos = {p.text for s in el.findall('sense') for p in s.findall('pos')}
        for k in el.findall('k_ele'):
            w = k.findtext('keb') or ''
            if not re.fullmatch(r'[一-鿿]{2}', w) or not all(c in kl for c in w) or min(kl[c] for c in w) > 1.5:
                continue
            inf = {i.text for i in k.findall('ke_inf')}
            if inf & {'&oK;', '&iK;', '&ateji;', '&sK;', '&io;'} or '&n-pr;' in pos:
                continue
            pri = bool(k.findall('ke_pri'))
            reads = [hira(r.findtext('reb')) for r in el.findall('r_ele')
                     if not r.findall('re_restr') or any(x.text == w for x in r.findall('re_restr'))]
            if not reads:
                continue
            rd, ok = check_reading(reads[0], w, kd)
            if ok != 'OK' or (misc & BAD_MISC):
                continue
            why = None
            if pri:
                why = 'JMdict頻度'
            elif w in wn:
                why = 'WordNet'
            elif wk.get(w) == rd and not (field & TECH):
                why = 'JMdict+ウィクショナリー'
            if why:
                rows[w] = (w, rd, RANK_NAME[min(kl[c] for c in w)], why)
        el.clear()
    out = sorted(rows.values(), key=lambda r: (r[1], r[0]))
    with open('scripts/data/upper_jukugo_pool.tsv', 'w', encoding='utf-8', newline='') as f:
        f.write('語\t読み\t最難級\t根拠\n')
        for r in out:
            f.write('\t'.join(r) + '\n')
    print(len(out), 'words')


main(*sys.argv[1:5])
