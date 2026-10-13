#!/usr/bin/env node
/**
 * examQuestions コレクションへの模擬試験問題データ投入スクリプト（9級〜5級分）
 *
 * scripts/seed-exam-questions.js が10級分（20問）のみだったため、
 * 9級・8級・7級・6級・5級それぞれについて20問（読み/意味/書き/使い方 各5問）を追加する。
 * 画数（stroke）カテゴリは、正確な検証済みデータが手元にないため今回は追加しない
 * （誤った画数を教育アプリに載せるリスクを避けるため。10級分の既存4問のみ残る）。
 *
 * 各級の漢字・読み方は scripts/seed-kanji-questions.js
 * （日本漢字能力検定協会「級別漢字表」準拠、questions コレクション用に
 * 既に投入済みのデータ）から、素直な読み（送り仮名の括弧表記を含まない
 * 基本形）を持つものを選び、既存の10級分と同じ形式で出題を組み立てた。
 * 「意味」の選択肢は、その学年で一般的に学習する平易な言い換えを充てている。
 *
 * 事前準備・使い方は seed-exam-questions.js と同じ。
 * GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json node seed-exam-questions-l9-l5.js
 */

const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('エラー: 環境変数 GOOGLE_APPLICATION_CREDENTIALS が設定されていません。');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

function q({ id, kanji, type, question, options, correctAnswer, explanation, level, difficulty }) {
  return {
    questionId: id,
    kanji,
    questionType: type,
    question,
    options,
    correctAnswer,
    explanation,
    level,
    difficulty: `ExamDifficulty.${difficulty}`,
    category: `ExamCategory.${type}`,
    averageTimeSeconds: 15.0,
    correctnessRate: 0.0,
    userAttempts: 0,
    commonMistakes: [],
    additionalTip: null,
  };
}

const questions = [
  // ============ 9級（小学2年生相当） ============
  q({ id: 'l9-reading-001', kanji: '毎', type: 'reading', question: '次の漢字の読みがなを選びましょう。「毎」', options: ['マイ', 'カイ', 'ザイ', 'ライ'], correctAnswer: 'マイ', explanation: '「毎」は「マイ」と読みます（毎日＝まいにち）。', level: 9, difficulty: 'easy' }),
  q({ id: 'l9-reading-002', kanji: '肉', type: 'reading', question: '次の漢字の読みがなを選びましょう。「肉」', options: ['ニク', 'ギュウ', 'ブタ', 'サカナ'], correctAnswer: 'ニク', explanation: '「肉」は「ニク」と読みます（牛肉＝ぎゅうにく）。', level: 9, difficulty: 'easy' }),
  q({ id: 'l9-reading-003', kanji: '妹', type: 'reading', question: '次の漢字の読みがなを選びましょう。「妹」', options: ['いもうと', 'あね', 'あに', 'おとうと'], correctAnswer: 'いもうと', explanation: '「妹」は「いもうと」と読みます。', level: 9, difficulty: 'easy' }),
  q({ id: 'l9-reading-004', kanji: '馬', type: 'reading', question: '次の漢字の読みがなを選びましょう。「馬」', options: ['うま', 'とり', 'いぬ', 'ねこ'], correctAnswer: 'うま', explanation: '「馬」は「うま」と読みます。', level: 9, difficulty: 'easy' }),
  q({ id: 'l9-reading-005', kanji: '角', type: 'reading', question: '次の漢字の読みがなを選びましょう。「角」', options: ['かど', 'みち', 'まち', 'いえ'], correctAnswer: 'かど', explanation: '「角」は「かど」と読みます（街角＝まちかど）。', level: 9, difficulty: 'medium' }),
  q({ id: 'l9-meaning-001', kanji: '前', type: 'meaning', question: '「前」の意味として正しいものを選びましょう。', options: ['まえの方', 'うしろの方', '横の方', '上の方'], correctAnswer: 'まえの方', explanation: '「前」は位置や順序が先であることを表します。', level: 9, difficulty: 'easy' }),
  q({ id: 'l9-meaning-002', kanji: '近', type: 'meaning', question: '「近い」の意味として正しいものを選びましょう。', options: ['きょりが短い', 'きょりが長い', '時間が長い', '大きい'], correctAnswer: 'きょりが短い', explanation: '「近い」は距離や時間の隔たりが小さいことです。', level: 9, difficulty: 'easy' }),
  q({ id: 'l9-meaning-003', kanji: '通', type: 'meaning', question: '「通る」の意味として正しいものを選びましょう。', options: ['ある場所をすぎて行く', 'とまる', 'たべる', 'ねむる'], correctAnswer: 'ある場所をすぎて行く', explanation: '「通る」は道などを通過して進むことです。', level: 9, difficulty: 'medium' }),
  q({ id: 'l9-meaning-004', kanji: '光', type: 'meaning', question: '「光る」の意味として正しいものを選びましょう。', options: ['明るくかがやく', 'くらくなる', '音を出す', 'においがする'], correctAnswer: '明るくかがやく', explanation: '「光る」は光を放って輝くことです。', level: 9, difficulty: 'medium' }),
  q({ id: 'l9-meaning-005', kanji: '引', type: 'meaning', question: '「引く」の意味として正しいものを選びましょう。', options: ['手前に動かす', '前に進める', '上に上げる', '下に落とす'], correctAnswer: '手前に動かす', explanation: '「引く」は自分の方に近づけるように動かすことです。', level: 9, difficulty: 'medium' }),
  q({ id: 'l9-writing-001', kanji: '毎', type: 'writing', question: '「マイ」を表す漢字を選びましょう。', options: ['毎', '母', '海', '梅'], correctAnswer: '毎', explanation: '「マイ」は「毎」と書きます。', level: 9, difficulty: 'easy' }),
  q({ id: 'l9-writing-002', kanji: '肉', type: 'writing', question: '「ニク」を表す漢字を選びましょう。', options: ['肉', '内', '円', '同'], correctAnswer: '肉', explanation: '「ニク」は「肉」と書きます。', level: 9, difficulty: 'easy' }),
  q({ id: 'l9-writing-003', kanji: '妹', type: 'writing', question: '「いもうと」を表す漢字を選びましょう。', options: ['妹', '姉', '母', '兄'], correctAnswer: '妹', explanation: '「いもうと」は「妹」と書きます。', level: 9, difficulty: 'easy' }),
  q({ id: 'l9-writing-004', kanji: '馬', type: 'writing', question: '「うま」を表す漢字を選びましょう。', options: ['馬', '鳥', '牛', '魚'], correctAnswer: '馬', explanation: '「うま」は「馬」と書きます。', level: 9, difficulty: 'easy' }),
  q({ id: 'l9-writing-005', kanji: '場', type: 'writing', question: '「ば」を表す漢字を選びましょう。', options: ['場', '土', '地', '所'], correctAnswer: '場', explanation: '「ば」は「場」と書きます（場所＝ばしょ）。', level: 9, difficulty: 'medium' }),
  q({ id: 'l9-usage-001', kanji: '前', type: 'usage', question: '「なまえ」に入る漢字を選びましょう。「名＿」', options: ['前', '後', '間', '中'], correctAnswer: '前', explanation: '「名前」で「なまえ」と読みます。', level: 9, difficulty: 'medium' }),
  q({ id: 'l9-usage-002', kanji: '場', type: 'usage', question: '「＿しょでまちあわせる」に入る漢字を選びましょう。', options: ['場', '間', '所', '前'], correctAnswer: '場', explanation: '「場所」で「ばしょ」と読みます。', level: 9, difficulty: 'medium' }),
  q({ id: 'l9-usage-003', kanji: '通', type: 'usage', question: '「まいにち がっこうに＿う」に入る漢字を選びましょう。', options: ['通', '走', '行', '来'], correctAnswer: '通', explanation: '「通う」で「かよう」と読みます。', level: 9, difficulty: 'medium' }),
  q({ id: 'l9-usage-004', kanji: '妹', type: 'usage', question: '「わたしの＿は五さいです」に入る漢字を選びましょう。', options: ['妹', '姉', '兄', '父'], correctAnswer: '妹', explanation: '「妹」で「いもうと」と読みます。', level: 9, difficulty: 'medium' }),
  q({ id: 'l9-usage-005', kanji: '近', type: 'usage', question: '「えきの＿くにすんでいる」に入る漢字を選びましょう。', options: ['近', '遠', '外', '中'], correctAnswer: '近', explanation: '「近く」で「ちかく」と読みます。', level: 9, difficulty: 'hard' }),

  // ============ 8級（小学3年生相当） ============
  q({ id: 'l8-reading-001', kanji: '由', type: 'reading', question: '次の漢字の読みがなを選びましょう。「由」', options: ['ユ', 'リ', 'ヨウ', 'シン'], correctAnswer: 'ユ', explanation: '「由」は「ユ」と読みます（理由＝りゆう）。', level: 8, difficulty: 'medium' }),
  q({ id: 'l8-reading-002', kanji: '湯', type: 'reading', question: '次の漢字の読みがなを選びましょう。「湯」', options: ['ゆ', 'みず', 'こおり', 'ゆき'], correctAnswer: 'ゆ', explanation: '「湯」は「ゆ」と読みます（お湯＝おゆ）。', level: 8, difficulty: 'easy' }),
  q({ id: 'l8-reading-003', kanji: '仕', type: 'reading', question: '次の漢字の読みがなを選びましょう。「仕」', options: ['シ', 'ジ', 'セイ', 'サ'], correctAnswer: 'シ', explanation: '「仕」は「シ」と読みます（仕事＝しごと）。', level: 8, difficulty: 'medium' }),
  q({ id: 'l8-reading-004', kanji: '銀', type: 'reading', question: '次の漢字の読みがなを選びましょう。「銀」', options: ['ギン', 'キン', 'テツ', 'ドウ'], correctAnswer: 'ギン', explanation: '「銀」は「ギン」と読みます（銀行＝ぎんこう）。', level: 8, difficulty: 'medium' }),
  q({ id: 'l8-reading-005', kanji: '油', type: 'reading', question: '次の漢字の読みがなを選びましょう。「油」', options: ['あぶら', 'みず', 'こおり', 'しる'], correctAnswer: 'あぶら', explanation: '「油」は「あぶら」と読みます（石油＝せきゆ）。', level: 8, difficulty: 'medium' }),
  q({ id: 'l8-meaning-001', kanji: '氷', type: 'meaning', question: '「氷」の意味として正しいものを選びましょう。', options: ['こおった水', 'あたたかい水', 'あまい水', 'うみの水'], correctAnswer: 'こおった水', explanation: '「氷」は水が凍って固まったものです。', level: 8, difficulty: 'easy' }),
  q({ id: 'l8-meaning-002', kanji: '真', type: 'meaning', question: '「真」の意味として正しいものを選びましょう。', options: ['まったく・ほんとうの', 'にせの', 'すこしの', 'おおきな'], correctAnswer: 'まったく・ほんとうの', explanation: '「真」は本当・純粋であることを表します（真夏＝まなつ）。', level: 8, difficulty: 'medium' }),
  q({ id: 'l8-meaning-003', kanji: '拾', type: 'meaning', question: '「拾う」の意味として正しいものを選びましょう。', options: ['落ちているものを手に取る', '物をなげる', '物をわたす', '物をかくす'], correctAnswer: '落ちているものを手に取る', explanation: '「拾う」は落ちているものを取り上げることです。', level: 8, difficulty: 'medium' }),
  q({ id: 'l8-meaning-004', kanji: '開', type: 'meaning', question: '「開ける」の意味として正しいものを選びましょう。', options: ['とじていたものをひらく', 'とじる', 'こわす', 'つくる'], correctAnswer: 'とじていたものをひらく', explanation: '「開ける」は閉じていたものを開くことです。', level: 8, difficulty: 'easy' }),
  q({ id: 'l8-meaning-005', kanji: '悪', type: 'meaning', question: '「悪い」の意味として正しいものを選びましょう。', options: ['よくない', 'よい', 'ふつう', 'おおきい'], correctAnswer: 'よくない', explanation: '「悪い」は良くない状態を表します。', level: 8, difficulty: 'easy' }),
  q({ id: 'l8-writing-001', kanji: '湯', type: 'writing', question: '「おふろのゆ」の「ゆ」を表す漢字を選びましょう。', options: ['湯', '水', '氷', '雪'], correctAnswer: '湯', explanation: '「ゆ」は「湯」と書きます。', level: 8, difficulty: 'easy' }),
  q({ id: 'l8-writing-002', kanji: '氷', type: 'writing', question: '「こおり」を表す漢字を選びましょう。', options: ['氷', '雪', '雨', '水'], correctAnswer: '氷', explanation: '「こおり」は「氷」と書きます。', level: 8, difficulty: 'easy' }),
  q({ id: 'l8-writing-003', kanji: '銀', type: 'writing', question: '「ギン」を表す漢字を選びましょう。', options: ['銀', '金', '鉄', '銅'], correctAnswer: '銀', explanation: '「ギン」は「銀」と書きます。', level: 8, difficulty: 'medium' }),
  q({ id: 'l8-writing-004', kanji: '油', type: 'writing', question: '「あぶら」を表す漢字を選びましょう。', options: ['油', '水', '湯', '氷'], correctAnswer: '油', explanation: '「あぶら」は「油」と書きます。', level: 8, difficulty: 'medium' }),
  q({ id: 'l8-writing-005', kanji: '炭', type: 'writing', question: '「すみ」を表す漢字を選びましょう。', options: ['炭', '灰', '火', '石'], correctAnswer: '炭', explanation: '「すみ」は「炭」と書きます（木炭＝もくたん）。', level: 8, difficulty: 'medium' }),
  q({ id: 'l8-usage-001', kanji: '由', type: 'usage', question: '「り＿でがっこうをやすんだ」に入る漢字を選びましょう。', options: ['由', '実', '田', '申'], correctAnswer: '由', explanation: '「理由」で「りゆう」と読みます。', level: 8, difficulty: 'hard' }),
  q({ id: 'l8-usage-002', kanji: '仕', type: 'usage', question: '「おとうさんの＿ごと」に入る漢字を選びましょう。', options: ['仕', '休', '働', '作'], correctAnswer: '仕', explanation: '「仕事」で「しごと」と読みます。', level: 8, difficulty: 'medium' }),
  q({ id: 'l8-usage-003', kanji: '銀', type: 'usage', question: '「お金をあずける＿こう」に入る漢字を選びましょう。', options: ['銀', '金', '両', '行'], correctAnswer: '銀', explanation: '「銀行」で「ぎんこう」と読みます。', level: 8, difficulty: 'medium' }),
  q({ id: 'l8-usage-004', kanji: '湯', type: 'usage', question: '「おふろにあつい お＿をはる」に入る漢字を選びましょう。', options: ['湯', '水', '氷', '雪'], correctAnswer: '湯', explanation: '「お湯」で「おゆ」と読みます。', level: 8, difficulty: 'easy' }),
  q({ id: 'l8-usage-005', kanji: '開', type: 'usage', question: '「まどを＿ける」に入る漢字を選びましょう。', options: ['開', '閉', '入', '出'], correctAnswer: '開', explanation: '「開ける」で「あける」と読みます。', level: 8, difficulty: 'easy' }),

  // ============ 7級（小学4年生相当） ============
  q({ id: 'l7-reading-001', kanji: '民', type: 'reading', question: '次の漢字の読みがなを選びましょう。「民」', options: ['ミン', 'コク', 'シン', 'カン'], correctAnswer: 'ミン', explanation: '「民」は「ミン」と読みます（国民＝こくみん）。', level: 7, difficulty: 'medium' }),
  q({ id: 'l7-reading-002', kanji: '典', type: 'reading', question: '次の漢字の読みがなを選びましょう。「典」', options: ['テン', 'ジ', 'ショ', 'ブン'], correctAnswer: 'テン', explanation: '「典」は「テン」と読みます（辞典＝じてん）。', level: 7, difficulty: 'medium' }),
  q({ id: 'l7-reading-003', kanji: '健', type: 'reading', question: '次の漢字の読みがなを選びましょう。「健」', options: ['ケン', 'コウ', 'アン', 'ヘイ'], correctAnswer: 'ケン', explanation: '「健」は「ケン」と読みます（健康＝けんこう）。', level: 7, difficulty: 'medium' }),
  q({ id: 'l7-reading-004', kanji: '械', type: 'reading', question: '次の漢字の読みがなを選びましょう。「械」', options: ['カイ', 'キ', 'ゲン', 'セイ'], correctAnswer: 'カイ', explanation: '「械」は「カイ」と読みます（機械＝きかい）。', level: 7, difficulty: 'medium' }),
  q({ id: 'l7-reading-005', kanji: '愛', type: 'reading', question: '次の漢字の読みがなを選びましょう。「愛」', options: ['アイ', 'ジョウ', 'ケン', 'シン'], correctAnswer: 'アイ', explanation: '「愛」は「アイ」と読みます（愛情＝あいじょう）。', level: 7, difficulty: 'easy' }),
  q({ id: 'l7-meaning-001', kanji: '産', type: 'meaning', question: '「産まれる」の意味として正しいものを選びましょう。', options: ['この世に生まれ出る', 'そだつ', 'しぬ', 'あるく'], correctAnswer: 'この世に生まれ出る', explanation: '「産まれる」は誕生することです。', level: 7, difficulty: 'medium' }),
  q({ id: 'l7-meaning-002', kanji: '泣', type: 'meaning', question: '「泣く」の意味として正しいものを選びましょう。', options: ['なみだを流す', 'わらう', 'ねむる', 'はしる'], correctAnswer: 'なみだを流す', explanation: '「泣く」は涙を流して悲しみなどを表すことです。', level: 7, difficulty: 'easy' }),
  q({ id: 'l7-meaning-003', kanji: '無', type: 'meaning', question: '「無い」の意味として正しいものを選びましょう。', options: ['存在しない', '存在する', '大きい', '小さい'], correctAnswer: '存在しない', explanation: '「無い」は存在しないことを表します。', level: 7, difficulty: 'easy' }),
  q({ id: 'l7-meaning-004', kanji: '唱', type: 'meaning', question: '「唱える」の意味として正しいものを選びましょう。', options: ['声に出して言う', '書く', '聞く', 'かんがえる'], correctAnswer: '声に出して言う', explanation: '「唱える」は声に出して言うことです（合唱＝がっしょう）。', level: 7, difficulty: 'medium' }),
  q({ id: 'l7-meaning-005', kanji: '標', type: 'meaning', question: '「標」の意味として正しいものを選びましょう。', options: ['めじるし', 'おと', 'におい', 'あじ'], correctAnswer: 'めじるし', explanation: '「標」は目印を表します（目標＝もくひょう）。', level: 7, difficulty: 'medium' }),
  q({ id: 'l7-writing-001', kanji: '愛', type: 'writing', question: '「アイ」を表す漢字を選びましょう。', options: ['愛', '恋', '好', '友'], correctAnswer: '愛', explanation: '「アイ」は「愛」と書きます。', level: 7, difficulty: 'easy' }),
  q({ id: 'l7-writing-002', kanji: '泣', type: 'writing', question: '「なく」を表す漢字を選びましょう。（涙を流す方）', options: ['泣', '鳴', '笑', '叫'], correctAnswer: '泣', explanation: '「なく（涙を流す）」は「泣く」と書きます。', level: 7, difficulty: 'medium' }),
  q({ id: 'l7-writing-003', kanji: '健', type: 'writing', question: '「ケン」を表す漢字を選びましょう。（健康の健）', options: ['健', '建', '険', '験'], correctAnswer: '健', explanation: '「ケン」（健康）は「健」と書きます。', level: 7, difficulty: 'hard' }),
  q({ id: 'l7-writing-004', kanji: '産', type: 'writing', question: '「さん」と読み、「うむ・うまれる」の意味を表す漢字を選びましょう。', options: ['産', '育', '成', '続'], correctAnswer: '産', explanation: '「うまれる」は「産まれる」とも書きます。', level: 7, difficulty: 'medium' }),
  q({ id: 'l7-writing-005', kanji: '民', type: 'writing', question: '「ミン」を表す漢字を選びましょう。（国民の民）', options: ['民', '国', '人', '皆'], correctAnswer: '民', explanation: '「ミン」（国民）は「民」と書きます。', level: 7, difficulty: 'medium' }),
  q({ id: 'l7-usage-001', kanji: '典', type: 'usage', question: '「ことばのいみをしらべる、じ＿」に入る漢字を選びましょう。', options: ['典', '書', '本', '文'], correctAnswer: '典', explanation: '「辞典」で「じてん」と読みます。', level: 7, difficulty: 'medium' }),
  q({ id: 'l7-usage-002', kanji: '健', type: 'usage', question: '「＿こうにきをつける」に入る漢字を選びましょう。', options: ['健', '建', '験', '検'], correctAnswer: '健', explanation: '「健康」で「けんこう」と読みます。', level: 7, difficulty: 'hard' }),
  q({ id: 'l7-usage-003', kanji: '械', type: 'usage', question: '「きかいを使う、機＿」に入る漢字を選びましょう。', options: ['械', '会', '回', '海'], correctAnswer: '械', explanation: '「機械」で「きかい」と読みます。', level: 7, difficulty: 'hard' }),
  q({ id: 'l7-usage-004', kanji: '愛', type: 'usage', question: '「かぞくを＿する」に入る漢字を選びましょう。', options: ['愛', '好', '楽', '思'], correctAnswer: '愛', explanation: '「愛する」で「あいする」と読みます。', level: 7, difficulty: 'easy' }),
  q({ id: 'l7-usage-005', kanji: '標', type: 'usage', question: '「もく＿をたてる」に入る漢字を選びましょう。', options: ['標', '票', '漂', '表'], correctAnswer: '標', explanation: '「目標」で「もくひょう」と読みます。', level: 7, difficulty: 'hard' }),

  // ============ 6級（小学5年生相当） ============
  q({ id: 'l6-reading-001', kanji: '停', type: 'reading', question: '次の漢字の読みがなを選びましょう。「停」', options: ['テイ', 'ハン', 'キュウ', 'シ'], correctAnswer: 'テイ', explanation: '「停」は「テイ」と読みます（停止＝ていし）。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-reading-002', kanji: '航', type: 'reading', question: '次の漢字の読みがなを選びましょう。「航」', options: ['コウ', 'セン', 'カイ', 'フネ'], correctAnswer: 'コウ', explanation: '「航」は「コウ」と読みます（航海＝こうかい）。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-reading-003', kanji: '脈', type: 'reading', question: '次の漢字の読みがなを選びましょう。「脈」', options: ['ミャク', 'ケツ', 'シン', 'タイ'], correctAnswer: 'ミャク', explanation: '「脈」は「ミャク」と読みます（山脈＝さんみゃく）。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-reading-004', kanji: '費', type: 'reading', question: '次の漢字の読みがなを選びましょう。「費」', options: ['ヒ', 'ザイ', 'キン', 'ダイ'], correctAnswer: 'ヒ', explanation: '「費」は「ヒ」と読みます（費用＝ひよう）。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-reading-005', kanji: '士', type: 'reading', question: '次の漢字の読みがなを選びましょう。「士」', options: ['シ', 'ヘイ', 'グン', 'ジン'], correctAnswer: 'シ', explanation: '「士」は「シ」と読みます（兵士＝へいし）。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-meaning-001', kanji: '許', type: 'meaning', question: '「許す」の意味として正しいものを選びましょう。', options: ['よいと認める', 'だめだと言う', 'わすれる', 'おこる'], correctAnswer: 'よいと認める', explanation: '「許す」は認めて良いとすることです。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-meaning-002', kanji: '解', type: 'meaning', question: '「解く」の意味として正しいものを選びましょう。', options: ['答えを出す・ほどく', 'むすぶ', 'かくす', 'おぼえる'], correctAnswer: '答えを出す・ほどく', explanation: '「解く」は問題の答えを出す、また結び目をほどくことです。', level: 6, difficulty: 'easy' }),
  q({ id: 'l6-meaning-003', kanji: '招', type: 'meaning', question: '「招く」の意味として正しいものを選びましょう。', options: ['人をよぶ', '人をおくる', '人をさがす', '人をまつ'], correctAnswer: '人をよぶ', explanation: '「招く」は人を招待して呼ぶことです。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-meaning-004', kanji: '暴', type: 'meaning', question: '「暴れる」の意味として正しいものを選びましょう。', options: ['あらあらしく動く', 'しずかにする', 'ねむる', 'わらう'], correctAnswer: 'あらあらしく動く', explanation: '「暴れる」は激しく荒々しく動くことです。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-meaning-005', kanji: '非', type: 'meaning', question: '「非常」の意味として正しいものを選びましょう。', options: ['ふつうでないこと', 'いつも通りのこと', 'たのしいこと', 'かんたんなこと'], correctAnswer: 'ふつうでないこと', explanation: '「非常」は普通ではない状態を表します。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-writing-001', kanji: '停', type: 'writing', question: '「テイ」を表す漢字を選びましょう。（停止の停）', options: ['停', '定', '低', '底'], correctAnswer: '停', explanation: '「テイ」（停止）は「停」と書きます。', level: 6, difficulty: 'hard' }),
  q({ id: 'l6-writing-002', kanji: '航', type: 'writing', question: '「コウ」を表す漢字を選びましょう。（航海の航）', options: ['航', '港', '行', '交'], correctAnswer: '航', explanation: '「コウ」（航海）は「航」と書きます。', level: 6, difficulty: 'hard' }),
  q({ id: 'l6-writing-003', kanji: '許', type: 'writing', question: '「ゆるす」を表す漢字を選びましょう。', options: ['許', '認', '信', '謝'], correctAnswer: '許', explanation: '「ゆるす」は「許す」と書きます。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-writing-004', kanji: '解', type: 'writing', question: '「とく」を表す漢字を選びましょう。（問題をとく）', options: ['解', '説', '読', '聞'], correctAnswer: '解', explanation: '「とく（問題を）」は「解く」と書きます。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-writing-005', kanji: '費', type: 'writing', question: '「ヒ」を表す漢字を選びましょう。（費用の費）', options: ['費', '非', '比', '肥'], correctAnswer: '費', explanation: '「ヒ」（費用）は「費」と書きます。', level: 6, difficulty: 'hard' }),
  q({ id: 'l6-usage-001', kanji: '停', type: 'usage', question: '「バスが＿しゃじょうにとまる」に入る漢字を選びましょう。', options: ['停', '乗', '止', '待'], correctAnswer: '停', explanation: '「停車場」で「ていしゃじょう」と読みます。', level: 6, difficulty: 'hard' }),
  q({ id: 'l6-usage-002', kanji: '解', type: 'usage', question: '「もんだいを＿く」に入る漢字を選びましょう。', options: ['解', '答', '問', '考'], correctAnswer: '解', explanation: '「解く」で「とく」と読みます。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-usage-003', kanji: '招', type: 'usage', question: '「ともだちを家に＿く」に入る漢字を選びましょう。', options: ['招', '呼', '来', '行'], correctAnswer: '招', explanation: '「招く」で「まねく」と読みます。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-usage-004', kanji: '許', type: 'usage', question: '「がいしゅつを＿してもらう」に入る漢字を選びましょう。', options: ['許', '認', '説', '謝'], correctAnswer: '許', explanation: '「許す」で「ゆるす」と読みます。', level: 6, difficulty: 'medium' }),
  q({ id: 'l6-usage-005', kanji: '費', type: 'usage', question: '「こうつう＿がかかる」に入る漢字を選びましょう。', options: ['費', '料', '代', '金'], correctAnswer: '費', explanation: '「費用」で「ひよう」と読みます。', level: 6, difficulty: 'medium' }),

  // ============ 5級（小学6年生相当） ============
  q({ id: 'l5-reading-001', kanji: '幼', type: 'reading', question: '次の漢字の読みがなを選びましょう。「幼」', options: ['ヨウ', 'ショウ', 'チ', 'ジ'], correctAnswer: 'ヨウ', explanation: '「幼」は「ヨウ」とも読みます（幼い＝おさない）。', level: 5, difficulty: 'medium' }),
  q({ id: 'l5-reading-002', kanji: '糖', type: 'reading', question: '次の漢字の読みがなを選びましょう。「糖」', options: ['トウ', 'ミツ', 'カン', 'アマ'], correctAnswer: 'トウ', explanation: '「糖」は「トウ」と読みます（砂糖＝さとう）。', level: 5, difficulty: 'medium' }),
  q({ id: 'l5-reading-003', kanji: '宅', type: 'reading', question: '次の漢字の読みがなを選びましょう。「宅」', options: ['タク', 'イエ', 'カ', 'ジュウ'], correctAnswer: 'タク', explanation: '「宅」は「タク」と読みます（自宅＝じたく）。', level: 5, difficulty: 'medium' }),
  q({ id: 'l5-reading-004', kanji: '策', type: 'reading', question: '次の漢字の読みがなを選びましょう。「策」', options: ['サク', 'ケイ', 'ホウ', 'ダン'], correctAnswer: 'サク', explanation: '「策」は「サク」と読みます（対策＝たいさく）。', level: 5, difficulty: 'medium' }),
  q({ id: 'l5-reading-005', kanji: '胃', type: 'reading', question: '次の漢字の読みがなを選びましょう。「胃」', options: ['イ', 'チョウ', 'シン', 'ハイ'], correctAnswer: 'イ', explanation: '「胃」は「イ」と読みます（胃薬＝いぐすり）。', level: 5, difficulty: 'easy' }),
  q({ id: 'l5-meaning-001', kanji: '危', type: 'meaning', question: '「危ない」の意味として正しいものを選びましょう。', options: ['あぶない・きけんな', 'あんぜんな', 'たのしい', 'べんりな'], correctAnswer: 'あぶない・きけんな', explanation: '「危ない」は危険な状態を表します。', level: 5, difficulty: 'easy' }),
  q({ id: 'l5-meaning-002', kanji: '欲', type: 'meaning', question: '「欲しい」の意味として正しいものを選びましょう。', options: ['手に入れたいと思う', 'いらないと思う', 'こわいと思う', 'ふしぎに思う'], correctAnswer: '手に入れたいと思う', explanation: '「欲しい」は何かを手に入れたい気持ちを表します。', level: 5, difficulty: 'easy' }),
  q({ id: 'l5-meaning-003', kanji: '並', type: 'meaning', question: '「並ぶ」の意味として正しいものを選びましょう。', options: ['列になって連なる', 'ちらばる', 'かくれる', 'あつまってかたまる'], correctAnswer: '列になって連なる', explanation: '「並ぶ」は一列に連なって位置することです。', level: 5, difficulty: 'easy' }),
  q({ id: 'l5-meaning-004', kanji: '誠', type: 'meaning', question: '「誠」の意味として正しいものを選びましょう。', options: ['うそのないまごころ', 'うたがう気持ち', 'おこる気持ち', 'こわがる気持ち'], correctAnswer: 'うそのないまごころ', explanation: '「誠」は偽りのない真心を表します（誠実＝せいじつ）。', level: 5, difficulty: 'medium' }),
  q({ id: 'l5-meaning-005', kanji: '縦', type: 'meaning', question: '「縦」の意味として正しいものを選びましょう。', options: ['たての方向', 'よこの方向', 'ななめの方向', 'まるい方向'], correctAnswer: 'たての方向', explanation: '「縦」は上下の方向を表します（縦横＝たてよこ）。', level: 5, difficulty: 'easy' }),
  q({ id: 'l5-writing-001', kanji: '危', type: 'writing', question: '「あぶない」を表す漢字を選びましょう。', options: ['危', '険', '怖', '悪'], correctAnswer: '危', explanation: '「あぶない」は「危ない」と書きます。', level: 5, difficulty: 'medium' }),
  q({ id: 'l5-writing-002', kanji: '欲', type: 'writing', question: '「ほしい」を表す漢字を選びましょう。', options: ['欲', '望', '好', '願'], correctAnswer: '欲', explanation: '「ほしい」は「欲しい」と書きます。', level: 5, difficulty: 'medium' }),
  q({ id: 'l5-writing-003', kanji: '並', type: 'writing', question: '「ならぶ」を表す漢字を選びましょう。', options: ['並', '列', '連', '続'], correctAnswer: '並', explanation: '「ならぶ」は「並ぶ」と書きます。', level: 5, difficulty: 'medium' }),
  q({ id: 'l5-writing-004', kanji: '宅', type: 'writing', question: '「タク」を表す漢字を選びましょう。（自宅の宅）', options: ['宅', '家', '室', '屋'], correctAnswer: '宅', explanation: '「タク」（自宅）は「宅」と書きます。', level: 5, difficulty: 'hard' }),
  q({ id: 'l5-writing-005', kanji: '胃', type: 'writing', question: '「イ」を表す漢字を選びましょう。（胃薬の胃）', options: ['胃', '肺', '腸', '心'], correctAnswer: '胃', explanation: '「イ」（胃薬）は「胃」と書きます。', level: 5, difficulty: 'hard' }),
  q({ id: 'l5-usage-001', kanji: '危', type: 'usage', question: '「その川であそぶのは＿ない」に入る漢字を選びましょう。', options: ['危', '悪', '重', '難'], correctAnswer: '危', explanation: '「危ない」で「あぶない」と読みます。', level: 5, difficulty: 'easy' }),
  q({ id: 'l5-usage-002', kanji: '策', type: 'usage', question: '「もんだいのたい＿をかんがえる」に入る漢字を選びましょう。', options: ['策', '対', '案', '法'], correctAnswer: '策', explanation: '「対策」で「たいさく」と読みます。', level: 5, difficulty: 'medium' }),
  q({ id: 'l5-usage-003', kanji: '宅', type: 'usage', question: '「じ＿でべんきょうする」に入る漢字を選びましょう。', options: ['宅', '分', '習', '図'], correctAnswer: '宅', explanation: '「自宅」で「じたく」と読みます。', level: 5, difficulty: 'hard' }),
  q({ id: 'l5-usage-004', kanji: '並', type: 'usage', question: '「れつに＿ぶ」に入る漢字を選びましょう。', options: ['並', '連', '続', '重'], correctAnswer: '並', explanation: '「並ぶ」で「ならぶ」と読みます。', level: 5, difficulty: 'medium' }),
  q({ id: 'l5-usage-005', kanji: '糖', type: 'usage', question: '「さ＿をいれてあまくする」に入る漢字を選びましょう。', options: ['糖', '塩', '味', '甘'], correctAnswer: '糖', explanation: '「砂糖」で「さとう」と読みます。', level: 5, difficulty: 'medium' }),
];

async function main() {
  const batch = db.batch();
  const collection = db.collection('examQuestions');

  for (const item of questions) {
    const ref = collection.doc(item.questionId);
    batch.set(ref, item);
  }

  await batch.commit();
  console.log(`✅ ${questions.length}件の問題を examQuestions コレクションに投入しました（9級〜5級分、各20問）。`);
}

main().catch((err) => {
  console.error('❌ 投入に失敗しました:', err);
  process.exit(1);
});
