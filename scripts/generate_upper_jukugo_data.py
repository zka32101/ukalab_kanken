#!/usr/bin/env python3
"""準1級・1級の熟語（読み・書き取りの出題用）の lib/data/upper_jukugo_data.dart を作る。

  python3 -I scripts/generate_upper_jukugo_data.py

元データ: scripts/data/upper_jukugo_pool.tsv（extract_upper_jukugo_pool.py が作る）。
子ども向けに不適切な字・語は除く。出典の表示は lib/screens/settings_screen.dart の appCredits。
"""
BAD_CHARS = set('姦淫媾婬睾陰娼糞屎尿屁痔瘡癪妾蠱')
BAD_WORDS = {'喀痰', '鼾睡', '癌腫', '下疳', '疳性', '癇性', '癇症', '衣嚢', '縊殺'}

rows = []
for n, line in enumerate(open('scripts/data/upper_jukugo_pool.tsv', encoding='utf-8')):
    f = line.rstrip('\n').split('\t')
    if n == 0 or len(f) < 4:
        continue
    word, reading = f[0], f[1]
    if set(word) & BAD_CHARS or word in BAD_WORDS:
        continue
    rows.append((word, reading))

out = [
    '// GENERATED FILE - do not edit by hand. Run scripts/generate_upper_jukugo_data.py.',
    '//',
    '// 準1級・1級の配当漢字を含む二字熟語と読み（熟語の読み・書き取りの演習用）。',
    '// 元データ: scripts/data/upper_jukugo_pool.tsv。JMdict（EDRDG, CC BY-SA 4.0）・',
    '// ウィクショナリー日本語版（CC BY-SA 4.0）・日本語WordNet（NICT）で確かめた語。',
    '// 読みは KANJIDIC2 の漢字ごとの読みに分けられるものだけ。',
    '',
    'const Map<String, String> kUpperJukugo = {',
]
for w, r in rows:
    out.append("  '%s': '%s'," % (w, r))
out.append('};')
open('lib/data/upper_jukugo_data.dart', 'w', encoding='utf-8', newline='\n').write('\n'.join(out) + '\n')
print(len(rows), 'words')
