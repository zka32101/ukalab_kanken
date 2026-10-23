"""4級・3級・準2級・2級の配当漢字の書き順データ(lib/data/stroke_order_upper_data.dart)を作る。

使い方: python scripts/generate_stroke_order_upper.py <kanjivg-YYYYMMDD.xml.gz> [出力先]
KanjiVG (https://kanjivg.tagaini.net) (c) Ulrich Apel and contributors, CC BY-SA 3.0。
パスは元のSVGのまま。複数セグメントの画は既存データと同じく1文字列にまとめる。
"""
import gzip
import re
import sys
import xml.etree.ElementTree as ET

LEVELS = ['LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']
src = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else 'lib/data/stroke_order_upper_data.dart'

levels_src = open('lib/data/level_kanji_data.dart', encoding='utf-8').read()
wanted = []
for lv in LEVELS:
    wanted += list(re.search(r"'%s':\s*'([^']*)'" % lv, levels_src).group(1))

root = ET.fromstring(gzip.open(src, 'rb').read())
NS = '{http://kanjivg.tagaini.net}'
by_char = {}
for k in root.iter('kanji'):
    kid = k.get('id')  # kvg:kanji_04e00 (異体字は -Kaisho などが付く)
    m = re.fullmatch(r'kvg:kanji_([0-9a-f]{5})', kid)
    if not m:
        continue
    ch = chr(int(m.group(1), 16))
    paths = [p.get('d') for p in k.iter('path')]
    by_char[ch] = paths

missing = [c for c in wanted if c not in by_char]
if missing:
    sys.exit('KanjiVGに無い字: ' + ''.join(missing))

lines = [
    '// GENERATED FILE - do not edit by hand. Run scripts/generate_stroke_order_upper.py.',
    '//',
    '// 4級・3級・準2級・2級の配当漢字の書き順データ。KanjiVG由来。',
    '// Source: KanjiVG (https://kanjivg.tagaini.net) (c) Ulrich Apel and contributors,',
    '// licensed under Creative Commons Attribution-Share Alike 3.0',
    '// (https://creativecommons.org/licenses/by-sa/3.0/).',
    '// パスは元のSVGのまま（stroke_order_sample_data.dart と同じ形式・viewBox 109）。',
    '',
    "import '../models/stroke_order.dart';",
    '',
    '/// 4級〜2級の書き順データ。`StrokeOrderSampleData` から参照される。',
    'class StrokeOrderUpperData {',
    '  StrokeOrderUpperData._();',
    '',
    '  static final Map<String, StrokeOrderData> data = {',
]
for c in wanted:
    lines.append("    '%s': const StrokeOrderData(" % c)
    lines.append("      kanji: '%s'," % c)
    lines.append('      viewBox: 109,')
    lines.append('      strokePaths: [')
    for d in by_char[c]:
        lines.append("        '%s'," % d)
    lines.append('      ],')
    lines.append('    ),')
lines += ['  };', '}', '']
open(out, 'w', encoding='utf-8', newline='\n').write('\n'.join(lines))
print('wrote', out, len(wanted), 'kanji')
