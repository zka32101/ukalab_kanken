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
import re
import sys
import xml.etree.ElementTree as ET

LEVEL_RANK = {'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2, 'LEVEL_1_PRE': 1.5, 'LEVEL_1': 1}
RANK_NAME = {1.5: '準1級', 1: '1級'}

KATA2HIRA = {c: chr(ord(c) - 0x60) for c in map(chr, range(0x30A1, 0x30F7))}
SMALL = str.maketrans('ゃゅょっぁぃぅぇぉ', 'やゆよつあいうえお')
VOICE = dict(zip('かきくけこさしすせそたちつてとはひふへほ', 'がぎぐげござじずぜぞだぢづでどばびぶべぼ'))
HALF = dict(zip('はひふへほ', 'ぱぴぷぺぽ'))
KANJI = re.compile(r'[一-鿿]')


def hira(s):
    return ''.join(KATA2HIRA.get(c, c) for c in s)


def unsmall(s):
    return s.translate(SMALL)


def kanji_levels():
    src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
    out = {}
    for name in ('LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3'):
        m = re.search(r"'%s':\s*'([^']*)'" % name, src)
        for c in m.group(1):
            out[c] = 5
    for name, r in LEVEL_RANK.items():
        m = re.search(r"'%s':\s*'([^']*)'" % name, src)
        for c in m.group(1):
            out[c] = r
    return out


def kanjidic(path):
    """字 -> 読みの候補 [(比較用の形, 現代仮名の形)]（音読み・訓読みの語幹。濁音化・半濁音化・促音化を含む）"""
    out = {}
    for ch in ET.parse(path).getroot().iter('character'):
        lit = ch.findtext('literal')
        forms = set()
        for r in ch.iter('reading'):
            if r.get('r_type') not in ('ja_on', 'ja_kun'):
                continue
            s = hira(r.text or '').replace('-', '')
            s = s.split('.')[0]
            if not s:
                continue
            forms.add(s)
        more = set()
        for s in forms:
            if s[0] in VOICE:
                more.add(VOICE[s[0]] + s[1:])
            if s[0] in HALF:
                more.add(HALF[s[0]] + s[1:])
        forms |= more
        more = set()
        for s in forms:
            if len(s) >= 2 and s[-1] in 'つちくき':
                more.add(s[:-1] + 'っ')
        forms |= more
        out[lit] = sorted({(unsmall(s), s) for s in forms})
    return out


def segment(reading, word, kd):
    """読みを、字ごとの読みに分けて、現代仮名の読みの集合を返す（分けられなければ空）。"""
    target = unsmall(reading)
    results = set()

    def go(i, pos, acc):
        if i == len(word):
            if pos == len(target):
                results.add(acc)
            return
        for plain, modern in kd.get(word[i], []):
            if target.startswith(plain, pos):
                go(i + 1, pos + len(plain), acc + modern)

    go(0, 0, '')
    return results


def clean_markup(s):
    s = re.sub(r'<ref[^>]*>.*?</ref>', '', s, flags=re.S)
    s = re.sub(r'\{\{[^{}]*\}\}', '', s)
    s = re.sub(r'\[\[(?:[^\]|]*\|)?([^\]]*)\]\]', r'\1', s)
    s = re.sub(r"'''?", '', s)
    return s.strip()


def headline_reading(w):
    m = re.search(r"（([ぁ-ゟァ-ヺー・ 　]+)）", w)
    if m:
        return hira(m.group(1)).replace('・', '').replace(' ', '').replace('　', '')
    m = re.search(r'\{\{kana-DEFAULTSORT\|([ぁ-ゟ]+)', w) or re.search(r'DEFAULTSORT:([ぁ-ゟ]+)', w)
    return m.group(1) if m else None


def gloss(w):
    m = re.search(r'^#(?![*:#])\s*(.+)$', w, re.M)
    return clean_markup(m.group(1)) if m else ''


def main():
    wikt = json.load(open(sys.argv[1], encoding='utf-8'))
    kd = kanjidic(sys.argv[2])
    kl = kanji_levels()

    rows = []
    for title, w in wikt['yoji'].items():
        chars = [c for c in title if KANJI.match(c)]
        if len(chars) != 4 or len(title) != 4 or any(c not in kl for c in chars):
            continue
        hardest = min(kl[c] for c in chars)
        if hardest > 1.5:
            continue  # 2級以下の字だけの語は、すでにある四字熟語のデータの範囲
        raw = headline_reading(w)
        if raw is None:
            reading, check = '', '読み無し'
        else:
            segs = segment(raw, title, kd)
            if not segs:
                reading, check = raw, '要確認（字の読みに分けられない）'
            elif len(segs) == 1:
                reading, check = next(iter(segs)), 'OK'
            elif raw in segs:
                # 小書きの違い（っ／つ など）で複数に分かれるが、元の読みがそのまま現代仮名づかいの形
                reading, check = raw, 'OK'
            else:
                reading, check = sorted(segs)[0], '要確認（読みが複数: %s）' % '／'.join(sorted(segs))
        g = gloss(w)
        note = []
        if len(g) < 10:
            note.append('意味が短い')
        if title in g:
            note.append('意味に語そのものが入る')
        rows.append((title, reading, raw or '', g, RANK_NAME[hardest], check, '、'.join(note)))
    rows.sort(key=lambda r: (0 if r[4] == '準1級' else 1, r[1] or 'ん'))

    with open('scripts/data/upper_yoji_candidates.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('語\t読み(整形後)\t読み(元)\t意味(原文)\t最難級\t読みの検査\t意味の印\n')
        for r in rows:
            f.write('\t'.join(x.replace('\t', ' ') for x in r) + '\n')

    ok = [r for r in rows if r[5] == 'OK']
    lines = [
        '# 準1級・1級向け 四字熟語の候補（確認用）',
        '',
        'ウィクショナリーの「四字熟語」から、準1級・1級の配当漢字を含む語を機械で取り出した候補。',
        '**そのままアプリには入れない。** 確認して、取り込む語だけ残す。',
        '',
        '- 読み: ウィクショナリーの読みを、KANJIDIC2 の各字の読み（音・訓、濁音化・促音化を許す）に分けられるかで検査。',
        '  分けられたものは現代仮名づかいに直して「OK」。分けられない・複数に分かれるものは「要確認」。',
        '- 意味: 原文のまま。別の語の説明が混ざることがある（短い・語そのものが入るものに印）。',
        '- 級: 4字のうち最も難しい字の級（公式の出題範囲とは一致しない）。',
        '- 出典: Wiktionary（日本語版）(CC BY-SA 4.0)、KANJIDIC2 (c) EDRDG (CC BY-SA 4.0)。',
        '',
        '合計 %d 語（読みの検査OK: %d、要確認: %d）' % (len(rows), len(ok), len(rows) - len(ok)),
        '',
        '| 語 | 読み | 検査 | 意味（原文） | 印 | 級 |',
        '|---|---|---|---|---|---|',
    ]
    for t, rd, raw, g, lv, ck, note in rows:
        lines.append('| %s | %s | %s | %s | %s | %s |' % (
            t, rd or '-', ck, g.replace('|', '／')[:80], note, lv))
    open('docs/data_verification/upper_yoji_candidates.md', 'w', encoding='utf-8', newline='\n').write('\n'.join(lines) + '\n')
    print('rows', len(rows), 'ok', len(ok))


main()
