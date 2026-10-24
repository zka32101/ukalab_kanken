#!/usr/bin/env python3
"""アプリに同梱する問題データ(assets/questions/kanken_questions.json)を、scripts/seed-kanji-questions.js から作る。

  python3 -I scripts/generate_bundled_questions.py

オフライン（Firestore から問題が取れないとき）の演習で使う。本番の questions コレクションと
同じ元データ（シードスクリプト）から作るので、食い違わない（test/bundled_questions_test.dart で確認）。
準1級・1級は、アプリでまだ問題として使っていないので含めない。
出力は決まった順序・決まった書き方（再実行しても同じファイルになる）。
"""
import json
import sys

EXCLUDE = {'LEVEL_1', 'LEVEL_1_PRE'}

src = open('scripts/seed-kanji-questions.js', encoding='utf-8').read()
a = src.index('const questions = ') + len('const questions = ')
b = src.index('];\nasync function main') + 1
questions = [q for q in json.loads(src[a:b]) if q['level'] not in EXCLUDE]

for q in questions:
    # 取り込み側(KanjiQuestion.fromJson)が使う欄だけを残す。
    for key in list(q):
        if key not in ('id', 'level', 'kanji', 'questionType', 'choices', 'correctAnswer',
                       'version', 'reading', 'example', 'extraReadings'):
            del q[key]

out = 'assets/questions/kanken_questions.json'
text = json.dumps(questions, ensure_ascii=False, separators=(',', ':')) + '\n'
open(out, 'w', encoding='utf-8', newline='\n').write(text)
print('wrote', out, len(questions), '問', len(text.encode('utf-8')) // 1024, 'KB')
sys.exit(0)
