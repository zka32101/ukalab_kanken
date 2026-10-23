// GENERATED FILE - do not edit by hand. Run scripts/generate_sanji_data.py.
//
// 三字熟語の演習（漢検の「三字熟語」。7級・6級で出題）に使う語と、各字の読み。
// 元データ: scripts/data/sanji_jukugo.tsv。全ての字が10級〜2級の配当漢字にある語だけを入れている。

class SanjiJukugo {
  final String word;

  /// 各字の、この熟語での読み（カタカナ。例: 不可能 → フ・カ・ノウ）。
  final List<String> readings;

  /// 含む字のうち最も難しい字の級（例: 'LEVEL_6'）。この級以下の演習で出す。
  final String level;

  const SanjiJukugo(this.word, this.readings, this.level);
}

const List<SanjiJukugo> kSanjiJukugo = [
  SanjiJukugo('不可能', ['フ', 'カ', 'ノウ'], 'LEVEL_6'),
  SanjiJukugo('証明書', ['ショウ', 'メイ', 'ショ'], 'LEVEL_6'),
  SanjiJukugo('図書館', ['ト', 'ショ', 'カン'], 'LEVEL_8'),
  SanjiJukugo('運動会', ['ウン', 'ドウ', 'カイ'], 'LEVEL_8'),
  SanjiJukugo('動物園', ['ドウ', 'ブツ', 'エン'], 'LEVEL_8'),
  SanjiJukugo('交通費', ['コウ', 'ツウ', 'ヒ'], 'LEVEL_6'),
  SanjiJukugo('消火器', ['ショウ', 'カ', 'キ'], 'LEVEL_7'),
  SanjiJukugo('非常口', ['ヒ', 'ジョウ', 'コウ'], 'LEVEL_6'),
  SanjiJukugo('自動車', ['ジ', 'ドウ', 'シャ'], 'LEVEL_8'),
  SanjiJukugo('水族館', ['スイ', 'ゾク', 'カン'], 'LEVEL_8'),
  SanjiJukugo('遊園地', ['ユウ', 'エン', 'チ'], 'LEVEL_8'),
  SanjiJukugo('参考書', ['サン', 'コウ', 'ショ'], 'LEVEL_7'),
  SanjiJukugo('郵便局', ['ユウ', 'ビン', 'キョク'], 'LEVEL_5'),
  SanjiJukugo('研究所', ['ケン', 'キュウ', 'ショ'], 'LEVEL_8'),
  SanjiJukugo('保健室', ['ホ', 'ケン', 'シツ'], 'LEVEL_6'),
  SanjiJukugo('博物館', ['ハク', 'ブツ', 'カン'], 'LEVEL_7'),
  SanjiJukugo('美術館', ['ビ', 'ジュツ', 'カン'], 'LEVEL_6'),
  SanjiJukugo('管理人', ['カン', 'リ', 'ニン'], 'LEVEL_7'),
  SanjiJukugo('入学式', ['ニュウ', 'ガク', 'シキ'], 'LEVEL_8'),
  SanjiJukugo('卒業式', ['ソツ', 'ギョウ', 'シキ'], 'LEVEL_7'),
  SanjiJukugo('開会式', ['カイ', 'カイ', 'シキ'], 'LEVEL_8'),
  SanjiJukugo('展覧会', ['テン', 'ラン', 'カイ'], 'LEVEL_5'),
  SanjiJukugo('音楽会', ['オン', 'ガク', 'カイ'], 'LEVEL_9'),
  SanjiJukugo('発表会', ['ハッ', 'ピョウ', 'カイ'], 'LEVEL_8'),
  SanjiJukugo('世界的', ['セ', 'カイ', 'テキ'], 'LEVEL_7'),
  SanjiJukugo('国際的', ['コク', 'サイ', 'テキ'], 'LEVEL_6'),
  SanjiJukugo('理想的', ['リ', 'ソウ', 'テキ'], 'LEVEL_7'),
  SanjiJukugo('具体的', ['グ', 'タイ', 'テキ'], 'LEVEL_7'),
  SanjiJukugo('積極的', ['セッ', 'キョク', 'テキ'], 'LEVEL_7'),
  SanjiJukugo('消極的', ['ショウ', 'キョク', 'テキ'], 'LEVEL_7'),
  SanjiJukugo('全国的', ['ゼン', 'コク', 'テキ'], 'LEVEL_7'),
  SanjiJukugo('科学的', ['カ', 'ガク', 'テキ'], 'LEVEL_7'),
  SanjiJukugo('一般的', ['イッ', 'パン', 'テキ'], 'LEVEL_4'),
  SanjiJukugo('日常的', ['ニチ', 'ジョウ', 'テキ'], 'LEVEL_6'),
  SanjiJukugo('歴史的', ['レキ', 'シ', 'テキ'], 'LEVEL_6'),
  SanjiJukugo('文化的', ['ブン', 'カ', 'テキ'], 'LEVEL_7'),
  SanjiJukugo('経済的', ['ケイ', 'ザイ', 'テキ'], 'LEVEL_5'),
  SanjiJukugo('社会的', ['シャ', 'カイ', 'テキ'], 'LEVEL_7'),
  SanjiJukugo('小数点', ['ショウ', 'スウ', 'テン'], 'LEVEL_9'),
  SanjiJukugo('未完成', ['ミ', 'カン', 'セイ'], 'LEVEL_7'),
  SanjiJukugo('無関係', ['ム', 'カン', 'ケイ'], 'LEVEL_7'),
  SanjiJukugo('不自然', ['フ', 'シ', 'ゼン'], 'LEVEL_7'),
  SanjiJukugo('不平等', ['フ', 'ビョウ', 'ドウ'], 'LEVEL_7'),
  SanjiJukugo('不安定', ['フ', 'アン', 'テイ'], 'LEVEL_7'),
  SanjiJukugo('無意味', ['ム', 'イ', 'ミ'], 'LEVEL_7'),
  SanjiJukugo('副社長', ['フク', 'シャ', 'チョウ'], 'LEVEL_7'),
  SanjiJukugo('大自然', ['ダイ', 'シ', 'ゼン'], 'LEVEL_7'),
  SanjiJukugo('新年会', ['シン', 'ネン', 'カイ'], 'LEVEL_9'),
  SanjiJukugo('体育祭', ['タイ', 'イク', 'サイ'], 'LEVEL_8'),
  SanjiJukugo('同窓会', ['ドウ', 'ソウ', 'カイ'], 'LEVEL_5'),
  SanjiJukugo('高気圧', ['コウ', 'キ', 'アツ'], 'LEVEL_6'),
  SanjiJukugo('低気圧', ['テイ', 'キ', 'アツ'], 'LEVEL_6'),
  SanjiJukugo('記念日', ['キ', 'ネン', 'ビ'], 'LEVEL_7'),
];
