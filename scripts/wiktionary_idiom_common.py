"""ウィクショナリー由来の語彙候補を作るスクリプト(extract_wiktionary_*_candidates.py)の共通部分。

読みの検査: ウィクショナリーの読みを、KANJIDIC2 の各字の読み（音・訓の語幹、濁音化・半濁音化・促音化を許す）と、
題名の中のかな（送り仮名・助詞）に分けられるかで調べ、分けられたものだけ、現代仮名づかいの読みに直す。
"""
import re
import xml.etree.ElementTree as ET

LEVEL_RANK = {'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2, 'LEVEL_1_PRE': 1.5, 'LEVEL_1': 1}
RANK_NAME = {5: '3級以下', 2.5: '準2級', 2: '2級', 1.5: '準1級', 1: '1級'}

KATA2HIRA = {c: chr(ord(c) - 0x60) for c in map(chr, range(0x30A1, 0x30F7))}
SMALL = str.maketrans('ゃゅょっぁぃぅぇぉ', 'やゆよつあいうえお')
UNVOICE = str.maketrans('がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽ', 'かきくけこさしすせそたちつてとはひふへほはひふへほ')
VOICE = dict(zip('かきくけこさしすせそたちつてとはひふへほ', 'がぎぐげござじずぜぞだぢづでどばびぶべぼ'))
HALF = dict(zip('はひふへほ', 'ぱぴぷぺぽ'))
KANJI = re.compile(r'[一-鿿]')


def hira(s):
    return ''.join(KATA2HIRA.get(c, c) for c in s)


def unsmall(s):
    return s.translate(SMALL)


def loose(s):
    """小書き・濁点の違いを無視した比較用の形（並べ替え用の読みは、濁点が付かないことがある）。"""
    return unsmall(s).translate(UNVOICE)


def kanji_levels():
    src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
    out = {}
    for name in ('LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3'):
        for c in re.search(r"'%s':\s*'([^']*)'" % name, src).group(1):
            out[c] = 5
    for name, r in LEVEL_RANK.items():
        for c in re.search(r"'%s':\s*'([^']*)'" % name, src).group(1):
            out[c] = r
    return out


def kanjidic(path):
    """字 -> 読みの候補（現代仮名の形）"""
    out = {}
    for ch in ET.parse(path).getroot().iter('character'):
        lit = ch.findtext('literal')
        forms = set()
        for r in ch.iter('reading'):
            if r.get('r_type') not in ('ja_on', 'ja_kun'):
                continue
            s = hira(r.text or '').replace('-', '').split('.')[0]
            if s:
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
        out[lit] = sorted(forms)
    return out


def segment(reading, word, kd, fold=unsmall):
    """読みを、字ごとの読みと題名の中のかなに分けて、現代仮名づかいの読みの集合を返す（分けられなければ空）。
    [fold] は比較のときに無視する違い（ふつうは小書き。並べ替え用の読みなら濁点も）。"""
    target = fold(reading)
    results = set()

    def go(i, pos, acc):
        if i == len(word):
            if pos == len(target):
                results.add(acc)
            return
        c = word[i]
        if KANJI.match(c):
            for modern in kd.get(c, []):
                plain = fold(modern)
                if target.startswith(plain, pos):
                    go(i + 1, pos + len(plain), acc + modern)
        else:  # 送り仮名・助詞など。題名のかなが、そのまま読みに入る
            h = hira(c)
            if target.startswith(fold(h), pos):
                go(i + 1, pos + 1, acc + h)

    go(0, 0, '')
    return results


def clean_markup(s):
    s = re.sub(r'<ref[^>]*>.*?</ref>', '', s, flags=re.S)
    s = re.sub(r'\{\{タグ[^{}]*\}\}', '', s)
    s = re.sub(r'\{\{ふりがな\|([^|{}]*)\|[^{}]*\}\}', r'\1', s)
    s = re.sub(r'\{\{[^{}]*\}\}', '', s)
    s = re.sub(r'\[\[(?:[^\]|]*\|)?([^\]]*)\]\]', r'\1', s)
    s = re.sub(r"'''?", '', s)
    s = re.sub(r'<[^>]+>', '', s)
    return s.strip()


def headline_reading(w):
    m = re.search(r"（([ぁ-ゟァ-ヺー・ 　]+)）", w)
    if m:
        return hira(m.group(1)).replace('・', '').replace(' ', '').replace('　', '')
    m = (re.search(r'\{\{kana-DEFAULTSORT\|([ぁ-ゟ]+)', w) or re.search(r'DEFAULTSORT:([ぁ-ゟ]+)', w)
         or re.search(r'\{\{ja-idiom\|([ぁ-ゟ]+)', w))
    return m.group(1) if m else None


def glosses(w, limit=2):
    """意味の行（'#' で始まる行。用例の '#*' は除く）を、最初の limit 個。"""
    out = []
    for m in re.finditer(r'^#(?![*:#])\s*(.+)$', w, re.M):
        g = clean_markup(m.group(1))
        if g:
            out.append(g)
        if len(out) >= limit:
            break
    return out


def check_reading(raw, title, kd, fold=unsmall):
    """(整形後の読み, 検査結果)"""
    if raw is None:
        return '', '読み無し'
    segs = segment(raw, title, kd, fold)
    if not segs:
        return raw, '要確認（字の読みに分けられない）'
    if len(segs) == 1:
        return next(iter(segs)), 'OK'
    if raw in segs and fold is unsmall:
        return raw, 'OK'  # 小書きの違いで複数に分かれるが、元の読みがそのまま現代仮名づかいの形
    return sorted(segs)[0], '要確認（読みが複数: %s）' % '／'.join(sorted(segs))
