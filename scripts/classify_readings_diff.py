#!/usr/bin/env python3
"""常用漢字表との照合で出た読みの差分(欠落・過剰)を原因別(A〜E)に分類し、docs に書き出す。
  python3 -I scripts/classify_readings_diff.py <joyo.txt> [--unihan Unihan_Readings.txt] [--report docs/data_verification/readings_diff_classification.md]
joyo.txt: scripts/extract_joyo_table.py 冒頭の手順で作る(表の全文はリポジトリに置かない)。
--unihan: Unicode の Unihan_Readings.txt(kJapaneseOn/kJapaneseKun)。表外読みが実在するかの参考にだけ使う。
分類(アプリは readings を変更しない。修正は別途 --list-fixes の A のみ):
  A 明白な誤り(カナ種別の取り違えによる同一読みの重複、形式不正)
  B 表記ゆれで実質同じ(語幹だけの表記、送り仮名の括弧位置、表の備考にある別形)
  C 級配当の違いの可能性が高い欠落(表にあるがアプリに無い。アプリの級が2級より下)
  D 表外読みとして実在する可能性が高い過剰(Unihan に載る等)
  E 判断不能
"""
import argparse, collections, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import extract_joyo_table as ext
import check_joyo_official as chk

k2h, strip_ok, norm = chk.k2h, chk.strip_ok, chk.norm_app_reading
LVNAME = chk.LVNAME
ON = re.compile(r'^[ァ-ヶー]+$'); KUN = re.compile(r'^[ぁ-ゟ]+(（[ぁ-ゟ]+）)?$')
kind = lambda s: 'on' if ext.KATA.match(s) else 'kun'

# ---- 表の備考にある別形(常用漢字表の備考欄に明記): 十「ジッ」は「ジュッ」とも言う
TABLE_NOTE_VARIANTS = {('十', 'ジュッ'): 'ジッ', }

# ---- ローマ字(Unihan) → ひらがな
_R = {}
for r, k in [('a','あ'),('i','い'),('u','う'),('e','え'),('o','お')]: _R[r] = k
_rows = {'k':'かきくけこ','s':'さしすせそ','t':'たちつてと','n':'なにぬねの','h':'はひふへほ','m':'まみむめも','r':'らりるれろ','g':'がぎぐげご','z':'ざじずぜぞ','d':'だぢづでど','b':'ばびぶべぼ','p':'ぱぴぷぺぽ'}
for c, ks in _rows.items():
    for v, k in zip('aiueo', ks): _R[c + v] = k
_R.update({'ya':'や','yu':'ゆ','yo':'よ','wa':'わ','wo':'を','n':'ん','shi':'し','chi':'ち','tsu':'つ','fu':'ふ','ji':'じ','si':'し','ti':'ち','tu':'つ','hu':'ふ','zi':'じ','di':'ぢ','du':'づ'})
for c, ks in {'k':'き','s':'し','t':'ち','n':'に','h':'ひ','m':'み','r':'り','g':'ぎ','b':'び','p':'ぴ','z':'じ','d':'ぢ'}.items():
    for v, s in zip('aiueo', 'ゃぃゅぇょ'): pass
    for v, s in (('a','ゃ'),('u','ゅ'),('o','ょ')): _R[c + 'y' + v] = ks + s
for v, s in (('a','ゃ'),('u','ゅ'),('o','ょ')):
    _R['sh' + v] = 'し' + s; _R['ch' + v] = 'ち' + s; _R['j' + v] = 'じ' + s
def romaji_to_hira(s):
    s = s.lower(); out = ''; i = 0
    while i < len(s):
        if i + 1 < len(s) and s[i] == s[i+1] and s[i] not in 'aiueon':
            out += 'っ'; i += 1; continue
        for n in (3, 2, 1):
            if s[i:i+n] in _R and not (s[i:i+n] == 'n' and i + 1 < len(s) and s[i+1] in 'aiueoy'):
                out += _R[s[i:i+n]]; i += n; break
        else:
            return None
    return out

def load_unihan(path):
    on, kun = collections.defaultdict(set), collections.defaultdict(set)
    if not path: return None
    for line in open(path, encoding='utf-8'):
        if line.startswith('#') or '\t' not in line: continue
        cp, key, val = line.rstrip('\n').split('\t')
        if key not in ('kJapaneseOn', 'kJapaneseKun'): continue
        ch = chr(int(cp[2:], 16))
        for w in val.split():
            h = romaji_to_hira(w)
            if h: (on if key == 'kJapaneseOn' else kun)[ch].add(h)
    return on, kun

def unihan_attested(uni, ch, r):
    if uni is None: return None
    on, kun = uni
    if kind(r) == 'on':
        f = k2h(r)
        # 長音は「う」に統一されている(Unihan)。「ー」は無視
        return f in on[ch]
    full = k2h(norm(r)); stem = k2h(strip_ok(r))
    return any(u == full or u.startswith(stem) for u in kun[ch])

def classify(joyo_txt, unihan):
    table, _ = ext.parse(open(joyo_txt, encoding='utf-8').read())
    lv, data, _ = chk.load_app()
    uni = load_unihan(unihan)
    missing, excess = [], []
    for c in lv:
        if c not in table or c not in data: continue
        rs = data[c][0]
        tn = {(kind(t['yomi']), k2h(t['yomi'])): t['yomi'] for t in table[c]['readings']}
        an = {(kind(r), k2h(norm(r))): r for r in rs}
        for k, y in tn.items():
            if k not in an: missing.append((lv[c], c, y))
        for k, r in an.items():
            if k not in tn: excess.append((lv[c], c, r))
    rows = []   # (side, level, ch, reading, cls, reason, fix)
    # ---- 過剰
    for L, c, r in excess:
        rs = data[c][0]; tr = [t['yomi'] for t in table[c]['readings']]
        tk = [y for y in tr if kind(y) == kind(r)]
        others = [x for x in rs if x != r]
        if any(k2h(x) == k2h(r) for x in others) and ON.match(r + '') is None and kind(r) == 'kun' and any(ON.match(x) and k2h(x) == k2h(r) for x in others):
            rows.append(('過剰', L, c, r, 'A', 'カタカナの音読み(%s)と同じ読みをひらがなで重複して持つ(カナ種別の取り違え)' % [x for x in others if ON.match(x) and k2h(x) == k2h(r)][0], '削除'))
        elif [t for t in tr if kind(t) != kind(r) and k2h(norm(t)) == k2h(norm(r))]:
            t = [t for t in tr if kind(t) != kind(r) and k2h(norm(t)) == k2h(norm(r))][0]
            rows.append(('過剰', L, c, r, 'A', 'カナ種別の取り違え。表の読み「%s」と、かなを揃えると同じ' % t, '「%s」→「%s」' % (r, t)))
        elif not (ON.match(r) or KUN.match(r)):
            rows.append(('過剰', L, c, r, 'A', '読みの形式が不正', '要修正'))
        elif (c, r) in TABLE_NOTE_VARIANTS:
            rows.append(('過剰', L, c, r, 'B', '表の備考に「%s」は「%s」とも言う、とある別形' % (TABLE_NOTE_VARIANTS[(c, r)], r), ''))
        elif kind(r) == 'kun' and any(t.startswith(k2h(strip_ok(r))) for t in map(k2h, tk)):
            hit = [y for y in tk if k2h(y).startswith(k2h(strip_ok(r)))][0]
            why = '語幹だけの表記(同じ字の表の訓「%s」と語幹が同じ)' % hit if '（' not in r else '表の訓「%s」と語幹が同じで、送り仮名の形だけが違う' % hit
            rows.append(('過剰', L, c, r, 'B', why, ''))
        else:
            a = unihan_attested(uni, c, r)
            if a:
                rows.append(('過剰', L, c, r, 'D', '表外の読みだが Unihan(kJapaneseOn/Kun)に実在する', ''))
            else:
                rows.append(('過剰', L, c, r, 'E', 'Unihan にも表にも無い(Unihan は網羅的でない)。人の確認が必要' if a is False else 'Unihan 未指定のため判断不能', ''))
    # ---- 欠落
    for L, c, y in missing:
        rs = data[c][0]; k = kind(y)
        sw = [r for (L2, c2, r) in excess if c2 == c and kind(r) != k and k2h(norm(r)) == k2h(norm(y))]
        if sw:
            rows.append(('欠落', L, c, y, 'A', 'アプリは「%s」(かなの種別が逆)で持つ。上の過剰と同じ件' % sw[0], '')); continue
        pair = [r for (L2, c2, r) in excess if c2 == c and kind(r) == k and k2h(strip_ok(r)) == k2h(y)]
        if pair:
            rows.append(('欠落', L, c, y, 'B', 'アプリは「%s」(送り仮名の括弧つき)で持つ。同じ読み' % pair[0], '')); continue
        if L == '2':
            rows.append(('欠落', L, c, y, 'E', '2級は常用漢字の最上位の級。上位級への配当では説明できず、省略か配当不明かを人が確認する', '')); continue
        if k == 'on':
            tag = '別音(漢音・呉音・慣用音の追加読み)'
        else:
            st = k2h(strip_ok(y)); apps = [k2h(strip_ok(r)) for r in rs if kind(r) == 'kun']
            if any(y_.startswith(a) or a.startswith(y_) for a in apps for y_ in [st] if a):
                tag = '活用形・派生形(同じ字に語幹の同じ訓がある)'
            else:
                tag = '別訓(アプリに無い別の訓読み)'
        rows.append(('欠落', L, c, y, 'C', tag + '。アプリの級(%s)より上位の級に配当される可能性が高い(推測。漢検の級別表とは未照合)' % LVNAME[L], ''))
    return rows, len(excess), len(missing)

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('txt'); ap.add_argument('--unihan'); ap.add_argument('--report')
    ap.add_argument('--list-fixes', action='store_true'); a = ap.parse_args()
    rows, ne, nm = classify(a.txt, a.unihan)
    cnt = collections.Counter((r[0], r[4]) for r in rows)
    print('欠落', nm, '過剰', ne, dict(cnt))
    if a.list_fixes:
        for r in rows:
            if r[4] == 'A': print(r)
    if a.report: write(a.report, rows, cnt, nm, ne, a.unihan is not None)

def write(path, rows, cnt, nm, ne, has_uni):
    order = {'A':0,'B':1,'C':2,'D':3,'E':4}
    o = ['# 読みの差分の分類(自動生成)', '',
         '常用漢字表(2010)との照合(`scripts/check_joyo_official.py`)で出た差分 欠落%d件・過剰%d件を、原因別に分類した。生成: `scripts/classify_readings_diff.py`。' % (nm, ne), '',
         '**分類は機械的な推定**。漢検協会の級別漢字表は照合に使っていない(転載条件が未確認のためデータ化しない)。C・D・E は修正していない。', '',
         '## 分類の定義', '',
         '| 分類 | 意味 | 対応 |', '|---|---|---|',
         '| A | 明白な誤り(ひらがな/カタカナの取り違えによる同じ読みの重複、形式不正) | 表記の統一で決まるものだけ修正 |',
         '| B | 表記ゆれで実質同じ(語幹だけの表記、送り仮名の括弧位置、表の備考にある別形) | 修正しない(アプリの表記規約の範囲) |',
         '| C | 級配当の違いの可能性が高い欠落(表にあるが、アプリの級より上位の級に配当されうる読み) | 修正しない |',
         '| D | 表外読みとして実在する可能性が高い過剰(Unihan に載る等) | 修正しない |',
         '| E | 判断不能 | 修正しない。人が確認 |', '',
         '## 件数', '', '| 分類 | 欠落(表にあってアプリに無い) | 過剰(アプリにあって表に無い) | 計 |', '|---|---|---|---|']
    for k in 'ABCDE':
        o.append('| %s | %d | %d | %d |' % (k, cnt[('欠落', k)], cnt[('過剰', k)], cnt[('欠落', k)] + cnt[('過剰', k)]))
    o.append('| 計 | %d | %d | %d |' % (nm, ne, nm + ne))
    o += ['', '- 過剰の D/E の判定には Unihan の kJapaneseOn/kJapaneseKun を使った%s。Unihan に無いことは誤りの証拠ではない。' % ('' if has_uni else '(今回の生成では未指定)'),
          '- 欠落の C は「アプリの級が2級より下」であることだけを根拠にした推測。2級の欠落は上位の級で説明できないため E にした。', '']
    for k, title in [('A', 'A 明白な誤り'), ('B', 'B 表記ゆれで実質同じ'), ('D', 'D 表外読みで正しい可能性が高い過剰'), ('E', 'E 判断不能')]:
        sel = sorted([r for r in rows if r[4] == k], key=lambda r: (r[0], LVNAME.get(r[1], ''), r[2]))
        o += ['## %s(%d件)' % (title, len(sel)), '']
        if not sel: o += ['なし', '']; continue
        o += ['| 種別 | 級 | 字 | 読み | 根拠 |', '|---|---|---|---|---|']
        for r in sel: o.append('| %s | %s | %s | %s | %s |' % (r[0], LVNAME[r[1]], r[2], r[3], r[5]))
        o.append('')
    fx = [r for r in rows if r[4] == 'A' and r[0] == '過剰']
    _, data, _ = chk.load_app()
    o += ['## 適用した修正(A のうち、表記の統一だけで決まるもの: %d件)' % len(fx), '',
          'このレポートは修正前(origin/main の読み)に対する分類。修正は readings の中の1要素の削除またはカナ種別の置換だけで、読みの意味は変えない。', '',
          '| 字 | 修正前 | 修正後 | 根拠 |', '|---|---|---|---|']
    for r in sorted(fx, key=lambda r: r[2]):
        before = data[r[2]][0]
        if r[6] == '削除': after = [x for x in before if x != r[3]]
        else: after = [r[6].split('」→「')[1].rstrip('」') if x == r[3] else x for x in before]
        o.append('| %s | %s | %s | %s |' % (r[2], '、'.join(before), '、'.join(after), r[5]))
    o.append('')
    sel = [r for r in rows if r[4] == 'C']
    o += ['## C 級配当の違いの可能性が高い欠落(%d件)' % len(sel), '', '根拠の種類ごとに、級別に並べた(字=表の読み)。', '']
    by = collections.defaultdict(list)
    for r in sel: by[r[5].split('。')[0]].append(r)
    for tag, rs in sorted(by.items()):
        o += ['### %s(%d件)' % (tag, len(rs)), '']
        for L in chk.LEVELS:
            x = [r for r in rs if r[1] == L]
            if x: o.append('- **%s**: ' % LVNAME[L] + '、'.join('%s=%s' % (r[2], r[3]) for r in x))
        o.append('')
    o += ['共通の根拠: アプリの級が2級より下で、表の読みが省略されている。漢検は級ごとに配当する読みを限定しており、その読みはより上位の級に配当されている可能性が高い。ただし級別表と未照合のため、**推測**である。', '']
    o += ['## 人の確認が必要な点', '',
          '- 2級「伎」: アプリの読みは「ギ」だけで、表の「キ」(歌舞伎)が無い(E)。「ギ」は表外だが実在する読み(D)。漢検の2級配当の読みを確認し、「キ」の追加が必要か判断する。',
          '- 2級「丼=どん」「塞=ふさがる」(E): 2級に上位の級は無いため、省略かどうかを確認する。',
          '- C(級配当の違いと推測した欠落)全体: 漢検の級別の配当読みと未照合。特に10〜5級は、アプリが小学校の学年配当の読みに絞っている可能性が高いが、確認していない。',
          '- B のうち語幹だけの表記(まな・やす・まる・で・だ 等)は、アプリの表記規約(用例の読みと合わせるため)の可能性があり、削除していない。',
          '- Unihan は外部データ(リポジトリには含めない)。取得: https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip の Unihan_Readings.txt。', '']
    open(path, 'w', encoding='utf-8').write('\n'.join(o) + '\n')

if __name__ == '__main__': main()
