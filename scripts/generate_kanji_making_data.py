#!/usr/bin/env python3
"""「漢字作り」の演習データ(lib/data/kanji_making_data.dart)を、scripts/data/kanji_making.tsv から作る。

  python3 -I scripts/generate_kanji_making_data.py

漢検の例題(受検級の目安チェック 6級・7級)の形式。
  R(同じ読みの漢字): 「A・B・Cには『ケン』と読む漢字が入ります」。
     TSV: R<TAB>読み<TAB>語○|答え (2〜3個)<TAB>紛らわしい字(読点区切り)
     例: R  けん  条○|件  ○設|建  ○査|検  健,研,県
     → 問題 『条A・B設・C査』、正解 A件 B建 C検。
     誤答の組み合わせは、正解の字を並べ替えたもの(2つ。字が2個のときは1つ)と、正解の字を
     紛らわしい字に1つ置き換えたもの、から2つ作る。
  S(同じ字を挟む2つの熟語): 「AとBに入る漢字の組み合わせ」。
     TSV: S<TAB>共通の字<TAB>Aの答え<TAB>Bの答え<TAB>誤答の組(「A,B;A,B」)
     例: S  景  夜  品  信,色;結,面  → 問題 『A景・景B』、正解 A夜 B品。

次の組ははじく。
  ・問題・答え・誤答に、10級〜2級の配当漢字(lib/data/level_kanji_data.dart)に無い字がある
各組の「難しさ」は、使う字のうち最も難しい級。この級以下の演習で出す。
"""
import re
import sys

ORDER = {'LEVEL_10': 10, 'LEVEL_9': 9, 'LEVEL_8': 8, 'LEVEL_7': 7, 'LEVEL_6': 6,
         'LEVEL_5': 5, 'LEVEL_4': 4, 'LEVEL_3': 3, 'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2}
LEVEL_NAME = {v: k for k, v in ORDER.items()}
LABELS = 'ABC'

src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
kanji_level = {}
for m in re.finditer(r"'(LEVEL_\w+)':\s*'([^']*)'", src):
    if m.group(1) in ORDER:
        for c in m.group(2):
            kanji_level[c] = ORDER[m.group(1)]

KANJI = re.compile(r'[一-鿿]')
rows, dropped, errors = [], [], []


def check(cond, msg, line):
    if not cond:
        errors.append((msg, line))


for n, line in enumerate(open('scripts/data/kanji_making.tsv', encoding='utf-8'), 1):
    line = line.rstrip('\n')
    if not line:
        continue
    f = line.split('\t')
    kind = f[0]
    if kind == 'R':
        reading = f[1]
        slots = f[2:-1]
        extras = f[-1].split(',')
        check(2 <= len(slots) <= 3, 'R は2〜3個', line)
        words, answers = [], []
        for s in slots:
            word, ans = s.split('|')
            check(word.count('○') == 1 and len(word) == 2 and len(ans) == 1, '語は2字で○が1つ、答えは1字', line)
            words.append(word)
            answers.append(ans)
        check(len(set(answers)) == len(answers), '答えの字が重複', line)
        check(all(e not in answers for e in extras) and len(set(extras)) == len(extras), '紛らわしい字が答えと重複', line)
        # 問題: ○ を A・B・C に置き換えて並べる
        prompt = '・'.join(w.replace('○', LABELS[i]) for i, w in enumerate(words))
        k = len(answers)
        wrongs = []
        for shift in (1, 2):
            if shift < k:
                rot = answers[shift:] + answers[:shift]
                if rot != answers and rot not in wrongs:
                    wrongs.append(rot)
        sub = list(answers)
        sub[0] = extras[0]
        wrongs.append(sub)
        sub2 = list(answers)
        sub2[-1] = extras[1] if len(extras) > 1 else extras[0]
        if sub2 not in wrongs:
            wrongs.append(sub2)
        wrongs = wrongs[:2]
        instruction = '%s には「%s」と読む漢字が入ります。正しい組み合わせはどれ？' % (
            '・'.join(LABELS[:k]), reading)
        used = ''.join(words).replace('○', '') + ''.join(answers) + ''.join(extras)
    elif kind == 'S':
        shared, a, b, wr = f[1], f[2], f[3], f[4]
        check(len(shared) == 1 and len(a) == 1 and len(b) == 1, 'S は1字ずつ', line)
        answers = [a, b]
        wrongs = []
        for pair in wr.split(';'):
            x, y = pair.split(',')
            check(len(x) == 1 and len(y) == 1 and [x, y] != answers, '誤答の組が不正', line)
            wrongs.append([x, y])
        check(len(wrongs) >= 2, '誤答は2組', line)
        prompt = 'A%s・%sB' % (shared, shared)
        instruction = 'AとBに入る漢字の組み合わせはどれ？'
        used = shared + a + b + ''.join(''.join(w) for w in wrongs)
    else:
        errors.append(('種類が不明', line))
        continue
    unknown = [c for c in used if KANJI.match(c) and c not in kanji_level]
    if unknown:
        dropped.append((prompt, sorted(set(unknown))))
        continue
    hardest = min(kanji_level[c] for c in used if KANJI.match(c))
    rows.append((prompt, instruction, answers, wrongs[:2], LEVEL_NAME[hardest]))

if errors:
    for e in errors:
        print('ERROR', e)
    sys.exit(1)


def lit(xs):
    return '[' + ', '.join("'%s'" % x for x in xs) + ']'


out = [
    '// GENERATED FILE - do not edit by hand. Run scripts/generate_kanji_making_data.py.',
    '//',
    '// 漢字作りの演習（漢検の「漢字作り」。7級〜2級で出題）に使う問題。',
    '// 元データ: scripts/data/kanji_making.tsv。全ての字が10級〜2級の配当漢字にある問題だけを入れている。',
    '',
    'class KanjiMakingItem {',
    "  /// 問題の表示（例: 『条A・B設・C査』『A景・景B』）。",
    '  final String prompt;',
    '  final String instruction;',
    '',
    '  /// A・B・C に入る漢字（正解）と、誤った組み合わせ2つ（どれも A・B・C の並び）。',
    '  final List<String> answer;',
    '  final List<List<String>> wrong;',
    '',
    "  /// 使う字のうち最も難しい字の級（例: 'LEVEL_5'）。この級以下の演習で出す。",
    '  final String level;',
    '',
    '  const KanjiMakingItem(this.prompt, this.instruction, this.answer, this.wrong, this.level);',
    '}',
    '',
    'const List<KanjiMakingItem> kKanjiMaking = [',
]
for prompt, instruction, answers, wrongs, level in rows:
    out.append("  KanjiMakingItem('%s', '%s', %s, [%s], '%s')," % (
        prompt, instruction, lit(answers), ', '.join(lit(w) for w in wrongs), level))
out += ['];', '']
open('lib/data/kanji_making_data.dart', 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('wrote', len(rows), '問', 'はじいた:', dropped)
