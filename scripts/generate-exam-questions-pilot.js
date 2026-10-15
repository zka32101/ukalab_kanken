#!/usr/bin/env node
/**
 * 模擬試験（examQuestions）の問題を増やす「パイロット」生成スクリプト（既定: 5級）。
 *
 * 方針: 事実を新たに作らない。次の検証済みデータだけから機械的に組み立てる。
 *   - lib/data/level_kanji_data.dart        … 級別の配当漢字（公式の学年別漢字配当表と照合済み）
 *   - lib/data/kanji_info_data.dart         … 読み（音=カタカナ／訓=ひらがな）と用例
 *   - lib/data/kanji_stroke_count_data.dart … 画数（KANJIDIC2）
 * 意味・使い方は検証済みデータが無いので作らない。
 *
 *  - 読み(reading): 用例語の中の対象漢字の読み。誤答は同じ級の別字の読み（同じ表記種別）で、
 *    対象漢字が持つどの読みとも一致しないもの。
 *  - 書き取り(writing): 用例語の対象漢字を「＿」にして出題（読みを問題文に示す）。誤答は同じ級の別字で、
 *    対象漢字と読みを共有せず、置き換えた語が用例に無いもの。
 *  - 画数(stroke): 画数データがある字。誤答は正解±1〜2画。
 * 既存の問題（seed-exam-questions-l9-l5.js）と同じ字・同じカテゴリは作らない。
 *
 * 決定的（固定シードの乱数）。再実行しても同じ JSON になる。
 * 使い方: node scripts/generate-exam-questions-pilot.js [LEVEL_5] [読み数] [書き取り数] [画数]
 * 出力: scripts/data/exam-questions-pilot-l<N>.json （seed-exam-questions-pilot.js が読む）
 */
const fs = require('fs');
const path = require('path');

const LEVEL_KEY = process.argv[2] || 'LEVEL_5';
const N_READING = Number(process.argv[3] || 40);
const N_WRITING = Number(process.argv[4] || 30);
const N_STROKE = Number(process.argv[5] || 20);
const LEVEL_NUM = Number(LEVEL_KEY.replace('LEVEL_', ''));
const ROOT = path.join(__dirname, '..');
const OUT = path.join(__dirname, 'data', `exam-questions-pilot-l${LEVEL_NUM}.json`);

const read = (p) => fs.readFileSync(path.join(ROOT, p), 'utf8');

function mulberry32(a) {
  return function () {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const rnd = mulberry32(0x50494c + LEVEL_NUM * 104729);
function shuffled(arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rnd() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// ---- データ読み込み ----
const levelSrc = read('lib/data/level_kanji_data.dart');
const levelChars = [...new RegExp(`'${LEVEL_KEY}':\\s*'([^']+)'`).exec(levelSrc)[1]];

const info = {};
for (const m of read('lib/data/kanji_info_data.dart').matchAll(
  /'(.)': KanjiInfo\(readings: \[([^\]]*)\], examples: \[([^\]]*)\]\)/gu)) {
  const list = (s) => [...s.matchAll(/'([^']*)'/g)].map((x) => x[1]);
  info[m[1]] = { readings: list(m[2]), examples: list(m[3]) };
}
const stroke = {};
for (const m of read('lib/data/kanji_stroke_count_data.dart').matchAll(/^\s*'(.)': (\d+),/gmu)) {
  stroke[m[1]] = Number(m[2]);
}

const existingSrc = read('scripts/seed-exam-questions-l9-l5.js');
const existing = { reading: new Set(), writing: new Set(), stroke: new Set() };
for (const m of existingSrc.matchAll(new RegExp(`id: 'l${LEVEL_NUM}-(\\w+)-\\d+', kanji: '(.)'`, 'gu'))) {
  if (existing[m[1]]) existing[m[1]].add(m[2]);
}

// ---- 読みの正規化 ----
const strip = (r) => r.replace(/（[^）]*）/g, '');
const kata2hira = (s) => s.replace(/[ァ-ヶ]/g, (c) => String.fromCharCode(c.charCodeAt(0) - 0x60));
const norm = (r) => kata2hira(strip(r));
const isKata = (s) => /^[ァ-ヶー]+$/.test(s);
const splitEx = (ex) => {
  const m = /^(.+?)（([^（）]+)）$/.exec(ex || '');
  return m ? { word: m[1], yomi: m[2] } : null;
};
const allWords = new Set();
for (const k of Object.values(info)) {
  for (const e of k.examples) { const p = splitEx(e); if (p) allWords.add(p.word); }
}

const chars = levelChars.filter((c) => info[c]);
const readingSet = (c) => new Set(info[c].readings.map(norm));

// 各字について「読み r が用例語 word の中で実際に使われている」組を求める
function usable(c) {
  const out = [];
  const exs = info[c].examples.map(splitEx).filter(Boolean).filter((p) => p.word.includes(c));
  for (const r of info[c].readings) {
    const rd = strip(r);
    if (!rd) continue;
    // 音読みは用例語が熟語（2字以上）のもののみ
    const p = exs.find((e) => kata2hira(e.yomi).includes(norm(r)) && (isKata(rd) ? [...e.word].length >= 2 : true));
    if (p) out.push({ rd, p });
  }
  return out;
}

const out = [];
const counters = { reading: 0, writing: 0, stroke: 0 };
const place = (type, correct, wrong) => {
  const pos = counters[type] % 4; // 正解位置を均等に
  counters[type]++;
  const opts = shuffled(wrong);
  opts.splice(pos, 0, correct);
  return opts;
};
const byLen = (target, cands) =>
  shuffled(cands).sort((a, b) => Math.abs([...a].length - [...target].length) - Math.abs([...b].length - [...target].length));
const idOf = (type, i) => `l${LEVEL_NUM}-${type}-${String(i).padStart(3, '0')}`;
const startIdx = (type) => {
  const m = [...existingSrc.matchAll(new RegExp(`id: 'l${LEVEL_NUM}-${type}-(\\d+)'`, 'g'))].map((x) => Number(x[1]));
  return (m.length ? Math.max(...m) : 0) + 1;
};

// ---- 読み ----
{
  const elig = shuffled(chars.filter((c) => !existing.reading.has(c)).map((c) => ({ c, u: usable(c) })).filter((x) => x.u.length));
  let i = startIdx('reading');
  for (const { c, u } of elig.slice(0, N_READING)) {
    const { rd, p } = u[0];
    const mine = readingSet(c);
    const pool = [...new Set(chars.filter((d) => d !== c).flatMap((d) => info[d].readings.map(strip)))]
      .filter((r) => r && isKata(r) === isKata(rd) && !mine.has(kata2hira(r)));
    const wrong = byLen(rd, pool).slice(0, 3);
    out.push({
      id: idOf('reading', i++), kanji: c, type: 'reading',
      question: `次の漢字の読みがなを選びましょう。「${c}」（「${p.word}」の「${c}」）`,
      options: place('reading', rd, wrong), correctAnswer: rd,
      explanation: `「${c}」は「${rd}」と読みます（${p.word}＝${p.yomi}）。`,
      level: LEVEL_NUM, difficulty: 'medium',
    });
  }
}

// ---- 書き取り ----
{
  const elig = shuffled(
    chars.filter((c) => !existing.writing.has(c)).map((c) => ({ c, u: usable(c) }))
      .map((x) => ({
        ...x,
        u: x.u.filter(({ p }) => [...p.word].length >= 2 && p.word.split(x.c).length === 2 && !/[ぁ-ゖ]/.test(p.word)),
      }))
      .filter((x) => x.u.length));
  const usedReading = new Set(out.map((q) => q.kanji));
  const ordered = [...elig.filter((x) => !usedReading.has(x.c)), ...elig.filter((x) => usedReading.has(x.c))];
  let i = startIdx('writing');
  for (const { c, u } of ordered.slice(0, N_WRITING)) {
    const { rd, p } = u[0];
    const mine = readingSet(c);
    const cand = chars
      .filter((d) => d !== c && ![...readingSet(d)].some((r) => mine.has(r)))
      .filter((d) => !allWords.has(p.word.replace(c, d)));
    const wrong = shuffled(cand).slice(0, 3);
    const rdH = norm(rd);
    out.push({
      id: idOf('writing', i++), kanji: c, type: 'writing',
      question: `「${rdH}」を表す漢字を選びましょう。（「${p.word.replace(c, '＿')}」の＿）`,
      options: place('writing', c, wrong), correctAnswer: c,
      explanation: `「${rdH}」（${p.word}＝${p.yomi}）は「${c}」と書きます。`,
      level: LEVEL_NUM, difficulty: i % 2 ? 'medium' : 'hard',
    });
  }
}

// ---- 画数 ----
{
  const elig = shuffled(chars.filter((c) => stroke[c] && !existing.stroke.has(c)));
  let i = startIdx('stroke');
  for (const c of elig.slice(0, N_STROKE)) {
    const n = stroke[c];
    const wrong = shuffled([n - 2, n - 1, n + 1, n + 2].filter((x) => x >= 1)).slice(0, 3).map((x) => `${x}画`);
    out.push({
      id: idOf('stroke', i++), kanji: c, type: 'stroke',
      question: `「${c}」の画数を選びましょう。`,
      options: place('stroke', `${n}画`, wrong), correctAnswer: `${n}画`,
      explanation: `「${c}」は${n}画で書きます。`,
      level: LEVEL_NUM, difficulty: n <= 8 ? 'easy' : n <= 13 ? 'medium' : 'hard',
    });
  }
}

const final = out.map((r) => ({
  questionId: r.id, kanji: r.kanji, questionType: r.type, question: r.question,
  options: r.options, correctAnswer: r.correctAnswer, explanation: r.explanation,
  level: r.level, difficulty: `ExamDifficulty.${r.difficulty}`, category: `ExamCategory.${r.type}`,
  averageTimeSeconds: 15.0, correctnessRate: 0.0, userAttempts: 0, commonMistakes: [], additionalTip: null,
}));
fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(final, null, 2) + '\n');
console.log(`${final.length}問（reading ${counters.reading} / writing ${counters.writing} / stroke ${counters.stroke}）を ${path.relative(process.cwd(), OUT)} に出力しました。`);
