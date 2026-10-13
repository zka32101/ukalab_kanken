#!/usr/bin/env node
/**
 * examQuestions コレクションへの模擬試験問題データ投入スクリプト
 *
 * 用途:
 *   Firestoreの examQuestions コレクションは firestore.rules で
 *   クライアントからの書き込みを禁止しているため（allow write: if false）、
 *   Firebase Admin SDK を使ってサーバー側から投入する。
 *
 * 事前準備:
 *   1. cd scripts && npm install
 *   2. Firebase Console > プロジェクトの設定 > サービスアカウント から
 *      秘密鍵(JSON)を新規生成してダウンロードする
 *   3. ダウンロードしたJSONファイルのパスを環境変数で指定する
 *
 * 使い方（scripts/ ディレクトリで実行）:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json node seed-exam-questions.js
 *
 * 注意:
 *   サービスアカウントキーは強力な権限を持つ機密情報です。
 *   リポジトリには絶対にコミットしないでください（.gitignore対象）。
 */

const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('エラー: 環境変数 GOOGLE_APPLICATION_CREDENTIALS が設定されていません。');
  console.error('Firebase Consoleでサービスアカウントキーを発行し、そのパスを指定してください。');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

// EnhancedExamQuestion.fromJson() (lib/models/mock_exam_modes.dart) が
// 期待するフィールド構造に合わせる。difficulty/category は Dart の
// enum.toString() 形式の文字列("ExamDifficulty.easy"等)で保存する必要がある。
const questions = [
  // --- 読み (reading) ---
  {
    questionId: 'l10-reading-001',
    kanji: '一',
    questionType: 'reading',
    question: '次の漢字の読みがなを選びましょう。「一」',
    options: ['いち', 'に', 'さん', 'し'],
    correctAnswer: 'いち',
    explanation: '「一」は「いち」と読みます。数を表す基本の漢字です。',
    level: 10,
    difficulty: 'ExamDifficulty.easy',
    category: 'ExamCategory.reading',
  },
  {
    questionId: 'l10-reading-002',
    kanji: '山',
    questionType: 'reading',
    question: '次の漢字の読みがなを選びましょう。「山」',
    options: ['やま', 'かわ', 'うみ', 'そら'],
    correctAnswer: 'やま',
    explanation: '「山」は「やま」と読みます。',
    level: 10,
    difficulty: 'ExamDifficulty.easy',
    category: 'ExamCategory.reading',
  },
  {
    questionId: 'l10-reading-003',
    kanji: '木',
    questionType: 'reading',
    question: '次の漢字の読みがなを選びましょう。「木」',
    options: ['き', 'はな', 'くさ', 'つち'],
    correctAnswer: 'き',
    explanation: '「木」は「き」と読みます。',
    level: 10,
    difficulty: 'ExamDifficulty.easy',
    category: 'ExamCategory.reading',
  },
  {
    questionId: 'l10-reading-004',
    kanji: '水',
    questionType: 'reading',
    question: '次の漢字の読みがなを選びましょう。「水」',
    options: ['みず', 'ひ', 'つち', 'かぜ'],
    correctAnswer: 'みず',
    explanation: '「水」は「みず」と読みます。',
    level: 10,
    difficulty: 'ExamDifficulty.easy',
    category: 'ExamCategory.reading',
  },
  // --- 意味 (meaning) ---
  {
    questionId: 'l10-meaning-001',
    kanji: '上',
    questionType: 'meaning',
    question: '「上」の意味として正しいものを選びましょう。',
    options: ['高いところ', '低いところ', '横のところ', '中のところ'],
    correctAnswer: '高いところ',
    explanation: '「上」は位置が高い方向を表します。',
    level: 10,
    difficulty: 'ExamDifficulty.easy',
    category: 'ExamCategory.meaning',
  },
  {
    questionId: 'l10-meaning-002',
    kanji: '大',
    questionType: 'meaning',
    question: '「大」の意味として正しいものを選びましょう。',
    options: ['おおきい', 'ちいさい', 'ながい', 'みじかい'],
    correctAnswer: 'おおきい',
    explanation: '「大」は「おおきい」という意味です。',
    level: 10,
    difficulty: 'ExamDifficulty.easy',
    category: 'ExamCategory.meaning',
  },
  {
    questionId: 'l10-meaning-003',
    kanji: '小',
    questionType: 'meaning',
    question: '「小」の意味として正しいものを選びましょう。',
    options: ['ちいさい', 'おおきい', 'たかい', 'ひくい'],
    correctAnswer: 'ちいさい',
    explanation: '「小」は「ちいさい」という意味です。',
    level: 10,
    difficulty: 'ExamDifficulty.easy',
    category: 'ExamCategory.meaning',
  },
  {
    questionId: 'l10-meaning-004',
    kanji: '人',
    questionType: 'meaning',
    question: '「人」の意味として正しいものを選びましょう。',
    options: ['ひと', 'いぬ', 'ねこ', 'とり'],
    correctAnswer: 'ひと',
    explanation: '「人」は「ひと」を表す漢字です。',
    level: 10,
    difficulty: 'ExamDifficulty.easy',
    category: 'ExamCategory.meaning',
  },
  // --- 画数 (stroke) ---
  {
    questionId: 'l10-stroke-001',
    kanji: '三',
    questionType: 'stroke',
    question: '「三」の画数を選びましょう。',
    options: ['3画', '2画', '4画', '5画'],
    correctAnswer: '3画',
    explanation: '「三」は横線3本で3画です。',
    level: 10,
    difficulty: 'ExamDifficulty.easy',
    category: 'ExamCategory.stroke',
  },
  {
    questionId: 'l10-stroke-002',
    kanji: '子',
    questionType: 'stroke',
    question: '「子」の画数を選びましょう。',
    options: ['3画', '2画', '4画', '5画'],
    correctAnswer: '3画',
    explanation: '「子」は3画で書きます。',
    level: 10,
    difficulty: 'ExamDifficulty.medium',
    category: 'ExamCategory.stroke',
  },
  {
    questionId: 'l10-stroke-003',
    kanji: '女',
    questionType: 'stroke',
    question: '「女」の画数を選びましょう。',
    options: ['3画', '4画', '2画', '5画'],
    correctAnswer: '3画',
    explanation: '「女」は3画で書きます。',
    level: 10,
    difficulty: 'ExamDifficulty.medium',
    category: 'ExamCategory.stroke',
  },
  {
    questionId: 'l10-stroke-004',
    kanji: '田',
    questionType: 'stroke',
    question: '「田」の画数を選びましょう。',
    options: ['5画', '4画', '6画', '3画'],
    correctAnswer: '5画',
    explanation: '「田」は5画で書きます。',
    level: 10,
    difficulty: 'ExamDifficulty.medium',
    category: 'ExamCategory.stroke',
  },
  // --- 書き (writing) ---
  {
    questionId: 'l10-writing-001',
    kanji: '力',
    questionType: 'writing',
    question: '「ちから」を表す漢字を選びましょう。',
    options: ['力', '刀', '九', '刃'],
    correctAnswer: '力',
    explanation: '「ちから」は「力」と書きます。',
    level: 10,
    difficulty: 'ExamDifficulty.easy',
    category: 'ExamCategory.writing',
  },
  {
    questionId: 'l10-writing-002',
    kanji: '口',
    questionType: 'writing',
    question: '「くち」を表す漢字を選びましょう。',
    options: ['口', '目', '耳', '手'],
    correctAnswer: '口',
    explanation: '「くち」は「口」と書きます。',
    level: 10,
    difficulty: 'ExamDifficulty.easy',
    category: 'ExamCategory.writing',
  },
  {
    questionId: 'l10-writing-003',
    kanji: '日',
    questionType: 'writing',
    question: '「ひ」を表す漢字を選びましょう。',
    options: ['日', '月', '木', '田'],
    correctAnswer: '日',
    explanation: '「ひ」は「日」と書きます。',
    level: 10,
    difficulty: 'ExamDifficulty.easy',
    category: 'ExamCategory.writing',
  },
  {
    questionId: 'l10-writing-004',
    kanji: '月',
    questionType: 'writing',
    question: '「つき」を表す漢字を選びましょう。',
    options: ['月', '日', '田', '目'],
    correctAnswer: '月',
    explanation: '「つき」は「月」と書きます。',
    level: 10,
    difficulty: 'ExamDifficulty.easy',
    category: 'ExamCategory.writing',
  },
  // --- 使い方 (usage) ---
  {
    questionId: 'l10-usage-001',
    kanji: '上',
    questionType: 'usage',
    question: '「つくえの＿にほんがのっている」に入る漢字を選びましょう。',
    options: ['上', '下', '中', '外'],
    correctAnswer: '上',
    explanation: '「つくえの上」で「机の上」という意味になります。',
    level: 10,
    difficulty: 'ExamDifficulty.medium',
    category: 'ExamCategory.usage',
  },
  {
    questionId: 'l10-usage-002',
    kanji: '川',
    questionType: 'usage',
    question: '「＿があそこにながれている」に入る漢字を選びましょう。',
    options: ['川', '山', '木', '田'],
    correctAnswer: '川',
    explanation: '「川」は水が流れる場所を表します。',
    level: 10,
    difficulty: 'ExamDifficulty.medium',
    category: 'ExamCategory.usage',
  },
  {
    questionId: 'l10-usage-003',
    kanji: '木',
    questionType: 'usage',
    question: '「にわに＿がはえている」に入る漢字を選びましょう。',
    options: ['木', '水', '火', '土'],
    correctAnswer: '木',
    explanation: '「庭に木がある」という文になります。',
    level: 10,
    difficulty: 'ExamDifficulty.medium',
    category: 'ExamCategory.usage',
  },
  {
    questionId: 'l10-usage-004',
    kanji: '火',
    questionType: 'usage',
    question: '「ろうそくの＿がもえている」に入る漢字を選びましょう。',
    options: ['火', '水', '木', '土'],
    correctAnswer: '火',
    explanation: '「火が燃えている」という文になります。',
    level: 10,
    // 弱点対策モード(weakAreasExam)はdifficulty=hardの問題のみを検索するため、
    // 動作確認用に最低1問hardを用意しておく。
    difficulty: 'ExamDifficulty.hard',
    category: 'ExamCategory.usage',
  },
].map((q) => ({
  ...q,
  averageTimeSeconds: 15.0,
  correctnessRate: 0.0,
  userAttempts: 0,
  commonMistakes: [],
  additionalTip: null,
}));

async function main() {
  const batch = db.batch();
  const collection = db.collection('examQuestions');

  for (const q of questions) {
    const ref = collection.doc(q.questionId);
    batch.set(ref, q);
  }

  await batch.commit();
  console.log(`✅ ${questions.length}件の問題を examQuestions コレクションに投入しました（10級分）。`);
}

main().catch((err) => {
  console.error('❌ 投入に失敗しました:', err);
  process.exit(1);
});
