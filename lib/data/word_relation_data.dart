// GENERATED FILE - do not edit by hand. Run scripts/generate_word_relations.py.
//
// 対義語・類義語の演習（漢検の「対義語・類義語」。8級〜2級で出題）に使う組。
// 元データ: scripts/data/word_relations.tsv。全ての字が10級〜2級の配当漢字にある組だけを入れている。

enum WordRelationKind { antonym, synonym }

class WordRelation {
  final WordRelationKind kind;
  final String word;
  final String reading; // ひらがな
  final String partner; // 対義語、または類義語
  final String partnerReading;
  /// 意味の分野。選択肢の紛らわしい候補は、別の分野から選ぶ。
  final String group;
  /// 2語の字のうち最も難しい字の級（例: 'LEVEL_5'）。この級以下の演習で出す。
  final String level;

  const WordRelation(
      this.kind, this.word, this.reading, this.partner, this.partnerReading, this.group, this.level);
}

const List<WordRelation> kWordRelations = [
  WordRelation(WordRelationKind.antonym, '上昇', 'じょうしょう', '下降', 'かこう', '空間', 'LEVEL_3'),
  WordRelation(WordRelationKind.antonym, '増加', 'ぞうか', '減少', 'げんしょう', '数量', 'LEVEL_6'),
  WordRelation(WordRelationKind.antonym, '勝利', 'しょうり', '敗北', 'はいぼく', '行動', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '成功', 'せいこう', '失敗', 'しっぱい', '行動', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '前進', 'ぜんしん', '後退', 'こうたい', '空間', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '賛成', 'さんせい', '反対', 'はんたい', '心', 'LEVEL_6'),
  WordRelation(WordRelationKind.antonym, '原因', 'げんいん', '結果', 'けっか', '状態', 'LEVEL_6'),
  WordRelation(WordRelationKind.antonym, '利益', 'りえき', '損失', 'そんしつ', '数量', 'LEVEL_6'),
  WordRelation(WordRelationKind.antonym, '入学', 'にゅうがく', '卒業', 'そつぎょう', '社会', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '出席', 'しゅっせき', '欠席', 'けっせき', '社会', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '内部', 'ないぶ', '外部', 'がいぶ', '空間', 'LEVEL_8'),
  WordRelation(WordRelationKind.antonym, '安全', 'あんぜん', '危険', 'きけん', '状態', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '拡大', 'かくだい', '縮小', 'しゅくしょう', '数量', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '軽視', 'けいし', '重視', 'じゅうし', '心', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '理想', 'りそう', '現実', 'げんじつ', '心', 'LEVEL_6'),
  WordRelation(WordRelationKind.antonym, '主観', 'しゅかん', '客観', 'きゃっかん', '心', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '肯定', 'こうてい', '否定', 'ひてい', '心', 'LEVEL_2_PRE'),
  WordRelation(WordRelationKind.antonym, '義務', 'ぎむ', '権利', 'けんり', '社会', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '供給', 'きょうきゅう', '需要', 'じゅよう', '社会', 'LEVEL_4'),
  WordRelation(WordRelationKind.antonym, '消費', 'しょうひ', '生産', 'せいさん', '社会', 'LEVEL_6'),
  WordRelation(WordRelationKind.antonym, '長所', 'ちょうしょ', '短所', 'たんしょ', '状態', 'LEVEL_8'),
  WordRelation(WordRelationKind.antonym, '往路', 'おうろ', '復路', 'ふくろ', '空間', 'LEVEL_6'),
  WordRelation(WordRelationKind.antonym, '直線', 'ちょくせん', '曲線', 'きょくせん', '空間', 'LEVEL_8'),
  WordRelation(WordRelationKind.antonym, '質問', 'しつもん', '回答', 'かいとう', '行動', 'LEVEL_6'),
  WordRelation(WordRelationKind.antonym, '都市', 'とし', '農村', 'のうそん', '社会', 'LEVEL_8'),
  WordRelation(WordRelationKind.antonym, '集合', 'しゅうごう', '解散', 'かいさん', '行動', 'LEVEL_6'),
  WordRelation(WordRelationKind.antonym, '優勢', 'ゆうせい', '劣勢', 'れっせい', '状態', 'LEVEL_4'),
  WordRelation(WordRelationKind.antonym, '豊作', 'ほうさく', '凶作', 'きょうさく', '社会', 'LEVEL_4'),
  WordRelation(WordRelationKind.antonym, '誕生', 'たんじょう', '死亡', 'しぼう', '状態', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '過去', 'かこ', '未来', 'みらい', '時間', 'LEVEL_6'),
  WordRelation(WordRelationKind.antonym, '悲観', 'ひかん', '楽観', 'らっかん', '心', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '偶然', 'ぐうぜん', '必然', 'ひつぜん', '状態', 'LEVEL_3'),
  WordRelation(WordRelationKind.antonym, '保守', 'ほしゅ', '革新', 'かくしん', '社会', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '単純', 'たんじゅん', '複雑', 'ふくざつ', '状態', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '自然', 'しぜん', '人工', 'じんこう', '状態', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '進歩', 'しんぽ', '退歩', 'たいほ', '状態', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '具体', 'ぐたい', '抽象', 'ちゅうしょう', '心', 'LEVEL_3'),
  WordRelation(WordRelationKind.antonym, '縦断', 'じゅうだん', '横断', 'おうだん', '空間', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '絶対', 'ぜったい', '相対', 'そうたい', '心', 'LEVEL_6'),
  WordRelation(WordRelationKind.antonym, '開店', 'かいてん', '閉店', 'へいてん', '社会', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '加入', 'かにゅう', '脱退', 'だったい', '社会', 'LEVEL_4'),
  WordRelation(WordRelationKind.antonym, '収入', 'しゅうにゅう', '支出', 'ししゅつ', '数量', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '輸入', 'ゆにゅう', '輸出', 'ゆしゅつ', '社会', 'LEVEL_6'),
  WordRelation(WordRelationKind.antonym, '満足', 'まんぞく', '不満', 'ふまん', '心', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '最高', 'さいこう', '最低', 'さいてい', '数量', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '最初', 'さいしょ', '最後', 'さいご', '時間', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '可決', 'かけつ', '否決', 'ひけつ', '社会', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '好調', 'こうちょう', '不調', 'ふちょう', '状態', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '固体', 'こたい', '液体', 'えきたい', '状態', 'LEVEL_6'),
  WordRelation(WordRelationKind.antonym, '善意', 'ぜんい', '悪意', 'あくい', '心', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '正常', 'せいじょう', '異常', 'いじょう', '状態', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '当選', 'とうせん', '落選', 'らくせん', '社会', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '急性', 'きゅうせい', '慢性', 'まんせい', '状態', 'LEVEL_4'),
  WordRelation(WordRelationKind.antonym, '勤勉', 'きんべん', '怠惰', 'たいだ', '心', 'LEVEL_2_PRE'),
  WordRelation(WordRelationKind.antonym, '天国', 'てんごく', '地獄', 'じごく', '状態', 'LEVEL_3'),
  WordRelation(WordRelationKind.antonym, '東洋', 'とうよう', '西洋', 'せいよう', '空間', 'LEVEL_8'),
  WordRelation(WordRelationKind.antonym, '攻撃', 'こうげき', '防御', 'ぼうぎょ', '行動', 'LEVEL_4'),
  WordRelation(WordRelationKind.antonym, '寒冷', 'かんれい', '温暖', 'おんだん', '状態', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '有害', 'ゆうがい', '無害', 'むがい', '状態', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '有料', 'ゆうりょう', '無料', 'むりょう', '社会', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '受信', 'じゅしん', '送信', 'そうしん', '行動', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '上品', 'じょうひん', '下品', 'げひん', '状態', 'LEVEL_8'),
  WordRelation(WordRelationKind.antonym, '生前', 'せいぜん', '死後', 'しご', '時間', 'LEVEL_8'),
  WordRelation(WordRelationKind.synonym, '永遠', 'えいえん', '永久', 'えいきゅう', '時間', 'LEVEL_6'),
  WordRelation(WordRelationKind.synonym, '方法', 'ほうほう', '手段', 'しゅだん', '行動', 'LEVEL_5'),
  WordRelation(WordRelationKind.synonym, '運命', 'うんめい', '宿命', 'しゅくめい', '状態', 'LEVEL_8'),
  WordRelation(WordRelationKind.synonym, '決心', 'けっしん', '決意', 'けつい', '心', 'LEVEL_8'),
  WordRelation(WordRelationKind.synonym, '外見', 'がいけん', '外観', 'がいかん', '状態', 'LEVEL_7'),
  WordRelation(WordRelationKind.synonym, '周囲', 'しゅうい', '周辺', 'しゅうへん', '空間', 'LEVEL_6'),
  WordRelation(WordRelationKind.synonym, '経験', 'けいけん', '体験', 'たいけん', '行動', 'LEVEL_6'),
  WordRelation(WordRelationKind.synonym, '容易', 'ようい', '簡単', 'かんたん', '状態', 'LEVEL_5'),
  WordRelation(WordRelationKind.synonym, '終了', 'しゅうりょう', '完了', 'かんりょう', '行動', 'LEVEL_3'),
  WordRelation(WordRelationKind.synonym, '発達', 'はったつ', '発展', 'はってん', '状態', 'LEVEL_5'),
  WordRelation(WordRelationKind.synonym, '増加', 'ぞうか', '増大', 'ぞうだい', '数量', 'LEVEL_6'),
  WordRelation(WordRelationKind.synonym, '同意', 'どうい', '賛成', 'さんせい', '心', 'LEVEL_6'),
  WordRelation(WordRelationKind.synonym, '熟練', 'じゅくれん', '老練', 'ろうれん', '状態', 'LEVEL_5'),
  WordRelation(WordRelationKind.synonym, '勇敢', 'ゆうかん', '果敢', 'かかん', '心', 'LEVEL_3'),
  WordRelation(WordRelationKind.synonym, '苦心', 'くしん', '苦労', 'くろう', '心', 'LEVEL_7'),
  WordRelation(WordRelationKind.synonym, '欠点', 'けってん', '短所', 'たんしょ', '状態', 'LEVEL_7'),
  WordRelation(WordRelationKind.synonym, '目的', 'もくてき', '目標', 'もくひょう', '行動', 'LEVEL_7'),
  WordRelation(WordRelationKind.synonym, '返事', 'へんじ', '回答', 'かいとう', '行動', 'LEVEL_8'),
  WordRelation(WordRelationKind.synonym, '感心', 'かんしん', '感嘆', 'かんたん', '心', 'LEVEL_4'),
  WordRelation(WordRelationKind.synonym, '思案', 'しあん', '熟慮', 'じゅくりょ', '心', 'LEVEL_4'),
  WordRelation(WordRelationKind.synonym, '死亡', 'しぼう', '死去', 'しきょ', '状態', 'LEVEL_5'),
  WordRelation(WordRelationKind.synonym, '成功', 'せいこう', '成就', 'じょうじゅ', '行動', 'LEVEL_5'),
  WordRelation(WordRelationKind.antonym, '自分', 'じぶん', '他人', 'たにん', '人', 'LEVEL_8'),
  WordRelation(WordRelationKind.antonym, '去年', 'きょねん', '来年', 'らいねん', '時間', 'LEVEL_8'),
  WordRelation(WordRelationKind.antonym, '昼間', 'ひるま', '夜間', 'やかん', '時間', 'LEVEL_9'),
  WordRelation(WordRelationKind.antonym, '男子', 'だんし', '女子', 'じょし', '人', 'LEVEL_10'),
  WordRelation(WordRelationKind.antonym, '朝食', 'ちょうしょく', '夕食', 'ゆうしょく', '時間', 'LEVEL_9'),
  WordRelation(WordRelationKind.antonym, '右側', 'みぎがわ', '左側', 'ひだりがわ', '空間', 'LEVEL_7'),
  WordRelation(WordRelationKind.antonym, '出発', 'しゅっぱつ', '到着', 'とうちゃく', '行動', 'LEVEL_4'),
  WordRelation(WordRelationKind.antonym, '始点', 'してん', '終点', 'しゅうてん', '空間', 'LEVEL_8'),
  WordRelation(WordRelationKind.antonym, '多数', 'たすう', '少数', 'しょうすう', '数量', 'LEVEL_9'),
  WordRelation(WordRelationKind.antonym, '新品', 'しんぴん', '中古', 'ちゅうこ', '状態', 'LEVEL_8'),
  WordRelation(WordRelationKind.antonym, '出口', 'でぐち', '入口', 'いりぐち', '空間', 'LEVEL_10'),
];
