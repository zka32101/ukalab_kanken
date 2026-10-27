#!/usr/bin/env python3
"""対義語・類義語の答え合わせに出す、語の意味(lib/data/word_meaning_data.dart)を、scripts/data/word_meanings.tsv から作る。

  python3 -I scripts/generate_word_meanings.py

TSV は「語<TAB>意味(1文)」。意味は、子ども向けに分かりやすい短い文。
同じ語が2回あるとき、読み込みはエラーにする。意味に改行・タブは入れない。
"""
import sys

rows, seen, errors = [], set(), []
for n, line in enumerate(open('scripts/data/word_meanings.tsv', encoding='utf-8'), 1):
    line = line.rstrip('\n').rstrip('\r')
    if not line:
        continue
    parts = line.split('\t')
    if len(parts) != 2 or not parts[0] or not parts[1]:
        errors.append((n, line))
        continue
    word, meaning = parts
    if word in seen:
        errors.append((n, '重複: ' + word))
        continue
    seen.add(word)
    rows.append((word, meaning))

if errors:
    for e in errors:
        print('ERROR', e)
    sys.exit(1)


def lit(s):
    bs = chr(92)
    return "'" + s.replace(bs, bs + bs).replace("'", bs + "'") + "'"


out = [
    '// GENERATED FILE - do not edit by hand. Run scripts/generate_word_meanings.py.',
    '//',
    '// 対義語・類義語の答え合わせに出す、語の意味。元データ: scripts/data/word_meanings.tsv。',
    '',
    '/// 語 -> 意味(1文)。載っていない語は、意味を出さない。',
    'const Map<String, String> kWordMeanings = {',
]
for word, meaning in rows:
    out.append('  %s: %s,' % (lit(word), lit(meaning)))
out += ['};', '']
open('lib/data/word_meaning_data.dart', 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('wrote', len(rows), '語')
