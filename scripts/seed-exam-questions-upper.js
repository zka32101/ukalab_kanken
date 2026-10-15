#!/usr/bin/env node
/**
 * examQuestions コレクションへの模擬試験問題データ投入スクリプト（4級・3級・準2級・2級分）
 *
 * 問題データは scripts/generate-exam-questions-upper.js が生成した
 * scripts/data/exam-questions-upper.json（各級20問＝読み10・書き取り10、計80問）。
 * 生成元は seed-kanji-questions.js の検証済みデータ（配当漢字・読み・用例）のみ。
 * 意味・使い方・画数は検証済みデータが無いため含まない。
 * level は int（4級=4, 3級=3, 準2級=25, 2級=2。mock_exam_modes_screen.dart の変換と同じ）。
 *
 * 使い方（scripts/ ディレクトリで実行）:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json node seed-exam-questions-upper.js
 */
const admin = require('firebase-admin');
const questions = require('./data/exam-questions-upper.json');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('エラー: 環境変数 GOOGLE_APPLICATION_CREDENTIALS が設定されていません。');
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.applicationDefault() });
const db = admin.firestore();

async function main() {
  const batch = db.batch();
  const collection = db.collection('examQuestions');
  for (const item of questions) {
    batch.set(collection.doc(item.questionId), item);
  }
  await batch.commit();
  console.log(`✅ ${questions.length}件の問題を examQuestions コレクションに投入しました（4級・3級・準2級・2級分、各20問）。`);
}

main().catch((err) => {
  console.error('❌ 投入に失敗しました:', err);
  process.exit(1);
});
