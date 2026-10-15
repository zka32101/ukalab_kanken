#!/usr/bin/env python3
"""常用漢字表(平成22年内閣告示)の本表PDFから「漢字・音訓・例」を機械抽出する。
  curl -o joyo.pdf https://www.bunka.go.jp/kokugo_nihongo/sisaku/joho/joho/kijun/naikaku/pdf/joyokanjihyo_20101130.pdf
  pdftotext -layout joyo.pdf joyo.txt
  python3 -I scripts/extract_joyo_table.py joyo.txt out.json
出力JSONは作業用(リポジトリには全文を置かない)。構造:
  {漢字: {"variant": 旧字体等, "readings": [{"yomi": 表の音訓, "examples": [例...]}]}}
"""
import json, re, sys

KATA = re.compile(r'^[ァ-ヶー]+$')
HIRA = re.compile(r'^[ぁ-ゟ]+$')
KJ = r'[\u4e00-\u9fff\u3400-\u4dbf\U00020000-\U0002FFFF々]'
# 見出し: 漢字 + (旧字体等) + 空白 + 読み。例「亜（亞） ア」「遜［遜］ ソン」「亀（   ）キ」
HEAD = re.compile(r'^(' + KJ + r')(?:(?:（[^）]*）|［[^］]*］)\s*|\s+(?:(' + KJ + r')\s+)?)([ァ-ヶーぁ-ゟ]+)(?:\s{2,}(.*))?$')
# 表は「叱」を異体の「𠮟」(U+20B9F)で掲げる(解説に「𠮟」と「叱」は本来別字だが同扱い)。アプリ側は「叱」。
ALIAS = {'\U00020b9f': '叱'}

def norm(line):
    return re.sub(r'（\s+）', '（）', line.strip())

def split_cols(line):
    return [t for t in re.split(r'\s{2,}|\t+', line.strip()) if t]

def parse(txt):
    lines = txt.splitlines()
    start = next(i for i, l in enumerate(lines) if re.match(r'\s*本\s+表\s*$', l))
    end = next(i for i, l in enumerate(lines) if i > start and re.match(r'\s*付\s+表\s*$', l))
    entries, cur, anomalies = {}, None, []
    open_tail = False
    for ln in lines[start:end]:
        s = norm(ln)
        if not s or 'indd' in s or re.match(r'^本\s+表$', s) or re.match(r'^漢\s+字\s+音\s+訓', s):
            continue
        cols = split_cols(s)
        m = HEAD.match(s)
        if m and len(cols) >= 2:
            cur = ALIAS.get(m.group(1), m.group(1))
            if cur in entries:
                anomalies.append(('dup', cur))
            entries[cur] = {'variant': '', 'readings': []}
            rest = [m.group(3)] + ([x for x in split_cols(m.group(4))] if m.group(4) else [])
        else:
            rest = cols
            mm = re.match(r'^（[^）]*）\s+([ァ-ヶーぁ-ゟ]+)\s+(.*)$', s)  # 例: 餅「（餠） もち  餅屋，尻餅」
            if mm:
                rest = [mm.group(1)] + split_cols(mm.group(2))
        if cur is None:
            continue
        if (not m or len(cols) < 2) and len(cols) == 1 and open_tail and entries[cur]['readings']:
            # 例の欄が行末の「，」で折り返された続き
            entries[cur]['readings'][-1]['examples'] += [x.strip() for x in re.split(r'[，、]', cols[0]) if x.strip()]
            open_tail = cols[0].endswith(('，', '、'))
            continue
        open_tail = False
        if rest and (KATA.match(rest[0]) or HIRA.match(rest[0])) and (len(rest) >= 2 or m):
            ex = [x.strip() for x in re.split(r'[，、]', rest[1]) if x.strip()] if len(rest) >= 2 else []
            open_tail = len(rest) >= 2 and rest[1].endswith(('，', '、'))
            entries[cur]['readings'].append({'yomi': rest[0], 'examples': ex, 'note': rest[2:]})
        elif len(cols) == 1 and (re.match(r'^[ぁ-んァ-ヶー－]+$', s) or len(s) <= 2):
            continue  # ページ見出し(ア－イ / イ / キュウ－キョウ)
        else:
            anomalies.append(('unparsed', cur, s))
    return entries, anomalies

if __name__ == '__main__':
    txt = open(sys.argv[1], encoding='utf-8').read()
    entries, an = parse(txt)
    json.dump(entries, open(sys.argv[2], 'w', encoding='utf-8'), ensure_ascii=False)
    nread = sum(len(v['readings']) for v in entries.values())
    print('見出し漢字', len(entries), '音訓行', nread, '異常', len(an))
    for a in an[:40]:
        print(a)
