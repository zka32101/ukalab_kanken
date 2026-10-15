#!/usr/bin/env node
/**
 * examQuestions コレクションへの模擬試験問題データ投入スクリプト（パイロット: 5級の増量分）
 *
 * 問題データは scripts/generate-exam-questions-pilot.js が生成した
 * scripts/data/exam-questions-pilot-l5.json（読み40・書き取り30・画数20、計90問）。
 * 既存の l5-* ドキュメント（seed-exam-questions-l9-l5.js の20問）は変更しない（IDが重なるものは作っていない）。
 * 生成元は配当漢字・読み・用例・画数の検証済みデータのみ。
 *
 * 使い方（scripts/ ディレクトリで実行。本番に書き込むので、投入前に
 * `node verify-exam-questions-pilot.js` が成功することを確認すること）:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json node seed-exam-questions-pilot.js
 */
const admin = require('firebase-admin');
const questions = require('./data/exam-questions-pilot-l5.json');

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
  console.log(`✅ ${questions.length}件の問題を examQuestions コレクションに投入しました（5級の増量分）。`);
}

main().catch((err) => {
  console.error('❌ 投入に失敗しました:', err);
  process.exit(1);
});
