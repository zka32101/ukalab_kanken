#!/usr/bin/env node
/**
 * パイロット追加分（scripts/data/exam-questions-pilot-l<N>.json）の機械検証。
 * 生成スクリプトとは別に、元データ（配当漢字・読み・画数・既存問題）から独立に確認する。
 * 使い方: node scripts/verify-exam-questions-pilot.js [5]
 * 失敗が1件でもあれば終了コード1。
 */
const fs = require('fs');
const path = require('path');

const N = Number(process.argv[2] || 5);
const ROOT = path.join(__dirname, '..');
const read = (p) => fs.readFileSync(path.join(ROOT, p), 'utf8');
const data = JSON.parse(read(`scripts/data/exam-questions-pilot-l${N}.json`));

const levelChars = new Set([...new RegExp(`'LEVEL_${N}':\\s*'([^']+)'`).exec(read('lib/data/level_kanji_data.dart'))[1]]);
const info = {};
for (const m of read('lib/data/kanji_info_data.dart').matchAll(/'(.)': KanjiInfo\(readings: \[([^\]]*)\], examples: \[([^\]]*)\]\)/gu)) {
  const list = (s) => [...s.matchAll(/'([^']*)'/g)].map((x) => x[1]);
  info[m[1]] = { readings: list(m[2]), examples: list(m[3]) };
}
const stroke = {};
for (const m of read('lib/data/kanji_stroke_count_data.dart').matchAll(/^\s*'(.)': (\d+),/gmu)) stroke[m[1]] = Number(m[2]);

const strip = (r) => r.replace(/（[^）]*）/g, '');
const norm = (r) => strip(r).replace(/[ァ-ヶ]/g, (c) => String.fromCharCode(c.charCodeAt(0) - 0x60));
const rset = (c) => new Set(info[c].readings.map(norm));

const existingSrc = read('scripts/seed-exam-questions-l9-l5.js');
const existingIds = new Set([...existingSrc.matchAll(/id: '(l\d+-\w+-\d+)'/g)].map((m) => m[1]));
const existingQ = new Set([...existingSrc.matchAll(new RegExp(`id: 'l${N}-(\\w+)-\\d+', kanji: '(.)'`, 'gu'))].map((m) => `${m[1]}:${m[2]}`));

const errors = [];
const err = (q, msg) => errors.push(`${q.questionId}: ${msg}`);
const keys = ['questionId', 'kanji', 'questionType', 'question', 'options', 'correctAnswer', 'explanation', 'level', 'difficulty', 'category', 'averageTimeSeconds', 'correctnessRate', 'userAttempts', 'commonMistakes', 'additionalTip'];
const ids = new Set();
const seen = new Set();
const stat = {};
const pos = {};

for (const q of data) {
  const type = q.questionType;
  stat[type] = (stat[type] || 0) + 1;
  // スキーマ
  for (const k of keys) if (!(k in q)) err(q, `フィールド ${k} がない`);
  if (Object.keys(q).length !== keys.length) err(q, 'フィールド数が違う');
  if (q.level !== N) err(q, 'level が違う');
  if (q.category !== `ExamCategory.${type}`) err(q, 'category が questionType と不一致');
  if (!/^ExamDifficulty\.(easy|medium|hard)$/.test(q.difficulty)) err(q, 'difficulty が不正');
  if (!q.questionId.startsWith(`l${N}-${type}-`)) err(q, 'ID の形式が違う');
  // ID・内容の重複
  if (ids.has(q.questionId) || existingIds.has(q.questionId)) err(q, 'ID 重複');
  ids.add(q.questionId);
  const dupKey = `${type}:${q.kanji}`;
  if (seen.has(dupKey) || existingQ.has(dupKey)) err(q, `同じ字・同じカテゴリの問題が重複 (${dupKey})`);
  seen.add(dupKey);
  // 選択肢
  if (q.options.length !== 4 || new Set(q.options).size !== 4) err(q, '選択肢が4つ・重複なしでない');
  if (!q.options.includes(q.correctAnswer)) err(q, '正解が選択肢にない');
  const idx = q.options.indexOf(q.correctAnswer);
  pos[type] = pos[type] || [0, 0, 0, 0];
  pos[type][idx]++;
  // 配当範囲
  if (!levelChars.has(q.kanji)) err(q, `対象漢字が ${N}級の配当外`);
  if (type === 'reading') {
    const mine = rset(q.kanji);
    if (!info[q.kanji].readings.map(strip).includes(q.correctAnswer)) err(q, '正解が読みデータにない');
    for (const o of q.options) {
      if (o === q.correctAnswer) continue;
      if (mine.has(norm(o))) err(q, `誤答「${o}」が正解の字の読みと一致（別解）`);
    }
    // 音訓種別が揃っている
    const kata = (s) => /^[ァ-ヶー]+$/.test(s);
    if (new Set(q.options.map(kata)).size !== 1) err(q, '選択肢の音訓表記が混在');
    const m = /「([^」]+)」の「(.)」/u.exec(q.question);
    if (!m || !info[q.kanji].examples.some((e) => e.startsWith(m[1] + '（'))) err(q, '問題文の用例語が用例データにない');
    if (/[^\s]/.test(q.explanation) && !q.explanation.includes(q.correctAnswer)) err(q, '解説に正解がない');
  } else if (type === 'writing') {
    const mine = rset(q.kanji);
    const m = /（「([^」]*＿[^」]*)」の＿）/u.exec(q.question);
    if (!m) err(q, '書き取りの問題文形式が違う');
    else {
      const word = m[1].replace('＿', q.kanji);
      if (!info[q.kanji].examples.some((e) => e.startsWith(word + '（'))) err(q, `答えを入れた語「${word}」が用例にない`);
      if (q.question.includes(q.correctAnswer)) err(q, '問題文に答えが含まれる');
      for (const o of q.options) {
        if (o === q.correctAnswer) continue;
        if (!levelChars.has(o)) err(q, `誤答「${o}」が配当外`);
        else if ([...rset(o)].some((r) => mine.has(r))) err(q, `誤答「${o}」が正解と読みを共有（別解）`);
        const w2 = m[1].replace('＿', o);
        if (Object.values(info).some((v) => v.examples.some((e) => e.startsWith(w2 + '（')))) err(q, `誤答の語「${w2}」が用例に存在`);
      }
    }
    const given = norm(/「([^」]+)」を表す漢字/u.exec(q.question)[1]);
    if (!mine.has(given)) err(q, '問題文の読みが正解の字の読みでない');
  } else if (type === 'stroke') {
    if (stroke[q.kanji] === undefined) err(q, '画数データがない');
    if (q.correctAnswer !== `${stroke[q.kanji]}画`) err(q, `正解の画数がデータ(${stroke[q.kanji]})と不一致`);
    for (const o of q.options) if (!/^[1-9]\d*画$/.test(o)) err(q, `画数の形式が不正: ${o}`);
  } else err(q, `未対応のカテゴリ ${type}`);
}

console.log(`検証対象: ${data.length}問 / カテゴリ別: ${JSON.stringify(stat)}`);
console.log(`正解位置の分布（A,B,C,D）: ${JSON.stringify(pos)}`);
if (errors.length) {
  console.error(`NG: ${errors.length}件\n` + errors.join('\n'));
  process.exit(1);
}
console.log('OK: 全問で 配当範囲・別解なし・重複なし・スキーマ一致・選択肢4つ(重複なし/正解含む) を確認');
