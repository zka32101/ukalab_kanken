#!/usr/bin/env python3
"""対義語・類義語の演習データ(lib/data/word_relation_data.dart)を、scripts/data/word_relations.tsv から作る。

  python3 -I scripts/generate_word_relations.py

TSV は「種類(対=対義語/類=類義語)<TAB>語<TAB>読み<TAB>相手の語<TAB>相手の読み<TAB>分野」。
次の組ははじく。
  ・どちらかの語に、10級〜2級の配当漢字(lib/data/level_kanji_data.dart)に無い字がある
  ・同じ種類で、同じ組(順序違いも)が重複している
「分野」は、選択肢の紛らわしい候補が、正解と意味の近い語にならないよう、別の分野から選ぶための目印。
各組の「難しさ」は、2語の字のうち最も難しい級。この級以下の演習で出す。
"""
import re

ORDER = {'LEVEL_10': 10, 'LEVEL_9': 9, 'LEVEL_8': 8, 'LEVEL_7': 7, 'LEVEL_6': 6,
         'LEVEL_5': 5, 'LEVEL_4': 4, 'LEVEL_3': 3, 'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2,
         'LEVEL_1_PRE': 1.5, 'LEVEL_1': 1}
LEVEL_NAME = {v: k for k, v in ORDER.items()}

src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
kanji_level = {}
for m in re.finditer(r"'(LEVEL_\w+)':\s*'([^']*)'", src):
    if m.group(1) in ORDER:
        for c in m.group(2):
            kanji_level[c] = ORDER[m.group(1)]

rows, seen, dropped = [], set(), []
for line in open('scripts/data/word_relations.tsv', encoding='utf-8'):
    line = line.rstrip('\n')
    if not line:
        continue
    kind, w1, r1, w2, r2, group = line.split('\t')
    chars = w1 + w2
    if any(c not in kanji_level for c in chars):
        dropped.append((w1, w2, [c for c in chars if c not in kanji_level]))
        continue
    key = (kind, frozenset([w1, w2]))
    if key in seen:
        continue
    seen.add(key)
    hardest = min(kanji_level[c] for c in chars)
    rows.append((kind, w1, r1, w2, r2, group, LEVEL_NAME[hardest]))

out = [
    '// GENERATED FILE - do not edit by hand. Run scripts/generate_word_relations.py.',
    '//',
    '// 対義語・類義語の演習（漢検の「対義語・類義語」。8級〜2級で出題）に使う組。',
    '// 元データ: scripts/data/word_relations.tsv。全ての字が10級〜2級の配当漢字にある組だけを入れている。',
    '',
    'enum WordRelationKind { antonym, synonym }',
    '',
    'class WordRelation {',
    '  final WordRelationKind kind;',
    '  final String word;',
    '  final String reading; // ひらがな',
    '  final String partner; // 対義語、または類義語',
    '  final String partnerReading;',
    '  /// 意味の分野。選択肢の紛らわしい候補は、別の分野から選ぶ。',
    '  final String group;',
    '  /// 2語の字のうち最も難しい字の級（例: \'LEVEL_5\'）。この級以下の演習で出す。',
    '  final String level;',
    '',
    '  const WordRelation(',
    '      this.kind, this.word, this.reading, this.partner, this.partnerReading, this.group, this.level);',
    '}',
    '',
    'const List<WordRelation> kWordRelations = [',
]
for kind, w1, r1, w2, r2, g, l in rows:
    k = 'WordRelationKind.antonym' if kind == '対' else 'WordRelationKind.synonym'
    out.append("  WordRelation(%s, '%s', '%s', '%s', '%s', '%s', '%s')," % (k, w1, r1, w2, r2, g, l))
out += ['];', '']
open('lib/data/word_relation_data.dart', 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('wrote', len(rows), '組', 'はじいた:', dropped)
