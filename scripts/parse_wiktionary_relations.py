"""日本語版ウィクショナリー(CC BY-SA 4.0)のダンプから、2字熟語の「類義語」「対義語」欄の組を取り出す。

  curl -O https://dumps.wikimedia.org/jawiktionary/latest/jawiktionary-latest-pages-articles.xml.bz2
  python3 -I scripts/parse_wiktionary_relations.py jawiktionary-latest-pages-articles.xml.bz2 wiktionary_relations.json

出力は {語: {"syn": [...], "ant": [...]}}。extract_word_relation_candidates.py の入力。
"""
import bz2, re, json, sys, collections
import xml.etree.ElementTree as ET

K2 = re.compile(r'^[一-鿿]{2}$')
LINK = re.compile(r'\[\[(?:[^\]|]*\|)?([^\]]+)\]\]')
out = {}  # title -> {'syn': [...], 'ant': [...], 'defs': [...]}
n = 0
with bz2.open(sys.argv[1], 'rb') as f:
    for ev, el in ET.iterparse(f, events=('end',)):
        tag = el.tag.rsplit('}', 1)[-1]
        if tag != 'page':
            continue
        title = el.findtext('{*}title') or ''
        ns = el.findtext('{*}ns')
        if ns == '0' and K2.match(title):
            text = el.findtext('{*}revision/{*}text') or ''
            syn, ant = [], []
            # 「類義語」「対義語」の見出し（{{syn}} {{ant}} テンプレートまたは見出し文字列）以降の箇条書き
            for kind, pat in (('syn', r'(?:\{\{syn\}\}|類義語|類語|同義語)'), ('ant', r'(?:\{\{ant\}\}|対義語|反対語|反義語)')):
                for m in re.finditer(r'^[=*:\s]*' + pat + r'[=:\s]*(.*)$', text, re.M):
                    seg = m.group(1)
                    # 同じ行と、続く箇条書き（次の見出しまで、最大10行）を見る
                    rest = text[m.end(): m.end() + 600].split('\n')
                    lines = [seg]
                    for ln in rest[1:11]:
                        if ln.startswith('=') or ln.startswith('{{'):
                            break
                        lines.append(ln)
                    for ln in lines:
                        for w in LINK.findall(ln):
                            if K2.match(w) and w != title:
                                (syn if kind == 'syn' else ant).append(w)
            if syn or ant:
                out[title] = {'syn': sorted(set(syn)), 'ant': sorted(set(ant))}
        el.clear()
        n += 1
        if n % 200000 == 0:
            print(n, len(out), file=sys.stderr)
json.dump(out, open(sys.argv[2], 'w', encoding='utf-8'), ensure_ascii=False)
print('entries with relations', len(out), 'syn pairs', sum(len(v['syn']) for v in out.values()), 'ant pairs', sum(len(v['ant']) for v in out.values()))
