#!/usr/bin/env python3
"""故事・諺の演習データ(lib/data/koji_data.dart)を、scripts/data/koji_kotowaza.tsv から作る。

  python3 -I scripts/generate_koji_data.py

TSV は「故事成語・諺<TAB>読み(ひらがな。読点は入れない)<TAB>意味(私が自分の言葉で書いた短い説明)」。
漢検の「故事・諺」（準1級・1級）に合わせた、空欄に入る漢字を答える演習に使う。
次の語は入れない（はじく）。
  ・10級〜1級の配当漢字(lib/data/level_kanji_data.dart)に無い字を含む語
各語の「難しさ」は、含む字のうち最も難しい級。この級以下の演習で出す（準1級・1級だけで出題）。
"""
import re
import sys

ORDER = {'LEVEL_10': 10, 'LEVEL_9': 9, 'LEVEL_8': 8, 'LEVEL_7': 7, 'LEVEL_6': 6,
         'LEVEL_5': 5, 'LEVEL_4': 4, 'LEVEL_3': 3, 'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2,
         'LEVEL_1_PRE': 1.5, 'LEVEL_1': 1}
LEVEL_NAME = {v: k for k, v in ORDER.items()}
KANJI = re.compile(r'[一-鿿]')

src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
kanji_level = {}
for m in re.finditer(r"'(LEVEL_\w+)':\s*'([^']*)'", src):
    if m.group(1) in ORDER:
        for c in m.group(2):
            kanji_level[c] = ORDER[m.group(1)]

rows, seen, errors, dropped = [], set(), [], []
for n, line in enumerate(open('scripts/data/koji_kotowaza.tsv', encoding='utf-8'), 1):
    line = line.rstrip('\n')
    if not line:
        continue
    f = line.split('\t')
    if len(f) != 3 or not f[2].strip():
        errors.append((n, line))
        continue
    phrase, reading, meaning = f
    if phrase in seen:
        errors.append((n, '重複: ' + phrase))
        continue
    seen.add(phrase)
    chars = [c for c in phrase if KANJI.match(c)]
    if len(chars) < 2 or any(c not in kanji_level for c in chars):
        dropped.append(phrase)
        continue
    rows.append((phrase, reading, meaning, LEVEL_NAME[min(kanji_level[c] for c in chars)]))
if errors:
    for e in errors:
        print('ERROR', e)
    sys.exit(1)

esc = lambda s: s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
out = [
    '// GENERATED FILE - do not edit by hand. Run scripts/generate_koji_data.py.',
    '//',
    '// 故事・諺の演習（漢検の「故事・諺」。準1級・1級で出題）に使う語・読み・意味。',
    '// 元データ: scripts/data/koji_kotowaza.tsv。全ての字が10級〜1級の配当漢字にある語だけを入れている。',
    '',
    'class KojiItem {',
    '  final String phrase; // 故事成語・諺（例: 「一を聞いて十を知る」「蛇足」）',
    '  final String reading; // ひらがな（読点なし）',
    '  final String meaning;',
    "  /// この語に含まれる最も難しい字の級（例: 'LEVEL_1_PRE'）。この級以下の演習で出す。",
    '  final String level;',
    '',
    '  const KojiItem(this.phrase, this.reading, this.meaning, this.level);',
    '}',
    '',
    'const List<KojiItem> kKoji = [',
]
for p, r, m, l in rows:
    out.append("  KojiItem('%s', '%s', '%s', '%s')," % (esc(p), esc(r), esc(m), l))
out += ['];', '']
open('lib/data/koji_data.dart', 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('wrote', len(rows), '語 はじいた:', dropped)
