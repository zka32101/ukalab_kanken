"""日本語版ウィクショナリー(CC BY-SA 4.0)の「四字熟語」「故事成語」カテゴリの項目を取得する。

  python3 -I scripts/fetch_wiktionary_idioms.py wiktionary_idioms.json

準1級・1級向けの語彙データの「候補」を作る元データ。出力はこのリポジトリに入れない
(取り込む語は、extract_wiktionary_yoji_candidates.py で整えて、人が確認したものだけ)。
レート制限(429)のときは待って再試行する。
"""
import json, sys, time, urllib.error, urllib.parse, urllib.request

API = 'https://ja.wiktionary.org/w/api.php'
UA = {'User-Agent': 'ukalab-kanken-data-research/0.1 (zka32101 personal project; contact via GitHub)'}


def get(params):
    url = API + '?' + urllib.parse.urlencode(params)
    for wait in (5, 20, 60, 120, 0):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code != 429 or wait == 0:
                raise
            print('429, wait', wait, file=sys.stderr)
            time.sleep(wait)


def members(cat):
    out, cont = [], {}
    while True:
        d = get({'action': 'query', 'list': 'categorymembers', 'cmtitle': cat, 'cmlimit': 500,
                 'cmnamespace': 0, 'format': 'json', **cont})
        out += [m['title'] for m in d['query']['categorymembers']]
        if 'continue' not in d:
            return out
        cont = d['continue']


def wikitext(titles):
    res = {}
    for i in range(0, len(titles), 20):
        chunk = titles[i:i + 20]
        d = get({'action': 'query', 'prop': 'revisions', 'rvprop': 'content', 'rvslots': 'main',
                 'titles': '|'.join(chunk), 'format': 'json'})
        for p in d['query']['pages'].values():
            revs = p.get('revisions')
            if revs:
                res[p['title']] = revs[0]['slots']['main']['*']
        time.sleep(3)
    return res


out = {}
for key, cat in [('yoji', 'Category:四字熟語'), ('koji', 'Category:故事成語')]:
    ts = members(cat)
    print(key, len(ts), file=sys.stderr)
    out[key] = wikitext(ts)
json.dump(out, open(sys.argv[1], 'w', encoding='utf-8'), ensure_ascii=False)
print('saved', {k: len(v) for k, v in out.items()})
