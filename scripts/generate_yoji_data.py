#!/usr/bin/env python3
"""四字熟語の演習データ(lib/data/yoji_jukugo_data.dart)を、scripts/data/yoji_jukugo.tsv から作る。

  python3 -I scripts/generate_yoji_data.py

TSV は「四字熟語<TAB>読み(ひらがな)<TAB>意味」。次の語は入れない(はじく)。
  ・4字でない語
  ・10級〜1級の配当漢字(lib/data/level_kanji_data.dart)に無い字を含む語(表外字・踊り字「々」など)
各語の「難しさ」は、含む字のうち最も難しい級(10〜1。準2級は 2.5、準1級は 1.5)。この級以下の演習で出す。
意味にウィクショナリー(CC BY-SA 4.0)の文を含む。出典表示は lib/screens/settings_screen.dart の appCredits。
"""
import re

ORDER = {'LEVEL_10': 10, 'LEVEL_9': 9, 'LEVEL_8': 8, 'LEVEL_7': 7, 'LEVEL_6': 6,
         'LEVEL_5': 5, 'LEVEL_4': 4, 'LEVEL_3': 3, 'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2,
         'LEVEL_1_PRE': 1.5, 'LEVEL_1': 1}
LEVEL_NAME = {10: 'LEVEL_10', 9: 'LEVEL_9', 8: 'LEVEL_8', 7: 'LEVEL_7', 6: 'LEVEL_6', 5: 'LEVEL_5',
              4: 'LEVEL_4', 3: 'LEVEL_3', 2.5: 'LEVEL_2_PRE', 2: 'LEVEL_2',
              1.5: 'LEVEL_1_PRE', 1: 'LEVEL_1'}

src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
kanji_level = {}
for m in re.finditer(r"'(LEVEL_\w+)':\s*'([^']*)'", src):
    if m.group(1) in ORDER:
        for c in m.group(2):
            kanji_level[c] = ORDER[m.group(1)]

rows, seen = [], set()
for line in open('scripts/data/yoji_jukugo.tsv', encoding='utf-8'):
    line = line.rstrip('\n')
    if not line:
        continue
    word, reading, meaning = line.split('\t')
    if len(word) != 4 or any(c not in kanji_level for c in word) or word in seen:
        continue
    seen.add(word)
    hardest = min(kanji_level[c] for c in word)
    rows.append((word, reading, meaning, LEVEL_NAME[hardest]))

out = [
    '// GENERATED FILE - do not edit by hand. Run scripts/generate_yoji_data.py.',
    '//',
    '// 四字熟語の演習（漢検の「四字熟語」。5級〜1級で出題）に使う語・読み・意味。',
    '// 元データ: scripts/data/yoji_jukugo.tsv。全ての字が10級〜1級の配当漢字にある語だけを入れている。',
    '',
    'class YojiJukugo {',
    '  final String word;',
    '  final String reading; // ひらがな',
    '  final String meaning;',
    '  /// この語に含まれる最も難しい字の級（例: \'LEVEL_5\'）。この級以下の演習で出す。',
    '  final String level;',
    '',
    '  const YojiJukugo(this.word, this.reading, this.meaning, this.level);',
    '}',
    '',
    'const List<YojiJukugo> kYojiJukugo = [',
]
for w, r, m, l in rows:
    # Dart の文字列に安全に入れる（バックスラッシュ・引用符・$ の補間）。
    esc = lambda s: s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
    out.append("  YojiJukugo('%s', '%s', '%s', '%s')," % (esc(w), esc(r), esc(m), l))
out += ['];', '']
open('lib/data/yoji_jukugo_data.dart', 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('wrote', len(rows), 'words')
