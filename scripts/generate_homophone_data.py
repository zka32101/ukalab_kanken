#!/usr/bin/env python3
"""同音・同訓異字の演習データ(lib/data/homophone_data.dart)を、scripts/data/homophones.tsv から作る。

  python3 -I scripts/generate_homophone_data.py

TSV は「種類(音=同音異字/訓=同訓異字)<TAB>読み<TAB>文(読みを【】で囲む)<TAB>正解<TAB>誤答(読点区切り)」。
文は、【】の中が「読み」と同じで、【】が1回だけ入っていること。誤答は正解と別で、重複しないこと。
次の組ははじく。
  ・正解・誤答・文に、10級〜2級の配当漢字(lib/data/level_kanji_data.dart)に無い字がある(ひらがな・記号は可)
各組の「難しさ」は、文と選択肢の字のうち最も難しい級。この級以下の演習で出す。
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

KANJI = re.compile(r'[一-鿿]')
rows, dropped, errors = [], [], []
for n, line in enumerate(open('scripts/data/homophones.tsv', encoding='utf-8'), 1):
    line = line.rstrip('\n')
    if not line:
        continue
    kind, reading, sentence, answer, wrong = line.split('\t')
    wrongs = wrong.split(',')
    if sentence.count('【' + reading + '】') != 1 or sentence.count('【') != 1:
        errors.append((n, '文の【】が読みと合わない', sentence))
    if answer in wrongs or len(set(wrongs)) != len(wrongs) or len(wrongs) < 1:
        errors.append((n, '誤答が正解と重複・不足', line))
    chars = [c for c in sentence + answer + ''.join(wrongs) if KANJI.match(c)]
    unknown = [c for c in chars if c not in kanji_level]
    if unknown:
        dropped.append((reading, answer, sorted(set(unknown))))
        continue
    hardest = min(kanji_level[c] for c in chars)
    rows.append((kind, reading, sentence, answer, wrongs, LEVEL_NAME[hardest]))
if errors:
    for e in errors:
        print('ERROR', e)
    sys.exit(1)

out = [
    '// GENERATED FILE - do not edit by hand. Run scripts/generate_homophone_data.py.',
    '//',
    '// 同音・同訓異字の演習（漢検の「同音・同訓異字」。同音異字は7級〜、同訓異字は6級〜2級で出題）に使う組。',
    '// 元データ: scripts/data/homophones.tsv。文・選択肢の全ての字が10級〜2級の配当漢字にある組だけを入れている。',
    '',
    'enum HomophoneKind { homophone, homograph }',
    '',
    'class HomophoneQuestion {',
    '  final HomophoneKind kind;',
    '  final String reading; // ひらがな',
    '  /// 文。読みを【】で囲んである（例: 「友だちと【こうえん】であそぶ。」）。',
    '  final String sentence;',
    '  final String answer;',
    '  final List<String> wrong; // 紛らわしい誤答（同じ読みの別の字・語）',
    '  /// 文と選択肢の字のうち最も難しい字の級（例: \'LEVEL_5\'）。この級以下の演習で出す。',
    '  final String level;',
    '',
    '  const HomophoneQuestion(',
    '      this.kind, this.reading, this.sentence, this.answer, this.wrong, this.level);',
    '}',
    '',
    'const List<HomophoneQuestion> kHomophoneQuestions = [',
]
for kind, reading, sentence, answer, wrongs, level in rows:
    k = 'HomophoneKind.homophone' if kind == '音' else 'HomophoneKind.homograph'
    w = ', '.join("'%s'" % x for x in wrongs)
    out.append("  HomophoneQuestion(%s, '%s', '%s', '%s', [%s], '%s')," % (k, reading, sentence, answer, w, level))
out += ['];', '']
open('lib/data/homophone_data.dart', 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('wrote', len(rows), '問', 'はじいた:', len(dropped), dropped[:10])
