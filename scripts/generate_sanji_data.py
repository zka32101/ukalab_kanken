#!/usr/bin/env python3
"""三字熟語の演習データ(lib/data/sanji_jukugo_data.dart)を、scripts/data/sanji_jukugo.tsv から作る。

  python3 -I scripts/generate_sanji_data.py

漢検の「三字熟語」(6級・7級)の練習問題でよく使われる形（三字熟語の1字をカタカナにして、
その漢字を書かせる。例: 『フ可能』→ 不）。公式の例題は確認できなかったので、複数の練習サイトで
共通する形に合わせている。
TSV は「三字熟語<TAB>1字目の読み<TAB>2字目の読み<TAB>3字目の読み」(読みは、その熟語での読み。カタカナ)。
次の語はあはじく。
  ・3字でない語、読みがカタカナでない語
  ・10級〜2級の配当漢字(lib/data/level_kanji_data.dart)に無い字を含む語
各語の「難しさ」は、含む字のうち最も難しい級。この級以下の演習で出す。
"""
import re
import sys

ORDER = {'LEVEL_10': 10, 'LEVEL_9': 9, 'LEVEL_8': 8, 'LEVEL_7': 7, 'LEVEL_6': 6,
         'LEVEL_5': 5, 'LEVEL_4': 4, 'LEVEL_3': 3, 'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2}
LEVEL_NAME = {v: k for k, v in ORDER.items()}

src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
kanji_level = {}
for m in re.finditer(r"'(LEVEL_\w+)':\s*'([^']*)'", src):
    if m.group(1) in ORDER:
        for c in m.group(2):
            kanji_level[c] = ORDER[m.group(1)]

KATAKANA = re.compile(r'^[ァ-ヶー]+$')
rows, seen, dropped, errors = [], set(), [], []
for line in open('scripts/data/sanji_jukugo.tsv', encoding='utf-8'):
    line = line.rstrip('\n')
    if not line:
        continue
    f = line.split('\t')
    word, readings = f[0], f[1:]
    if len(word) != 3 or len(readings) != 3 or not all(KATAKANA.match(r) for r in readings):
        errors.append(line)
        continue
    if word in seen:
        errors.append('重複: ' + word)
        continue
    seen.add(word)
    if any(c not in kanji_level for c in word):
        dropped.append(word)
        continue
    rows.append((word, readings, LEVEL_NAME[min(kanji_level[c] for c in word)]))
if errors:
    for e in errors:
        print('ERROR', e)
    sys.exit(1)

out = [
    '// GENERATED FILE - do not edit by hand. Run scripts/generate_sanji_data.py.',
    '//',
    '// 三字熟語の演習（漢検の「三字熟語」。7級・6級で出題）に使う語と、各字の読み。',
    '// 元データ: scripts/data/sanji_jukugo.tsv。全ての字が10級〜2級の配当漢字にある語だけを入れている。',
    '',
    'class SanjiJukugo {',
    '  final String word;',
    '',
    '  /// 各字の、この熟語での読み（カタカナ。例: 不可能 → フ・カ・ノウ）。',
    '  final List<String> readings;',
    '',
    "  /// 含む字のうち最も難しい字の級（例: 'LEVEL_6'）。この級以下の演習で出す。",
    '  final String level;',
    '',
    '  const SanjiJukugo(this.word, this.readings, this.level);',
    '}',
    '',
    'const List<SanjiJukugo> kSanjiJukugo = [',
]
for word, readings, level in rows:
    out.append("  SanjiJukugo('%s', [%s], '%s')," % (word, ', '.join("'%s'" % r for r in readings), level))
out += ['];', '']
open('lib/data/sanji_jukugo_data.dart', 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('wrote', len(rows), '語', 'はじいた:', dropped)
