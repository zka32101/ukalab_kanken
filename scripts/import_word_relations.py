#!/usr/bin/env python3
"""対義語・類義語の候補（候補度A）のうち、確認して除いた組以外を scripts/data/word_relations.tsv に取り込む。

  python3 -I scripts/import_word_relations.py
  python3 -I scripts/generate_word_relations.py

候補は extract_word_relation_candidates.py で作る（scripts/data/word_relation_candidates.tsv）。
候補度Aの全件を目で確認し、意味が違う・まれな語・片方が別の関係・子ども向けに向かない組は
下の EXCLUDED に理由つきで残して除いた（取り込む前に確認した記録）。分野は「その他」（誤答の選択肢は
別の分野の語から選ぶので、手で付けた分野の語から選ばれる）。すでにある組は入れない。
"""
SYN_EXCLUDED = {
    '遺産/遺財': 'まれな語', '煙雨/細雨': 'まれな語', '害心/害意': 'まれな語', '教条/教理': '意味が違う',
    '教条/教義': '意味が違う', '傾国/傾城': 'まれな語', '児孫/子孫': 'まれな語', '旅人/過客': 'まれな語',
    '中夜/半夜': 'まれな語', '短剣/短針': '類義語ではない', '毒害/毒殺': '意味が違う', '落雷/電光': '意味が違う',
    '雷電/電光': '意味が近すぎず不確か', '砲火/銃火': 'まれな語', '襲撃/進撃': '意味が違う', '創生/創造': 'まれな語',
    '構成/構造': '意味が違う', '貯金/預金': '意味が違う', '失望/絶望': '程度が違う', '全滅/絶滅': '意味が違う',
    '修正/更正': '意味が違う', '死刑/死罪': 'まれな語', '深刻/重大': '意味が違う', '使用/活用': '意味が違う',
    '会談/会議': '意味が違う', '結末/結果': '意味が違う', '参照/参考': '意味が違う', '真実/真理': '意味が違う',
    '償還/返還': '意味が違う', '変更/改定': '意味が違う', '補償/賠償': '意味が違う', '公示/告示': '意味が違う',
    '統一/統合': '意味が違う', '特別/特殊': '意味が違う', '容易/簡易': '意味が違う', '効力/効果': '意味が違う',
    '根絶/絶滅': '意味が違う', '意味/意義': '意味が違う', '先任/前任': '意味が違う', '表層/表面': '意味が違う',
    '終了/終止': '意味が近すぎず不確か',
}
ANT_EXCLUDED = {
    '一瞬/長久': '組を絞る（一瞬の対義語は永遠に）', '一瞬/恒久': '組を絞る', '瞬間/長久': '組を絞る', '永遠/瞬間': '組を絞る',
    '一般/特別': '組を絞る', '大水/小水': 'まれな語', '嫌悪/支持': '対義語ではない', '原点/終点': '対義語ではない',
    '硬玉/軟玉': 'まれな語', '子孫/父祖': 'まれな語', '小心/放心': '対義語ではない', '初潮/閉経': '子ども向けに向かない',
    '実母/実父': '対義語ではない', '常住/無常': '対義語ではない', '成熟/成長': '対義語ではない', '成長/没落': '対義語ではない',
    '成長/衰弱': '対義語ではない', '成立/消滅': '対義語ではない', '創生/撲滅': '対義語ではない', '中止/完了': '対義語ではない',
    '中傷/美化': '対義語ではない', '底面/頂点': '対義語ではない', '到来/終結': '対義語ではない', '反対/容認': '対義語ではない',
    '分割/統一': '対義語ではない', '分離/編入': '対義語ではない', '養母/養父': '対義語ではない', '卵白/卵黄': '対義語ではない',
}

DEST = 'scripts/data/word_relations.tsv'
SRC = 'scripts/data/word_relation_candidates.tsv'

text = open(DEST, encoding='utf-8', newline='').read()
nl = '\r\n' if '\r\n' in text else '\n'
have = set()
for line in text.splitlines():
    f = line.split('\t')
    if len(f) > 3:
        have.add((f[0], frozenset((f[1], f[3]))))

added = skipped = 0
out = []
for line in open(SRC, encoding='utf-8'):
    f = line.rstrip('\n').split('\t')
    kind, w1, r1, w2, r2, group, why, tier = f
    if tier != 'A':
        continue
    excluded = (SYN_EXCLUDED if kind == '類' else ANT_EXCLUDED)
    if '%s/%s' % (w1, w2) in excluded or '%s/%s' % (w2, w1) in excluded:
        skipped += 1
        continue
    if (kind, frozenset((w1, w2))) in have:
        continue
    have.add((kind, frozenset((w1, w2))))
    out.append('\t'.join([kind, w1, r1, w2, r2, group]))
    added += 1

if not text.endswith(nl):
    text += nl
text += nl.join(out) + nl
open(DEST, 'w', encoding='utf-8', newline='').write(text)
print('added', added, 'excluded', skipped)
