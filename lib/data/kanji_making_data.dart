// GENERATED FILE - do not edit by hand. Run scripts/generate_kanji_making_data.py.
//
// 漢字作りの演習（漢検の「漢字作り」。7級〜2級で出題）に使う問題。
// 元データ: scripts/data/kanji_making.tsv。全ての字が10級〜2級の配当漢字にある問題だけを入れている。

class KanjiMakingItem {
  /// 問題の表示（例: 『条A・B設・C査』『A景・景B』）。
  final String prompt;
  final String instruction;

  /// A・B・C に入る漢字（正解）と、誤った組み合わせ2つ（どれも A・B・C の並び）。
  final List<String> answer;
  final List<List<String>> wrong;

  /// 使う字のうち最も難しい字の級（例: 'LEVEL_5'）。この級以下の演習で出す。
  final String level;

  const KanjiMakingItem(this.prompt, this.instruction, this.answer, this.wrong, this.level);
}

const List<KanjiMakingItem> kKanjiMaking = [
  KanjiMakingItem('条A・B設・C査', 'A・B・C には「けん」と読む漢字が入ります。正しい組み合わせはどれ？', ['件', '建', '検'], [['建', '検', '件'], ['検', '件', '建']], 'LEVEL_6'),
  KanjiMakingItem('A校・気B・C海', 'A・B・C には「こう」と読む漢字が入ります。正しい組み合わせはどれ？', ['高', '候', '航'], [['候', '航', '高'], ['航', '高', '候']], 'LEVEL_6'),
  KanjiMakingItem('A察・B情・C全', 'A・B・C には「かん」と読む漢字が入ります。正しい組み合わせはどれ？', ['観', '感', '完'], [['感', '完', '観'], ['完', '観', '感']], 'LEVEL_6'),
  KanjiMakingItem('A功・B治・C質', 'A・B・C には「せい」と読む漢字が入ります。正しい組み合わせはどれ？', ['成', '政', '性'], [['政', '性', '成'], ['性', '成', '政']], 'LEVEL_6'),
  KanjiMakingItem('A議・B決・C岸', 'A・B・C には「かい」と読む漢字が入ります。正しい組み合わせはどれ？', ['会', '解', '海'], [['解', '海', '会'], ['海', '会', '解']], 'LEVEL_6'),
  KanjiMakingItem('A化・B来・C業', 'A・B・C には「しょう」と読む漢字が入ります。正しい組み合わせはどれ？', ['消', '将', '商'], [['将', '商', '消'], ['商', '消', '将']], 'LEVEL_3'),
  KanjiMakingItem('A度・B育・C風', 'A・B・C には「たい」と読む漢字が入ります。正しい組み合わせはどれ？', ['態', '体', '台'], [['体', '台', '態'], ['台', '態', '体']], 'LEVEL_6'),
  KanjiMakingItem('A挙・B争・C生', 'A・B・C には「せん」と読む漢字が入ります。正しい組み合わせはどれ？', ['選', '戦', '先'], [['戦', '先', '選'], ['先', '選', '戦']], 'LEVEL_7'),
  KanjiMakingItem('A力・B室・C走', 'A・B・C には「きょう」と読む漢字が入ります。正しい組み合わせはどれ？', ['協', '教', '競'], [['教', '競', '協'], ['競', '協', '教']], 'LEVEL_6'),
  KanjiMakingItem('A景・景B', 'AとBに入る漢字の組み合わせはどれ？', ['夜', '品'], [['信', '色'], ['結', '面']], 'LEVEL_7'),
  KanjiMakingItem('A学・学B', 'AとBに入る漢字の組み合わせはどれ？', ['入', '年'], [['花', '体'], ['空', '橋']], 'LEVEL_8'),
  KanjiMakingItem('A校・校B', 'AとBに入る漢字の組み合わせはどれ？', ['学', '長'], [['花', '体'], ['空', '橋']], 'LEVEL_8'),
  KanjiMakingItem('A水・水B', 'AとBに入る漢字の組み合わせはどれ？', ['海', '泳'], [['本', '犬'], ['空', '雨']], 'LEVEL_8'),
  KanjiMakingItem('A気・気B', 'AとBに入る漢字の組み合わせはどれ？', ['天', '分'], [['花', '手'], ['犬', '足']], 'LEVEL_9'),
  KanjiMakingItem('A電・電B', 'AとBに入る漢字の組み合わせはどれ？', ['停', '車'], [['花', '犬'], ['森', '村']], 'LEVEL_6'),
  KanjiMakingItem('A国・国B', 'AとBに入る漢字の組み合わせはどれ？', ['外', '語'], [['花', '犬'], ['草', '石']], 'LEVEL_9'),
  KanjiMakingItem('A音・音B', 'AとBに入る漢字の組み合わせはどれ？', ['発', '楽'], [['犬', '花'], ['森', '村']], 'LEVEL_8'),
  KanjiMakingItem('A山・山B', 'AとBに入る漢字の組み合わせはどれ？', ['登', '頂'], [['虫', '店'], ['糸', '紙']], 'LEVEL_5'),
  KanjiMakingItem('A人・人B', 'AとBに入る漢字の組み合わせはどれ？', ['大', '口'], [['犬', '村'], ['花', '石']], 'LEVEL_10'),
];
