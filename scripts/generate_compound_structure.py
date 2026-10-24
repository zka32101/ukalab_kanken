#!/usr/bin/env python3
"""熟語の構成の演習データ(lib/data/compound_structure_data.dart)を、scripts/data/compound_structure.tsv から作る。

  python3 -I scripts/generate_compound_structure.py

TSV は「二字熟語<TAB>読み(ひらがな)<TAB>種類(ア〜オ)」。漢検の熟語の構成の区分に合わせる。
  ア 同じような意味の漢字を重ねたもの   イ 反対や対になる意味の漢字を重ねたもの
  ウ 上の字が下の字を修飾しているもの   エ 下の字が上の字の目的語・補語になっているもの
  オ 上の字が下の字を打ち消しているもの（不・無・非・未）
次の語は入れない（はじく）。
  ・2字でない語
  ・10級〜2級の配当漢字(lib/data/level_kanji_data.dart)に無い字を含む語
各語の「難しさ」は、2字のうち最も難しい級。この級以下の演習で出す（上の級ほど、やさしい級の語も出る）。
"""
import re
import sys

ORDER = {'LEVEL_10': 10, 'LEVEL_9': 9, 'LEVEL_8': 8, 'LEVEL_7': 7, 'LEVEL_6': 6,
         'LEVEL_5': 5, 'LEVEL_4': 4, 'LEVEL_3': 3, 'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2}
LEVEL_NAME = {v: k for k, v in ORDER.items()}
TYPE = {'ア': 'similarMeaning', 'イ': 'oppositeMeaning', 'ウ': 'modifier', 'エ': 'verbObject', 'オ': 'negation'}

src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
kanji_level = {}
for m in re.finditer(r"'(LEVEL_\w+)':\s*'([^']*)'", src):
    if m.group(1) in ORDER:
        for c in m.group(2):
            kanji_level[c] = ORDER[m.group(1)]

rows, seen, errors = [], set(), []
for n, line in enumerate(open('scripts/data/compound_structure.tsv', encoding='utf-8'), 1):
    line = line.rstrip('\n')
    if not line:
        continue
    word, reading, kind = line.split('\t')
    if len(word) != 2 or any(c not in kanji_level for c in word) or kind not in TYPE:
        errors.append((n, line))
        continue
    if not re.fullmatch(r'[ぁ-ゖー]+', reading):
        errors.append((n, line))
        continue
    if word in seen:
        errors.append((n, '重複: ' + line))
        continue
    seen.add(word)
    rows.append((LEVEL_NAME[min(kanji_level[c] for c in word)], word, reading, TYPE[kind]))
if errors:
    for e in errors:
        print('ERROR', e)
    sys.exit(1)
rows.sort(key=lambda r: (-ORDER[r[0]], r[1]))

out = [
    '// GENERATED FILE - do not edit by hand. Run scripts/generate_compound_structure.py.',
    '//',
    '// 熟語の構成問題（漢検の「熟語の構成」＝二字熟語の成り立ち）のデータ。',
    '// 元データ: scripts/data/compound_structure.tsv。漢検の区分（ア〜オ）に沿った5パターンで分類する。',
    '',
    'enum CompoundStructureType {',
    '  /// ア: 同じような意味の漢字を重ねたもの（例: 岩石）',
    '  similarMeaning,',
    '',
    '  /// イ: 反対や対になる意味の漢字を重ねたもの（例: 明暗）',
    '  oppositeMeaning,',
    '',
    '  /// ウ: 上の字が下の字を修飾しているもの（例: 洋画）',
    '  modifier,',
    '',
    '  /// エ: 下の字が上の字の目的語・補語になっているもの（例: 消火）',
    '  verbObject,',
    '',
    '  /// オ: 上の字が下の字を打ち消しているもの（例: 非常。不・無・非・未）',
    '  negation,',
    '}',
    '',
    'const Map<CompoundStructureType, String> compoundStructureLabels = {',
    "  CompoundStructureType.similarMeaning: '似た意味の漢字を重ねたもの',",
    "  CompoundStructureType.oppositeMeaning: '反対や対になる意味の漢字を重ねたもの',",
    "  CompoundStructureType.modifier: '上の字が下の字を修飾しているもの',",
    "  CompoundStructureType.verbObject: '下の字が上の字の目的語・補語になっているもの',",
    "  CompoundStructureType.negation: '上の字が下の字を打ち消しているもの',",
    '};',
    '',
    'class CompoundQuestion {',
    "  final String level; // この語に含まれる最も難しい字の級（例: 'LEVEL_5'）。この級以下の演習で出す",
    '  final String jukugo;',
    '  final String reading;',
    '  final CompoundStructureType structureType;',
    '',
    '  const CompoundQuestion({',
    '    required this.level,',
    '    required this.jukugo,',
    '    required this.reading,',
    '    required this.structureType,',
    '  });',
    '',
    '  String get correctLabel => compoundStructureLabels[structureType]!;',
    '}',
    '',
    'class CompoundStructureData {',
    '  CompoundStructureData._();',
    '',
    '  /// 級を「難しさの順位」にする（10級=10 … 2級=2、準2級=2.5）。',
    '  static const Map<String, double> _rank = {',
    "    'LEVEL_10': 10, 'LEVEL_9': 9, 'LEVEL_8': 8, 'LEVEL_7': 7, 'LEVEL_6': 6,",
    "    'LEVEL_5': 5, 'LEVEL_4': 4, 'LEVEL_3': 3, 'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2,",
    '  };',
    '',
    '  static const List<CompoundQuestion> all = [',
]
for lvl, w, r, t in rows:
    out.append("    CompoundQuestion(level: '%s', jukugo: '%s', reading: '%s', structureType: CompoundStructureType.%s)," % (lvl, w, r, t))
out += [
    '  ];',
    '',
    '  /// 指定の級の演習で出す語（その級以下の字だけの語。上の級ほど、やさしい級の語も出る）。',
    '  /// 準1級・1級（_rank に無い級）は、全部の語。',
    '  static List<CompoundQuestion> forLevel(String level) {',
    '    final rank = _rank[level] ?? 0;',
    '    return all.where((q) => (_rank[q.level] ?? 0) >= rank).toList();',
    '  }',
    '}',
    '',
]
open('lib/data/compound_structure_data.dart', 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
print('wrote', len(rows), 'words')
