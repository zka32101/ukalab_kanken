#!/usr/bin/env node
/**
 * 4級・3級・準2級・2級の模擬試験問題（examQuestions 用）を生成するスクリプト。
 *
 * 方針: 事実を新たに作らない。scripts/seed-kanji-questions.js に検証済みで入っている
 * 「配当漢字・読み・用例」だけから組み立てる。意味データが無いので「意味」「使い方」は作らず、
 * 各級 読み10問 + 書き取り10問 = 20問 とする。
 *
 *  - 読み: 用例語の中の対象漢字の読み（reading の送り仮名括弧を除いたもの）。
 *          用例の読みの中に含まれていることを確認できた字だけを使う。
 *          誤答は同じ級の別字の読みで、正解の字が持つどの読みとも一致しないものだけ。
 *  - 書き取り: 用例語（対象漢字を1つ含む、ひらがなを含まない2字以上の熟語）の対象漢字を「＿」にして出題。
 *          誤答は同じ級の別字で、正解の字が持つどの読みとも読みを共有せず、
 *          かつ「その字で置き換えた語」が配当データの用例に存在しないもの。
 *
 * 決定的: 乱数は固定シードの mulberry32。再実行しても同じ JSON になる。
 * 出力: scripts/data/exam-questions-upper.json（seed-exam-questions-upper.js が読む）
 * 使い方: node scripts/generate-exam-questions-upper.js
 */
const fs = require('fs');
const path = require('path');

const SRC = path.join(__dirname, 'seed-kanji-questions.js');
const OUT = path.join(__dirname, 'data', 'exam-questions-upper.json');

// examQuestions の level は int（10級=10, 準2級=25, 準1級=15。mock_exam_modes_screen.dart の変換に合わせる）
const LEVELS = [
  { key: 'LEVEL_4', level: 4, label: '4級' },
  { key: 'LEVEL_3', level: 3, label: '3級' },
  { key: 'LEVEL_2_PRE', level: 25, label: '準2級' },
  { key: 'LEVEL_2', level: 2, label: '2級' },
];
const READING_COUNT = 10;
const WRITING_COUNT = 10;

function mulberry32(a) {
  return function () {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
function shuffled(arr, rnd) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rnd() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function loadQuestions() {
  const s = fs.readFileSync(SRC, 'utf8');
  const a = s.indexOf('const questions = [');
  const b = s.indexOf('];\nasync function main');
  if (a < 0 || b < 0) throw new Error('seed-kanji-questions.js の構造が想定と違います');
  // eslint-disable-next-line no-eval
  return eval(s.slice(a + 'const questions = '.length, b + 1));
}

const strip = (r) => r.replace(/（[^）]*）/g, '');
const kata2hira = (s) => s.replace(/[ァ-ヶ]/g, (c) => String.fromCharCode(c.charCodeAt(0) - 0x60));
const norm = (r) => kata2hira(strip(r));
const isKana = (s) => /^[ぁ-ゖー]+$/.test(s);
const splitExample = (ex) => {
  const m = /^(.+?)（([^（）]+)）$/.exec(ex || '');
  return m ? { word: m[1], yomi: m[2] } : null;
};

const all = loadQuestions();
const allExampleWords = new Set();
for (const q of all) {
  for (const e of [q.example, ...(q.extraReadings || []).map((x) => x.example)]) {
    const p = splitExample(e);
    if (p) allExampleWords.add(p.word);
  }
}

function readingSet(q) {
  const set = new Set([norm(q.reading)]);
  for (const e of q.extraReadings || []) set.add(norm(e.reading));
  return set;
}

function build(lv) {
  const rnd = mulberry32(0x4b414e + lv.level * 7919);
  const pool = all.filter((q) => q.level === lv.key);
  const info = pool.map((q) => {
    const p = splitExample(q.example);
    const rd = norm(q.reading);
    const ok = p && isKana(rd) && p.word.includes(q.kanji) && kata2hira(p.yomi).includes(rd);
    return { q, p, rd, ok, set: readingSet(q) };
  });

  const readingElig = info.filter((x) => x.ok);
  const writingElig = info.filter(
    (x) => x.ok && [...x.p.word].length >= 2 && x.p.word.split(x.q.kanji).length === 2 && !/[ぁ-ゖ]/.test(x.p.word),
  );

  const pickReading = shuffled(readingElig, rnd).slice(0, READING_COUNT);
  const used = new Set(pickReading.map((x) => x.q.kanji));
  const pickWriting = shuffled(writingElig.filter((x) => !used.has(x.q.kanji)), rnd).slice(0, WRITING_COUNT);
  if (pickReading.length < READING_COUNT || pickWriting.length < WRITING_COUNT) {
    throw new Error(`${lv.label}: 問題を作れる字が足りません`);
  }

  const out = [];
  let k = 0;
  const place = (correct, wrong) => {
    const pos = k % 4; // 正解位置を 0..3 で均等に
    const opts = shuffled(wrong, rnd);
    opts.splice(pos, 0, correct);
    k++;
    return opts;
  };
  const byLen = (target, cands) =>
    shuffled(cands, rnd).sort((a, b) => Math.abs([...a].length - [...target].length) - Math.abs([...b].length - [...target].length));

  pickReading.forEach((x, i) => {
    const cand = [...new Set(info.filter((y) => y !== x && isKana(y.rd)).map((y) => y.rd))].filter(
      (r) => !x.set.has(r),
    );
    const wrong = byLen(x.rd, cand).slice(0, 3);
    const wordPart = x.p.word === x.q.kanji ? '' : `（「${x.p.word}」の「${x.q.kanji}」）`;
    out.push({
      id: `l${lv.level}-reading-${String(i + 1).padStart(3, '0')}`,
      kanji: x.q.kanji, type: 'reading',
      question: `次の漢字の読みがなを選びましょう。「${x.q.kanji}」${wordPart}`,
      options: place(x.rd, wrong), correctAnswer: x.rd,
      explanation: `「${x.q.kanji}」は「${x.rd}」と読みます（${x.p.word}＝${x.p.yomi}）。`,
      level: lv.level, difficulty: 'medium',
    });
  });

  pickWriting.forEach((x, i) => {
    const blank = x.p.word.replace(x.q.kanji, '＿');
    const cand = info
      .filter((y) => y !== x && ![...y.set].some((r) => x.set.has(r)))
      .map((y) => y.q.kanji)
      .filter((c) => !allExampleWords.has(x.p.word.replace(x.q.kanji, c)));
    const wrong = shuffled(cand, rnd).slice(0, 3);
    out.push({
      id: `l${lv.level}-writing-${String(i + 1).padStart(3, '0')}`,
      kanji: x.q.kanji, type: 'writing',
      question: `「${x.rd}」を表す漢字を選びましょう。（「${blank}」の＿）`,
      options: place(x.q.kanji, wrong), correctAnswer: x.q.kanji,
      explanation: `「${x.rd}」（${x.p.word}＝${x.p.yomi}）は「${x.q.kanji}」と書きます。`,
      level: lv.level, difficulty: i % 2 === 0 ? 'medium' : 'hard',
    });
  });
  return out;
}

const result = [];
for (const lv of LEVELS) result.push(...build(lv));
for (const r of result) {
  if (r.options.length !== 4 || new Set(r.options).size !== 4 || !r.options.includes(r.correctAnswer)) {
    throw new Error(`不正な選択肢: ${r.id}`);
  }
}
const final = result.map((r) => ({
  questionId: r.id, kanji: r.kanji, questionType: r.type, question: r.question,
  options: r.options, correctAnswer: r.correctAnswer, explanation: r.explanation,
  level: r.level, difficulty: `ExamDifficulty.${r.difficulty}`, category: `ExamCategory.${r.type}`,
  averageTimeSeconds: 15.0, correctnessRate: 0.0, userAttempts: 0, commonMistakes: [], additionalTip: null,
}));
fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(final, null, 2) + '\n');
console.log(`${final.length}問を ${path.relative(process.cwd(), OUT)} に出力しました。`);
