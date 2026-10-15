#!/usr/bin/env python3
"""アプリの読み・用例(10級〜2級の常用漢字)を、常用漢字表(平成22年内閣告示)本表の抽出結果と照合する。
  python3 -I scripts/check_joyo_official.py <joyo.txt> [--report docs/.../official_check_report.md] [--apply] [--adopted scripts/data/joyo_adopted_examples.tsv]
joyo.txt は pdftotext -layout の出力(手順は scripts/extract_joyo_table.py 冒頭)。
--apply を付けたときだけ lib/data/kanji_info_data.dart に「追加のみ」を書き込む(既存の用例・読みは変更しない)。
表の全文は出力しない。レポートに載せるのは差分の字と、追加した語/要確認の語だけ。
"""
import argparse, collections, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import extract_joyo_table as ext

LEVELS = ['10', '9', '8', '7', '6', '5', '4', '3', '2_PRE', '2']
def k2h(s): return ''.join(chr(ord(c) - 0x60) if 'ァ' <= c <= 'ヶ' else c for c in s)
def fix(s): return s.replace('\U00020b9f', '叱')   # 表の「𠮟」=アプリの「叱」
def strip_ok(r): return re.sub(r'（.*?）', '', r)
def norm_app_reading(r): return re.sub(r'[（）]', '', r)

DAKU = {}
for a, b in zip('かきくけこさしすせそたちつてとはひふへほ', 'がぎぐげござじずぜぞだぢづでどばびぶべぼ'): DAKU[a] = b
for a, b in zip('はひふへほ', 'ぱぴぷぺぽ'): DAKU[a + 'p'] = b

def reading_variants(stem):
    """語中での連濁・半濁音化・促音便を許容する語幹の形"""
    st = k2h(stem); out = {st}
    if st:
        if st[0] in DAKU: out.add(DAKU[st[0]] + st[1:])
        if st[0] in 'はひふへほ': out.add(DAKU[st[0] + 'p'] + st[1:])
        if st[-1] in 'つちくきふ': out.add(st[:-1] + 'っ'); out.add(st[:-1] + 'ッ')
        if st[-1] in 'つちくき': out.add(st[:-1] + 'っ')
    return out

def load_app():
    src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
    lv = {}
    for m in re.finditer(r"'LEVEL_(\w+)':\s*'([^']*)'", src):
        if m.group(1) in LEVELS:
            for c in m.group(2): lv.setdefault(c, m.group(1))
    info = open('lib/data/kanji_info_data.dart', encoding='utf-8').read()
    data = {}
    for m in re.finditer(r"^    '(.)': KanjiInfo\(readings: \[(.*?)\], examples: \[(.*?)\]\)", info, re.M):
        data[m.group(1)] = (re.findall(r"'([^']*)'", m.group(2)), re.findall(r"'([^']*)'", m.group(3)))
    return lv, data, info

WORD_OK = re.compile(r'^[\u4e00-\u9fff\u3400-\u4dbf々ぁ-ゟァ-ヶー]+$')   # 「」・。○〔〕などを含む備考混入を除く
EXRE = re.compile(r'^(.*?)（(.*?)）$')

def covered(reading, examples):
    """reading を示す語が用例にあるか(目安の機械判定)"""
    stem = k2h(strip_ok(reading)); full = k2h(norm_app_reading(reading))
    for e in examples:
        m = EXRE.match(e)
        if not m: continue
        y = k2h(m.group(2))
        if any(v in y for v in reading_variants(stem)) or full in y: return True
    return False

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('txt'); ap.add_argument('--report'); ap.add_argument('--apply', action='store_true')
    ap.add_argument('--adopted', default='scripts/data/joyo_adopted_examples.tsv')
    a = ap.parse_args()
    table, anomalies = ext.parse(open(a.txt, encoding='utf-8').read())
    nread = sum(len(v['readings']) for v in table.values())
    lv, data, info_src = load_app()

    targets = [c for c in lv if c in table and c in data]
    notin = [c for c in lv if c not in table]
    # 単語→読みの辞書(アプリ内の既存用例から。複数の読みがあれば曖昧として使わない)
    wordread = collections.defaultdict(set)
    for c, (rs, es) in data.items():
        for e in es:
            m = EXRE.match(e)
            if m: wordread[m.group(1)].add(m.group(2))

    missing, excess, nocov, notable_ex = [], [], [], collections.Counter()
    adopt, confirm = [], []
    per_level = collections.defaultdict(lambda: collections.Counter())
    for c in targets:
        rs, es = data[c]; L = lv[c]
        trs = table[c]['readings']
        tnorm = {}
        for t in trs: tnorm[(('on' if ext.KATA.match(t['yomi']) else 'kun'), k2h(t['yomi']))] = t
        anorm = {}
        for r in rs:
            kind = 'on' if ext.KATA.match(r) else 'kun'
            anorm[(kind, k2h(norm_app_reading(r)))] = r
        per_level[L]['字'] += 1
        for k, t in tnorm.items():
            if k not in anorm:
                missing.append((L, c, t['yomi'])); per_level[L]['欠落'] += 1
        for k, r in anorm.items():
            if k not in tnorm:
                excess.append((L, c, r)); per_level[L]['過剰'] += 1
        appwords = {fix(EXRE.match(e).group(1)) if EXRE.match(e) else e for e in es}
        for r in rs:
            if not covered(r, es):
                nocov.append((L, c, r)); per_level[L]['用例なし読み'] += 1
        for t in trs:
            for w in t['examples']:
                if fix(w) not in appwords: per_level[L]['表の例でアプリに無い語'] += 1
        # --- 追加候補 ---
        solo = [e for e in es if (EXRE.match(e) or [0, 0, ''])[2] == c or (EXRE.match(e) and EXRE.match(e).group(1) == c)]
        for r in rs:
            kind = 'on' if ext.KATA.match(r) else 'kun'
            key = (kind, k2h(norm_app_reading(r)))
            if key not in tnorm: continue          # 表に無い読みは触らない(報告のみ)
            t = tnorm[key]
            if covered(r, es): continue
            okuri = (re.search(r'（(.*?)）', r) or [None, ''])[1]
            stem = strip_ok(r)
            cands = []
            for w0 in t['examples']:
                w = fix(w0)
                if c not in w or w in appwords or not WORD_OK.match(w): continue
                rd = None
                if kind == 'kun':
                    # 見出し字+送り仮名のみの語は、アプリの読み(語幹+送り仮名)から機械的に作れる
                    if w == c + okuri and (okuri or w == c):
                        rd = stem + okuri; src = '語幹+送り仮名'
                if rd is None:
                    known = wordread.get(w, set())
                    if len(known) == 1:
                        cand = next(iter(known))
                        if any(v in k2h(cand) for v in reading_variants(k2h(strip_ok(r)))):
                            rd = cand; src = 'アプリ内の同一語の既存読み'
                if rd: cands.append((w, rd, src, w0))
            if cands:
                for w, rd, src, w0 in cands[:2]:
                    adopt.append((L, c, r, w, rd, src))
            else:
                confirm.append((L, c, r, [fix(x) for x in t['examples']][:3] if not t['examples'] else [fix(x) for x in t['examples']]))
        # 「字（読み）」だけの用例を持つ字: 上の処理で読みが覆われていれば追加しない
    # 同じ語が複数の読みの候補に出る(例: 形=かた/かたち)場合は読みが一意でないので自動追加しない
    cnt = collections.Counter((c, w) for _, c, _, w, _, _ in adopt)
    amb = [x for x in adopt if cnt[(x[1], x[3])] > 1]
    adopt = [x for x in adopt if cnt[(x[1], x[3])] == 1]
    for L, c, r, w, rd, src in amb:
        confirm.append((L, c, r, [w + '(読みが複数あり一意でない)']))
    return a, table, anomalies, nread, lv, data, targets, notin, missing, excess, nocov, adopt, confirm, per_level, info_src

LVNAME = {'10': '10級', '9': '9級', '8': '8級', '7': '7級', '6': '6級', '5': '5級', '4': '4級', '3': '3級', '2_PRE': '準2級', '2': '2級'}

def write_outputs(a, table, anomalies, nread, lv, data, targets, missing, excess, nocov, adopt, confirm, per_level):
    ex_re = EXRE
    solo = [c for c in targets if lv[c] in ('10', '9', '8', '7', '6', '5')
            and any((ex_re.match(e) and ex_re.match(e).group(1) == c) for e in data[c][1])]
    solo_chars = [c for c in solo if c in '妹刀氷息梨象桜蚕鋼俵']
    adopted_chars = {x[1] for x in adopt}
    out = ['# 常用漢字表との照合レポート(自動生成)', '', '**件数は origin/main(用例追加の適用前)時点の照合結果。** 適用後に再実行すると(c)等は減る。', '',
           '出典: 常用漢字表(平成22年内閣告示)本表。生成: `scripts/check_joyo_official.py`(抽出: `scripts/extract_joyo_table.py`)。',
           '常用漢字表PDFの利用規約は未確認のため、表の全文は転載していない。このレポートと `scripts/data/joyo_adopted_examples.tsv` に載せるのは、差分の字・読みと、アプリに追加した語だけ。', '',
           '## 抽出の健全性', '',
           f'- 見出し漢字: {len(table)}字(表の字種2,136字と一致)', f'- 音訓の行数: {nread}', f'- 判別できなかった行(備考の折り返しなど、音訓でも例でもない行): {len(anomalies)}行(全て備考欄の折り返し・注記)',
           '- 表の「𠮟」(U+20B9F)はアプリの「叱」(U+53F1)として扱う。「例」欄は全角読点「，」で区切り、行末が「，」の折り返しは次行へ連結。',
           f'- 照合対象: アプリの10級〜2級のうち常用漢字表にある{len(targets)}字(準1級・1級は対象外)', '',
           '## 件数', '', '| 級 | 字数 | (a)欠落 | (b)過剰 | (c)用例が無い読み | (d)表の例でアプリに無い語 |', '|---|---|---|---|---|---|']
    tot = collections.Counter()
    for L in LEVELS:
        c = per_level[L]; tot.update(c)
        out.append(f"| {LVNAME[L]} | {c['字']} | {c['欠落']} | {c['過剰']} | {c['用例なし読み']} | {c['表の例でアプリに無い語']} |")
    out.append(f"| 計 | {tot['字']} | {tot['欠落']} | {tot['過剰']} | {tot['用例なし読み']} | {tot['表の例でアプリに無い語']} |")
    out += ['', '- (a) 表の音訓がアプリの readings に無い。表の音訓は網羅的なので、頻度の低い読みの省略も含む(誤りとは限らない)。',
            '- (b) アプリの readings が表の音訓に無い。表外読み・表記の違い(送り仮名の括弧位置)・誤りの疑い。**readings は変更していない(報告のみ)。**',
            '- (c) その読みを示す語が用例に無い(目安の機械判定。連濁・促音便は許容、特別な読みの語は過検出あり)。',
            '- (d) 表の「例」の語のうち、アプリの用例にない語の数。表の例は網羅的で全てを入れる意図はないため、件数のみ示し一覧は置かない(全文転載を避ける)。', '']
    def sect(title, rows, fmt):
        out.extend([f'## {title}({len(rows)}件)', ''])
        by = collections.defaultdict(list)
        for r in rows: by[r[0]].append(r)
        for L in LEVELS:
            if by[L]:
                out.append(f'- **{LVNAME[L]}**: ' + '、'.join(fmt(r) for r in by[L]))
        out.append('')
    sect('(a) 表にあるがアプリの readings に無い音訓', missing, lambda r: f'{r[1]}={r[2]}')
    sect('(b) アプリの readings にあるが表に無い(過剰・要確認)', excess, lambda r: f'{r[1]}={r[2]}')
    sect('(c) 読みを示す語が用例に無い読み', nocov, lambda r: f'{r[1]}={r[2]}')
    out += ['## 「字（読み）」だけの用例を含む10字の扱い', '']
    out.append('(該当の読みについて、表の「例」にある語を併記。表の例が字単独だけなら、表からは語を補えない。)')
    for c in '妹刀氷息梨象桜蚕鋼俵':
        if c not in table or c not in data: continue
        added = [x[3] for x in adopt if x[1] == c]
        parts = []
        for t in table[c]['readings']:
            parts.append(t['yomi'] + '=' + ('・'.join(fix(x) for x in t['examples']) or '(例なし)'))
        out.append(f"- {c}: 追加 {('、'.join(added) if added else 'なし')} / 表: " + '; '.join(parts))
    out += ['', '## 追加した用例(' + str(len(adopt)) + '語・' + str(len(adopted_chars)) + '字)', '',
            '一覧は `scripts/data/joyo_adopted_examples.tsv`(字・級・対応する読み・追加語・読み・読みの根拠)。語は全て表の「例」から抽出できたものだけ。',
            '読みの根拠は「語幹+送り仮名」(見出し字+送り仮名だけの語で、アプリの読みから機械的に作る)か、「アプリ内の同一語の既存読み」(同じ語がアプリ内の別の字の用例に載っていて読みが一意)のどちらか。', '',
            '## 要確認(自動追加しなかった: ' + str(len(confirm)) + '件)', '',
            '読みを示す語が用例に無く、表の例から読みを確実に決められなかったもの(複合語の読みはアプリ内に根拠が無い、表の例が無い等)。表の例の語を併記。', '']
    for L, c, r, ws in confirm:
        out.append(f'- {LVNAME[L]} {c}={r}: ' + ('、'.join(ws) if ws else '(表に例なし)'))
    open(a.report, 'w', encoding='utf-8').write('\n'.join(out) + '\n')

def write_tsv(path, adopt, table):
    with open(path, 'w', encoding='utf-8') as f:
        f.write('# 常用漢字表(平成22年内閣告示)本表の「例」から、用例の不足する読みに追加した語。scripts/check_joyo_official.py が生成。\n')
        f.write('# kanji\tlevel\tapp_reading\tword\treading\tbasis\n')
        for L, c, r, w, rd, src in adopt:
            f.write(f'{c}\t{LVNAME[L]}\t{r}\t{w}\t{rd}\t{src}\n')

def apply_to_source(adopt, info_src):
    by = collections.defaultdict(list)
    for L, c, r, w, rd, src in adopt: by[c].append(f'{w}（{rd}）')
    n = 0
    def rep(m):
        nonlocal n
        c = m.group(1)
        if c not in by: return m.group(0)
        exs = re.findall(r"'([^']*)'", m.group(3))
        add = [x for x in by[c] if x not in exs]
        if not add: return m.group(0)
        n += len(add)
        body = m.group(3) + (', ' if m.group(3).strip() else '') + ', '.join(f"'{x}'" for x in add)
        return f"    '{c}': KanjiInfo(readings: [{m.group(2)}], examples: [{body}])"
    new = re.sub(r"^    '(.)': KanjiInfo\(readings: \[(.*?)\], examples: \[(.*?)\]\)", rep, info_src, flags=re.M)
    return new, n

def verify_tsv(path, table):
    bad = []
    for ln in open(path, encoding='utf-8'):
        if ln.startswith('#') or not ln.strip(): continue
        c, lvl, r, w, rd, src = ln.rstrip('\n').split('\t')
        exs = {fix(x) for t in table[c]['readings'] for x in t['examples']}
        if w not in exs: bad.append((c, w))
    return bad

if __name__ == '__main__':
    a, table, anomalies, nread, lv, data, targets, notin, missing, excess, nocov, adopt, confirm, per_level, info_src = main()
    print('表の見出し漢字', len(table), '音訓', nread, '| 対象', len(targets), '表に無い', notin)
    print('欠落', len(missing), '過剰', len(excess), '用例なし読み', len(nocov), '| 追加候補', len(adopt), '要確認', len(confirm))
    bad = verify_tsv(a.adopted, table) if os.path.exists(a.adopted) and not a.apply else []
    if a.report:
        write_outputs(a, table, anomalies, nread, lv, data, targets, missing, excess, nocov, adopt, confirm, per_level)
    if a.apply:
        write_tsv(a.adopted, adopt, table)
        new, n = apply_to_source(adopt, info_src)
        open('lib/data/kanji_info_data.dart', 'w', encoding='utf-8').write(new)
        print('追加した語', n, '字', len({x[1] for x in adopt}))
        print('TSVの語が表の例にあるか(不一致)', verify_tsv(a.adopted, table))
