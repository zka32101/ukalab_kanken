import 'dart:async';
import 'dart:math';
import 'package:ukalab_core/ui.dart' show CoinEvent, coinProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/compound_structure_data.dart';
import '../data/exam_prep_data.dart' show historyProvider;
import '../views/core_v069_entry.dart' show recordKankenReviewResult;
import '../data/level_kanji_data.dart';
import '../data/content_mistake_store.dart';
import '../data/upper_jukugo_data.dart';
import '../data/word_relation_data.dart';
import '../data/yoji_jukugo_data.dart';
import '../data/kanji_radical_data.dart';
import '../data/kanji_info_data.dart';
import '../data/kanji_making_data.dart';
import '../data/koji_data.dart';
import '../data/homophone_data.dart';
import '../data/kanji_stroke_count_data.dart';
import '../data/okurigana_data.dart';
import '../data/sanji_jukugo_data.dart';
import '../data/stroke_order_sample_data.dart';
import '../models/index.dart';
import '../providers/learning_goal_provider.dart';
import '../providers/spaced_repetition_provider.dart';
import '../providers/level_progress_provider.dart';
import '../providers/level_achievement_provider.dart' show correctQuestionIdsProvider;
import '../services/oshi_progress_store.dart';
import 'services_provider.dart';
import 'user_viewmodel.dart';

// 1回の演習セッションの問題数（達成感を出すため小さく区切る）
const int practiceSessionSize = 10;

/// 漢検の出題形式に合わせた演習モード
/// - reading: 漢字を見て読み方を答える（読みがな）
/// - writing: 読み方を見て漢字を答える（書き取り）
/// - radical: 漢字を見て部首を答える（9級以上で出題）
/// - compoundStructure: 二字熟語の構成（似た意味／対の意味／修飾／目的語）を答える（8級以下で出題）
/// - strokeCount: 漢字の画数を答える（漢検の「筆順・画数」。10級〜5級で出題）
/// - strokeOrder: 赤で示した画が何画目かを答える（漢検の「筆順」。10級〜5級で出題）
/// - okurigana: 正しい送りがなを選ぶ（漢検の「送りがな」。8級〜2級で出題）
/// - kanjiMaking: 同じ読みの漢字を熟語の空欄に入れて、組み合わせを選ぶ（漢検の「漢字作り」。7級〜2級で出題）
/// - sanji: 三字熟語の1字をカタカナにして、その漢字を答える（漢検の「三字熟語」。7級・6級で出題）
/// - yoji: 四字熟語の空欄に入る漢字を答える（漢検の「四字熟語」。5級〜2級で出題）
/// - antonym: 熟語の対義語を答える（漢検の「対義語」。8級〜2級で出題）
/// - synonym: 熟語の類義語を答える（漢検の「類義語」。6級〜2級で出題）
/// - homophone: 文の中のひらがなを、同じ読みの漢字から選んで答える（漢検の「同音・同訓異字」。同音異字は8級〜2級、同訓異字は6級〜2級で出題）
/// - wordReading: 熟語を見て読み方を答える（漢検の「読み」。熟語の読み。10級〜1級で出題）
/// - wordWriting: 読み方を見て正しい熟語を答える（漢検の「書き取り」。熟語の書き取り。10級〜1級で出題）
/// - koji: 故事成語・諺の空欄に入る漢字を答える（漢検の「故事・諺」。準1級・1級で出題）
/// - radicalName: 漢字の部首名（「きへん」「さんずい」など）を答える（漢検の「部首・部首名」。8級〜5級で出題）
/// - errorCorrection: 文の中の誤った漢字（同じ読みの別の字）を、正しい漢字に直す（漢検の「誤字訂正」。5級〜2級で出題）
/// - mixed: 問題ごとにその級で出題可能な形式からランダムに出題
enum PracticeMode {
  reading,
  writing,
  radical,
  compoundStructure,
  strokeCount,
  strokeOrder,
  okurigana,
  kanjiMaking,
  sanji,
  yoji,
  antonym,
  synonym,
  homophone,
  errorCorrection,
  radicalName,
  koji,
  wordReading,
  wordWriting,
  mixed,
}

/// 級ごとに実際の漢検で出題される形式に合わせた、選択可能な出題形式一覧
/// （mixedを除く）。10級は読み/書き取り/画数、9級から部首が加わり、
/// 8級以下では熟語の構成も加わる。画数は漢検で出題される10級〜5級のみ。
List<PracticeMode> availableModesForLevel(String level) {
  switch (level) {
    case 'LEVEL_10':
      return const [
        PracticeMode.reading,
        PracticeMode.writing,
        PracticeMode.wordReading,
        PracticeMode.wordWriting,
        PracticeMode.strokeCount,
        PracticeMode.strokeOrder,
      ];
    case 'LEVEL_9':
      return const [
        PracticeMode.reading,
        PracticeMode.writing,
        PracticeMode.wordReading,
        PracticeMode.wordWriting,
        PracticeMode.radical,
        PracticeMode.strokeCount,
        PracticeMode.strokeOrder,
      ];
    case 'LEVEL_8':
      return const [
        PracticeMode.reading,
        PracticeMode.writing,
        PracticeMode.wordReading,
        PracticeMode.wordWriting,
        PracticeMode.radical,
        PracticeMode.compoundStructure,
        PracticeMode.strokeCount,
        PracticeMode.strokeOrder,
        PracticeMode.okurigana,
        PracticeMode.antonym,
        PracticeMode.homophone,
        PracticeMode.radicalName,
      ];
    case 'LEVEL_7':
      return const [
        PracticeMode.reading,
        PracticeMode.writing,
        PracticeMode.wordReading,
        PracticeMode.wordWriting,
        PracticeMode.radical,
        PracticeMode.compoundStructure,
        PracticeMode.strokeCount,
        PracticeMode.strokeOrder,
        PracticeMode.okurigana,
        PracticeMode.antonym,
        PracticeMode.homophone,
        PracticeMode.kanjiMaking,
        PracticeMode.sanji,
        PracticeMode.radicalName,
      ];
    case 'LEVEL_6':
      return const [
        PracticeMode.reading,
        PracticeMode.writing,
        PracticeMode.wordReading,
        PracticeMode.wordWriting,
        PracticeMode.radical,
        PracticeMode.compoundStructure,
        PracticeMode.strokeCount,
        PracticeMode.strokeOrder,
        PracticeMode.okurigana,
        PracticeMode.antonym,
        PracticeMode.synonym,
        PracticeMode.homophone,
        PracticeMode.kanjiMaking,
        PracticeMode.sanji,
        PracticeMode.radicalName,
      ];
    case 'LEVEL_5':
      return const [
        PracticeMode.reading,
        PracticeMode.writing,
        PracticeMode.wordReading,
        PracticeMode.wordWriting,
        PracticeMode.radical,
        PracticeMode.compoundStructure,
        PracticeMode.strokeCount,
        PracticeMode.strokeOrder,
        PracticeMode.okurigana,
        PracticeMode.yoji,
        PracticeMode.antonym,
        PracticeMode.synonym,
        PracticeMode.homophone,
        PracticeMode.kanjiMaking,
        PracticeMode.errorCorrection,
        PracticeMode.radicalName,
      ];
    case 'LEVEL_4':
    case 'LEVEL_3':
    case 'LEVEL_2_PRE':
    case 'LEVEL_2':
      return const [
        PracticeMode.reading,
        PracticeMode.writing,
        PracticeMode.wordReading,
        PracticeMode.wordWriting,
        PracticeMode.radical,
        PracticeMode.compoundStructure,
        PracticeMode.okurigana,
        PracticeMode.yoji,
        PracticeMode.antonym,
        PracticeMode.synonym,
        PracticeMode.homophone,
        PracticeMode.kanjiMaking,
        PracticeMode.errorCorrection,
        PracticeMode.radicalName,
      ];
    default: // 準1級・1級（公式の出題: 読み・書取・故事諺・対義語類義語・同音同訓異字・誤字訂正・四字熟語）
      return const [
        PracticeMode.reading,
        PracticeMode.writing,
        PracticeMode.wordReading,
        PracticeMode.wordWriting,
        PracticeMode.radical,
        PracticeMode.compoundStructure,
        PracticeMode.yoji,
        PracticeMode.antonym,
        PracticeMode.synonym,
        PracticeMode.homophone,
        PracticeMode.errorCorrection,
        PracticeMode.koji,
      ];
  }
}

/// 選択中の演習モード（ホーム画面の演習開始ダイアログで選ぶ）
final practiceModeProvider = StateProvider<PracticeMode>((ref) => PracticeMode.mixed);

/// 実際に画面に表示する1問分のデータ。
/// 元のKanjiQuestion(source)から、演習モードに応じて
/// 「何を大きく表示するか」「選択肢に何を並べるか」を作り分ける。
class PracticeQuestion {
  final KanjiQuestion source;
  final PracticeMode actualMode; // mixed選択時に実際に割り当てられたモード
  final String prompt; // 大きく表示する文字（漢字 or 読み方）
  final String instruction; // 「この漢字の読み方は？」等の指示文
  final List<String> choices;
  final String correctAnswer;

  /// 筆順の問題で、赤く示す画（0始まり）。書き順の図は prompt の漢字のものを使う。筆順の問題以外は null。
  final int? highlightStroke;

  /// 答えたあとに出す、正解の語・意味などの1〜2行の説明。熟語系の出題は、土台の漢字（source）が
  /// 問題と関係ないので、source の読み・用例ではなく、この説明を出す。null なら出さない。
  final String? explanation;

  const PracticeQuestion({
    required this.source,
    required this.actualMode,
    required this.prompt,
    required this.instruction,
    required this.choices,
    required this.correctAnswer,
    this.highlightStroke,
    this.explanation,
  });
}

/// 漢字の問題から、読み・書き取りの練習問題を作る。模擬試験で、試験問題が足りない級（10級・準1級・1級など）や
/// Firestore が読めないときの補いにも使う。
List<PracticeQuestion> buildKanjiPracticeQuestions(
  List<KanjiQuestion> questions,
  PracticeMode mode,
  String level,
) =>
    _buildPracticeQuestions(questions, mode, level);

/// 級を「難しさの順位」にする（10級=10 … 2級=2、準2級=2.5、準1級=1.5、1級=1）。四字熟語を出す級の判定用。
/// 準1級・1級用の熟語などのデータは、2級以下の配当漢字でできたものを使う（その全部が出る）。
const Map<String, double> _levelRank = {
  'LEVEL_10': 10, 'LEVEL_9': 9, 'LEVEL_8': 8, 'LEVEL_7': 7, 'LEVEL_6': 6,
  'LEVEL_5': 5, 'LEVEL_4': 4, 'LEVEL_3': 3, 'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2,
  'LEVEL_1_PRE': 1.5, 'LEVEL_1': 1,
};

/// 指定の級の演習で出す四字熟語。語に含まれる字がすべて、その級以下の配当漢字にあるものだけ。
/// 四字熟語は5級〜2級で出題する（それ以外の級は空）。
List<YojiJukugo> yojiForLevel(String level) {
  final rank = _levelRank[level];
  if (rank == null || rank > 5) return const [];
  return [
    for (final y in kYojiJukugo)
      if ((_levelRank[y.level] ?? 0) >= rank) y,
  ];
}

/// 指定の級の演習で出す、同音・同訓異字の問題。文と選択肢の字がすべて、その級以下の配当漢字に
/// あるものだけ。同音異字は8級〜1級、同訓異字は6級〜1級で出題する（それ以外は空）。
List<HomophoneQuestion> homophonesForLevel(String level) {
  final rank = _levelRank[level];
  if (rank == null || rank > 8) return const [];
  final all = [
    for (final q in kHomophoneQuestions)
      if ((_levelRank[q.level] ?? 0) >= rank &&
          (rank <= 6 || q.kind == HomophoneKind.homophone))
        q,
  ];
  // 準1級・1級は、準2級以上の字を含む問題を出す（3級以下の字だけの問題は、足りないときだけ混ぜる）。
  if (rank < 2) {
    final upper = [for (final q in all) if ((_levelRank[q.level] ?? 0) < 3) q];
    if (upper.length >= 20) return upper;
  }
  return all;
}

/// 部首名の問題の選択肢（部首名4つ。正解を含む）。データに無い字は null。
/// 紛らわしい候補は、別の部首の名前から選ぶ。正解と前方一致する名前（き／きへん など、同じ部首の
/// 呼び方違い）は、どちらも正しく見えるので除く。
List<String>? radicalNameChoices(String kanji, Random random) {
  final info = KanjiRadicalData.get(kanji);
  if (info == null) return null;
  final answer = info.radicalName;
  // 同じ部首の呼び方（言 = ごんべん／げん など）は、正解と同じ部首を指すので候補にしない。
  final sameRadicalNames = <String>{
    for (final e in KanjiRadicalData.allEntries)
      if (e.value.radical == info.radical) e.value.radicalName,
  };
  final candidates = <String>{
    for (final e in KanjiRadicalData.allEntries)
      if (e.value.radical != info.radical &&
          !sameRadicalNames.contains(e.value.radicalName) &&
          !e.value.radicalName.startsWith(answer) &&
          !answer.startsWith(e.value.radicalName))
        e.value.radicalName,
  }.toList()
    ..shuffle(random);
  if (candidates.length < 3) return null;
  // 間違えやすいよう、正解と同じ種類の呼び名（〜へん・〜かんむり・〜づくり など）を優先して入れる。
  const kinds = ['へん', 'づくり', 'かんむり', 'あし', 'がまえ', 'かまえ', 'にょう', 'たれ'];
  final kind = kinds.where(answer.endsWith).firstOrNull;
  final similar = kind == null ? const <String>[] : [for (final c in candidates) if (c.endsWith(kind)) c];
  final rest = [for (final c in candidates) if (!similar.contains(c)) c];
  final picked = [...similar.take(2), ...rest].take(3).toList();
  return [answer, ...picked]..shuffle(random);
}

/// 指定の級の演習で出す、三字熟語。語に含まれる字がすべて、その級以下の配当漢字にあるものだけ。
/// 三字熟語は7級・6級で出題する（それ以外は空）。
List<SanjiJukugo> sanjiForLevel(String level) {
  final rank = _levelRank[level];
  if (rank == null || rank > 7 || rank < 6) return const [];
  return [
    for (final s in kSanjiJukugo)
      if ((_levelRank[s.level] ?? 0) >= rank) s,
  ];
}

/// 三字熟語の問題（『フ可能』の「フ」を漢字にする）。[index] 字目をカタカナにして、その漢字を選ばせる。
/// 入れると別の三字熟語（データにある語）になる字は、選択肢に入れない。作れなければ null。
({String prompt, String answer, List<String> choices})? sanjiBlank(
  SanjiJukugo s,
  int index,
  String level,
  Random random,
) {
  final answer = s.word[index];
  final choices = kanjiBlankChoices(
    answer,
    level,
    random,
    isUsable: (c) {
      if (s.word.contains(c)) return false;
      final candidate = s.word.replaceRange(index, index + 1, c);
      return !kSanjiJukugo.any((x) => x.word == candidate);
    },
  );
  if (choices == null) return null;
  return (
    prompt: s.word.replaceRange(index, index + 1, s.readings[index]),
    answer: answer,
    choices: choices,
  );
}

/// 指定の級の演習で出す、漢字作りの問題。使う字がすべて、その級以下の配当漢字にあるものだけ。
/// 漢字作りは7級〜2級で出題する（それ以外は空）。
List<KanjiMakingItem> kanjiMakingForLevel(String level) {
  final rank = _levelRank[level];
  if (rank == null || rank > 7 || rank < 2) return const []; // 準1級・1級には出さない
  return [
    for (final k in kKanjiMaking)
      if ((_levelRank[k.level] ?? 0) >= rank) k,
  ];
}

/// 漢字作りの選択肢の文字列（例: 「A件　B建　C検」）。
String kanjiMakingChoiceText(List<String> kanji) => [
      for (var i = 0; i < kanji.length; i++) '${'ABC'[i]}${kanji[i]}',
    ].join('　');

/// 漢字作りの正解を、問題の A・B・C に入れた形（例: 夜景・景品）。
String kanjiMakingCompleted(KanjiMakingItem k) {
  var s = k.prompt;
  for (var i = 0; i < k.answer.length; i++) {
    s = s.replaceAll('ABC'[i], k.answer[i]);
  }
  return s;
}

/// 対義語・類義語の答え合わせの説明（例: 勝利（しょうり）⇔ 敗北（はいぼく））。
String relationExplanation(WordRelation r, WordRelationKind kind) =>
    '${r.word}（${r.reading}）${kind == WordRelationKind.antonym ? '⇔' : '＝'}${r.partner}（${r.partnerReading}）';

/// 指定の級の演習で出す、送りがなの問題。その級以下の字の語だけ。送りがなは8級〜2級で出題する
/// （それ以外は空）。
List<OkuriganaItem> okuriganaForLevel(String level) {
  final rank = _levelRank[level];
  if (rank == null || rank > 8 || rank < 2) return const []; // 準1級・1級には出さない
  return [
    for (final o in kOkurigana)
      if ((_levelRank[o.level] ?? 0) >= rank) o,
  ];
}

/// 指定の級の演習で出す、誤字訂正の問題。同音・同訓異字の問題のうち、誤答が3つ以上あるもの
/// （誤答の1つを文に入れても、選択肢が3つ以上残る）。1字だけの答え（8級〜の同音異字）は、語として直す形ではないので除く。誤字訂正は5級〜2級で出題する（それ以外は空）。
List<HomophoneQuestion> errorCorrectionForLevel(String level) {
  final rank = _levelRank[level];
  if (rank == null || rank > 5) return const [];
  return [
    for (final q in homophonesForLevel(level))
      if (q.wrong.length >= 3 && q.answer.length >= 2) q,
  ];
}

/// 指定の級の演習で出す、対義語（または類義語）の組。2語に含まれる字がすべて、その級以下の
/// 配当漢字にあるものだけ。対義語は8級〜1級、類義語は6級〜1級で出題する（それ以外は空）。
List<WordRelation> wordRelationsForLevel(String level, WordRelationKind kind) {
  final rank = _levelRank[level];
  final minRank = kind == WordRelationKind.antonym ? 8 : 6;
  if (rank == null || rank > minRank) return const [];
  final all = [for (final r in kWordRelations) if (r.kind == kind && (_levelRank[r.level] ?? 0) >= rank) r];
  // 準1級・1級は、準2級以上の字を含む組を出す（3級以下の字だけの組は、足りないときだけ混ぜる）。
  if (rank < 2) {
    final upper = [for (final r in all) if ((_levelRank[r.level] ?? 0) < 3) r];
    if (upper.length >= 20) return upper;
  }
  return all;
}

/// 対義語・類義語の問題の選択肢（語4つ。正解を含む）。[askWord] が問いの語、[answer] が正解。
/// 紛らわしい候補は、同じ種類の他の組から、別の分野の語を選ぶ。問いの語・正解と
/// 何らかの対義語・類義語の関係がある語（全データで）は、候補から除く。足りなければ null。
List<String>? wordRelationChoices(
  WordRelation relation,
  bool reversed,
  String level,
  Random random,
) {
  final askWord = reversed ? relation.partner : relation.word;
  final answer = reversed ? relation.word : relation.partner;
  final related = <String>{askWord, answer};
  for (final r in kWordRelations) {
    if (r.word == askWord || r.partner == askWord || r.word == answer || r.partner == answer) {
      related..add(r.word)..add(r.partner);
    }
  }
  final candidates = <String>{
    for (final r in wordRelationsForLevel(level, relation.kind))
      if (r.group != relation.group) ...[r.word, r.partner],
  }..removeAll(related);
  if (candidates.length < 3) return null;
  final picked = candidates.toList()..shuffle(random);
  return [answer, ...picked.take(3)]..shuffle(random);
}

/// 指定の級の演習で出す故事・諺。語に含まれる字がすべて、その級以下の配当漢字にあるものだけ。
/// 故事・諺は準1級・1級で出題する（それ以外の級は空）。
List<KojiItem> kojiForLevel(String level) {
  final rank = _levelRank[level];
  if (rank == null || rank > 1.5) return const [];
  return [
    for (final k in kKoji)
      if ((_levelRank[k.level] ?? 0) >= rank) k,
  ];
}

final RegExp _kanjiChar = RegExp(r'[一-鿿]');

/// 熟語の用例（漢字ごとの用例のうち、漢字だけでできた2〜4字の語）と、その読み。
class JukugoItem {
  final String word;
  final String reading; // ひらがな
  /// 語に含まれる最も難しい字の級（例: 'LEVEL_5'）。この級以下の演習で出す。
  final String level;
  const JukugoItem(this.word, this.reading, this.level);
}

List<JukugoItem>? _jukugoCache;

List<JukugoItem> get allJukugo => _jukugoCache ??= _buildJukugo();

List<JukugoItem> _buildJukugo() {
  final rankOf = <String, double>{};
  for (final e in _levelRank.entries) {
    for (final c in LevelKanjiData.forLevel(e.key)) {
      rankOf[c] = e.value;
    }
  }
  final levelOfRank = {for (final e in _levelRank.entries) e.value: e.key};
  final exampleRe = RegExp(r'^(.+?)（(.+?)）$');
  final wordRe = RegExp(r'^[一-鿿]{2,4}$');
  final readingRe = RegExp(r'^[ぁ-ゖー]+$');
  final seen = <String>{};
  final out = <JukugoItem>[];
  for (final entry in KanjiInfoData.entries) {
    for (final ex in entry.value.examples) {
      final m = exampleRe.firstMatch(ex);
      if (m == null) continue;
      final word = m.group(1)!;
      final reading = m.group(2)!;
      if (!wordRe.hasMatch(word) || !readingRe.hasMatch(reading) || !seen.add(word)) continue;
      final ranks = [for (final c in word.split('')) rankOf[c]];
      if (ranks.any((r) => r == null)) continue;
      out.add(JukugoItem(word, reading, levelOfRank[ranks.whereType<double>().reduce(min)]!));
    }
  }
  // 準1級・1級の字を含む熟語（用例だけでは足りない分）。
  for (final e in kUpperJukugo.entries) {
    if (!seen.add(e.key)) continue;
    final ranks = [for (final c in e.key.split('')) rankOf[c]];
    if (ranks.any((r) => r == null)) continue;
    out.add(JukugoItem(e.key, e.value, levelOfRank[ranks.whereType<double>().reduce(min)]!));
  }
  return out;
}

/// 指定の級の演習で出す熟語（語に含まれる字がすべて、その級以下の配当漢字にあるものだけ）。
List<JukugoItem> jukugoForLevel(String level) {
  final rank = _levelRank[level];
  if (rank == null) return const [];
  return [
    for (final j in allJukugo)
      if ((_levelRank[j.level] ?? 0) >= rank) j,
  ];
}

/// 熟語の読みの選択肢（読み4つ。正解を含む）。紛らわしい読みは、同じ級の他の熟語の読みから、
/// 長さの近いものを選ぶ。作れなければ null。
List<String>? jukugoReadingChoices(JukugoItem item, List<JukugoItem> pool, Random random) {
  bool near(JukugoItem j) =>
      j.reading != item.reading && (j.reading.length - item.reading.length).abs() <= 1;
  // 間違えやすいよう、同じ字を含む熟語（同じ字の別の読み・似た読み）の読みを優先して入れる。
  final sharing = <String>{
    for (final j in pool)
      if (near(j) && j.word != item.word && j.word.split('').any(item.word.contains)) j.reading,
  }.toList()
    ..shuffle(random);
  final others = <String>{
    for (final j in pool)
      if (near(j) && !sharing.contains(j.reading)) j.reading,
  }.toList()
    ..shuffle(random);
  final picked = [...sharing.take(2), ...others].take(3).toList();
  if (picked.length < 3) return null;
  return [item.reading, ...picked]..shuffle(random);
}

/// 熟語の書き取りの選択肢（熟語4つ。正解を含む）。紛らわしい語は、正解と字を共有する同じ長さの語から選び、
/// 足りなければ同じ長さの語から選ぶ。正解と同じ読みの語（同音異義語）は、正解になりうるので入れない。
List<String>? jukugoWritingChoices(JukugoItem item, List<JukugoItem> pool, Random random) {
  final sameLength = [
    for (final j in pool)
      if (j.word != item.word && j.reading != item.reading && j.word.length == item.word.length) j.word,
  ];
  final sharing = [
    for (final w in sameLength)
      if (w.split('').any(item.word.contains)) w,
  ]..shuffle(random);
  final others = [
    for (final w in sameLength)
      if (!sharing.contains(w)) w,
  ]..shuffle(random);
  final picked = <String>{...sharing.take(3), ...others}.take(3).toList();
  if (picked.length < 3) return null;
  return [item.word, ...picked]..shuffle(random);
}

/// 故事・諺の空欄の選択肢（漢字4つ）。答えが難しい字（準1級・1級の字）のときは、同じ難しさの字から、
/// ふつうの字のときは、その級以下の配当漢字から、誤答を選ぶ。語に含まれる字は、選択肢に入れない。
List<String> kojiBlankChoices(String phrase, int index, String level, Random random) {
  final answer = phrase[index];
  final hardPool = <String>[
    ...LevelKanjiData.forLevel('LEVEL_1_PRE'),
    ...LevelKanjiData.forLevel('LEVEL_1'),
  ];
  if (hardPool.contains(answer)) {
    final candidates = [
      for (final c in hardPool)
        if (c != answer && !phrase.contains(c)) c,
    ]..shuffle(random);
    return [answer, ...candidates.take(3)]..shuffle(random);
  }
  return kanjiBlankChoices(answer, level, random, isUsable: (c) => !phrase.contains(c)) ?? [answer];
}

/// 四字熟語の空欄の選択肢（漢字4つ）。正解の字に、同じ読みの字（あれば最大2つ）と、
/// その級以下の配当漢字から選んだ字を足す。語の字のどれかを入れると別の語の字になる
/// （＝正解以外でも通る）字は、選択肢から除く。
List<String> yojiBlankChoices(String word, int index, String level, Random random) {
  final choices = kanjiBlankChoices(
    word[index],
    level,
    random,
    isUsable: (c) {
      if (word.contains(c)) return false;
      final candidate = word.replaceRange(index, index + 1, c);
      return !kYojiJukugo.any((y) => y.word == candidate);
    },
  );
  // 四字熟語の語数・字数なら、候補は十分にある（足りない場合は、あるだけで返す）。
  return choices ?? [word[index]];
}

/// 空欄に入る漢字の選択肢（漢字4つ。正解を含む）。正解の字に、同じ読みの字（あれば最大2つ）と、
/// その級以下の配当漢字から選んだ字を足す。[isUsable] が false の字（入れると別の語として成り立つ
/// 字など）は選択肢から除く。誤答が3つ作れなければ null。
List<String>? kanjiBlankChoices(
  String answer,
  String level,
  Random random, {
  required bool Function(String c) isUsable,
}) {
  final rank = _levelRank[level] ?? 10;
  final pool = <String>[
    for (final e in _levelRank.entries)
      // 誤答の字は、ふつうの字（2級以下）から選ぶ。準1級・1級の難しい字は混ぜない。
      if (e.value >= rank && e.value >= 2) ...LevelKanjiData.forLevel(e.key),
  ];
  bool valid(String c) => c != answer && isUsable(c);

  List<String> readingOf(String k) =>
      (KanjiInfoData.get(k)?.readings ?? const <String>[]).map(_stemReading).toList();
  final answerReadings = readingOf(answer).toSet();
  final homophones = <String>[
    for (final c in pool)
      if (valid(c) && readingOf(c).any(answerReadings.contains)) c,
  ]..shuffle(random);
  // 間違えやすいよう、正解と同じ部首の字（形が似た字）を優先して入れる。
  final answerRadical = KanjiRadicalData.get(answer)?.radical;
  final lookAlikes = answerRadical == null
      ? <String>[]
      : [
          for (final c in pool)
            if (valid(c) && !homophones.contains(c) && KanjiRadicalData.get(c)?.radical == answerRadical) c,
        ]
    ..shuffle(random);
  final others = [
    for (final c in pool)
      if (valid(c) && !homophones.contains(c) && !lookAlikes.contains(c)) c,
  ]..shuffle(random);
  final picked = [
    ...homophones.take(1),
    ...lookAlikes.take(2),
    ...homophones.skip(1).take(1),
    ...others,
  ].take(3).toList();
  if (picked.length < 3) return null;
  return [answer, ...picked]..shuffle(random);
}

/// 対義語・類義語の「集合−□散」の形の問題（漢検の例題と同じ）。
class WordRelationBlank {
  /// 問いの語（例: 集合）とその読み。
  final String askWord;
  final String askReading;

  /// 相手の語の1字を□にした形（例: □散）。
  final String partnerWithBlank;

  /// □に入る漢字（例: 解）と、その選択肢。
  final String answerChar;
  final List<String> choices;

  /// 相手の語（例: 解散）。
  final String partner;

  const WordRelationBlank({
    required this.askWord,
    required this.askReading,
    required this.partnerWithBlank,
    required this.answerChar,
    required this.choices,
    required this.partner,
  });
}

/// 対義語・類義語を、漢検の例題（「集合−□散」）と同じ形にする。相手の語が漢字2字のとき、そのうち
/// 1字を□にして、□に入る漢字を選ばせる。入れると別の対義語・類義語（データにある語）になる字は、
/// 選択肢に入れない。選択肢が作れなければ null（語を選ぶ形に回す）。
WordRelationBlank? wordRelationBlank(
  WordRelation relation,
  bool reversed,
  String level,
  Random random,
) {
  final askWord = reversed ? relation.partner : relation.word;
  final askReading = reversed ? relation.partnerReading : relation.reading;
  final partner = reversed ? relation.word : relation.partner;
  if (partner.runes.length != 2) return null;
  final index = random.nextInt(2);
  final knownWords = <String>{
    for (final r in kWordRelations) ...[r.word, r.partner],
  };
  final choices = kanjiBlankChoices(
    partner[index],
    level,
    random,
    isUsable: (c) {
      final candidate = partner.replaceRange(index, index + 1, c);
      return candidate != askWord && !knownWords.contains(candidate);
    },
  );
  if (choices == null) return null;
  return WordRelationBlank(
    askWord: askWord,
    askReading: askReading,
    partnerWithBlank: partner.replaceRange(index, index + 1, '□'),
    answerChar: partner[index],
    choices: choices,
    partner: partner,
  );
}

/// 読み（カタカナの音読み・括弧付きの訓読み）から、比べるための形（ひらがな・送り仮名なし）にする。
String _stemReading(String r) => String.fromCharCodes([
      for (final c in r.split('（').first.runes)
        c >= 0x30A1 && c <= 0x30F6 ? c - 0x60 : c,
    ]);

/// 筆順の問題（「赤い画は何画目？」）の選択肢（画の番号。1始まり）。正解の前後の番号を優先して
/// 4つ選び、小さい順に並べる。全部で4画未満の字では、4つ作れないので null（画数の問題に回す）。
List<int>? strokeOrderChoices(int answer, int total, Random random) {
  if (total < 4 || answer < 1 || answer > total) return null;
  final near = <int>[
    for (final d in [1, -1, 2, -2, 3, -3])
      if (answer + d >= 1 && answer + d <= total) answer + d,
  ];
  final rest = [
    for (var n = 1; n <= total; n++)
      if (n != answer && !near.contains(n)) n,
  ]..shuffle(random);
  return [answer, ...[...near, ...rest].take(3)]..sort();
}

/// 画数の問題の選択肢（画数）。正解の前後の画数から、紛らわしい候補を3つ足して4つにする（1画以上）。
/// 小さい順に並べる。
List<int> strokeCountChoices(int count, [Random? random]) {
  // 正解を含む連続した4つの画数。正解の位置が毎回同じにならないよう、窓の位置を選ぶ。
  final starts = [
    for (var s = count - 3; s <= count; s++)
      if (s >= 1) s,
  ];
  final start = starts[(random ?? Random()).nextInt(starts.length)];
  return [for (var i = 0; i < 4; i++) start + i];
}

/// 書き取り（読み → 漢字）の選択肢。元の選択肢のうち2つを、正解と同じ部首の字（形が似た字）に
/// 入れ替えて、間違えやすくする。入れ替える字は、問題の読みのどれとも同じ読みを持たない字だけ
/// （同じ読みの字は、正解になりうるので入れない）。作れないときは、元の選択肢をそのまま混ぜる。
List<String> writingChoicesWithLookAlikes(KanjiQuestion q, String level, Random random) {
  final base = List<String>.from(q.choices);
  final answer = q.correctAnswer;
  bool single(String s) => s.runes.length == 1;
  if (!single(answer) || !base.every(single) || base.length < 3) return base..shuffle(random);
  final radical = KanjiRadicalData.get(answer)?.radical;
  if (radical == null) return base..shuffle(random);
  final rank = _levelRank[level] ?? 10;
  final questionReadings = <String>{
    for (final r in q.allReadings) _stemReading(r.reading),
  };
  List<String> readingOf(String k) =>
      (KanjiInfoData.get(k)?.readings ?? const <String>[]).map(_stemReading).toList();
  final candidates = <String>[
    for (final e in _levelRank.entries)
      if (e.value >= rank && e.value >= 2)
        for (final c in LevelKanjiData.forLevel(e.key))
          if (c != answer &&
              !base.contains(c) &&
              KanjiRadicalData.get(c)?.radical == radical &&
              !readingOf(c).any(questionReadings.contains))
            c,
  ]..shuffle(random);
  final distractors = base.where((c) => c != answer).toList()..shuffle(random);
  final swap = candidates.take(2).length;
  final kept = distractors.skip(swap).toList();
  return [answer, ...candidates.take(2), ...kept]..shuffle(random);
}

/// KanjiQuestionの一覧から、指定モードに沿ったPracticeQuestionを組み立てる。
/// readingモードの選択肢（読み方）は、同じ一覧内の他の問題のreadingから
/// ランダムに抽出して作る（Firestore側のchoicesは漢字の選択肢のため使えない）。
/// radical/compoundStructureも同様に、他の問題や級内のデータから選択肢を組み立てる。
List<PracticeQuestion> _buildPracticeQuestions(
  List<KanjiQuestion> questions,
  PracticeMode mode,
  String level, {
  List<KanjiQuestion>? distractorPool,
}) {
  final random = Random();
  // 選択肢の紛らわしい候補は distractorPool（無ければ questions）から作る。
  final pool = distractorPool ?? questions;
  final allReadings = pool
      .expand((q) => q.allReadings)
      .map((r) => r.reading)
      .where((r) => r.isNotEmpty)
      .toSet()
      .toList();
  final radicalsInSet = pool
      .map((q) => KanjiRadicalData.get(q.kanji)?.radical)
      .whereType<String>()
      .toSet()
      .toList();
  final compoundPool = CompoundStructureData.forLevel(level);
  final singleModes = availableModesForLevel(level);

  return questions.map((question) {
    var actualMode = mode;
    if (mode == PracticeMode.mixed) {
      actualMode = singleModes[random.nextInt(singleModes.length)];
    }

    // 読み方データが無い問題はreading出題ができないため書き取りにフォールバック
    if (actualMode == PracticeMode.reading &&
        (question.reading == null || question.reading!.isEmpty)) {
      actualMode = PracticeMode.writing;
    }

    if (actualMode == PracticeMode.reading) {
      // 複数の読みを持つ漢字は、出題のたびにどれか1つを正解として選ぶ。
      final picked = question.allReadings[random.nextInt(question.allReadings.length)];
      final correctReading = picked.reading;
      // 同じ漢字の他の読みは紛らわしい不正解になるため選択肢から除く。
      final ownReadings = question.allReadings.map((r) => r.reading).toSet();
      final distractors = allReadings.where((r) => !ownReadings.contains(r)).toList()
        ..shuffle(random);
      final choices = [correctReading, ...distractors.take(3)]..shuffle(random);

      return PracticeQuestion(
        // 解説（読み方・用例）が出題した読みと一致するよう差し替える。
        source: question.copyWith(reading: picked.reading, example: picked.example),
        actualMode: actualMode,
        prompt: question.kanji,
        instruction: 'この漢字の読み方はどれ？',
        choices: choices,
        correctAnswer: correctReading,
      );
    }

    if (actualMode == PracticeMode.radical) {
      final info = KanjiRadicalData.get(question.kanji);
      final radicalPool = radicalsInSet.length >= 4 ? radicalsInSet : KanjiRadicalData.allRadicals;
      if (info == null || radicalPool.length < 4) {
        actualMode = PracticeMode.writing;
      } else {
        final distractors = radicalPool.where((r) => r != info.radical).toList()
          ..shuffle(random);
        final choices = [info.radical, ...distractors.take(3)]..shuffle(random);

        return PracticeQuestion(
          source: question,
          actualMode: actualMode,
          prompt: question.kanji,
          instruction: 'この漢字の部首はどれ？',
          choices: choices,
          correctAnswer: info.radical,
        );
      }
    }

    if (actualMode == PracticeMode.strokeOrder) {
      final data = StrokeOrderSampleData.getStrokeOrder(question.kanji);
      final answerIndex = data == null ? 0 : random.nextInt(data.strokeCount);
      final numbers =
          data == null ? null : strokeOrderChoices(answerIndex + 1, data.strokeCount, random);
      if (numbers == null) {
        // 書き順のデータが無い字、4画未満の字は、画数の問題に回す。
        actualMode = PracticeMode.strokeCount;
      } else {
        return PracticeQuestion(
          source: question,
          actualMode: actualMode,
          prompt: question.kanji,
          instruction: '赤い画は、何画目？',
          choices: [for (final n in numbers) '$n画目'],
          correctAnswer: '${answerIndex + 1}画目',
          highlightStroke: answerIndex,
        );
      }
    }

    if (actualMode == PracticeMode.strokeCount) {
      final count = kanjiStrokeCount(question.kanji);
      if (count == null) {
        actualMode = PracticeMode.writing;
      } else {
        final counts = strokeCountChoices(count, random);
        return PracticeQuestion(
          source: question,
          actualMode: actualMode,
          prompt: question.kanji,
          instruction: 'この漢字の画数はどれ？',
          choices: [for (final c in counts) '$c画'],
          correctAnswer: '$count画',
        );
      }
    }

    if (actualMode == PracticeMode.yoji) {
      final yojiPool = yojiForLevel(level);
      if (yojiPool.isEmpty) {
        actualMode = PracticeMode.writing;
      } else {
        final yoji = yojiPool[random.nextInt(yojiPool.length)];
        final index = random.nextInt(4);
        return PracticeQuestion(
          source: question,
          actualMode: actualMode,
          prompt: yoji.word.replaceRange(index, index + 1, '□'),
          instruction: '${yoji.meaning}（${yoji.reading}）\n□に入る漢字はどれ？',
          choices: yojiBlankChoices(yoji.word, index, level, random),
          correctAnswer: yoji.word[index],
          explanation: '正解: ${yoji.word}（${yoji.reading}）',
        );
      }
    }

    if (actualMode == PracticeMode.wordReading || actualMode == PracticeMode.wordWriting) {
      final pool = jukugoForLevel(level);
      if (pool.length >= 20) {
        final item = pool[random.nextInt(pool.length)];
        final reading = actualMode == PracticeMode.wordReading;
        final choices = reading
            ? jukugoReadingChoices(item, pool, random)
            : jukugoWritingChoices(item, pool, random);
        if (choices != null) {
          return PracticeQuestion(
            source: question,
            actualMode: actualMode,
            prompt: reading ? item.word : item.reading,
            instruction: reading ? 'この熟語の読み方はどれ？' : 'この読み方の熟語はどれ？',
            choices: choices,
            correctAnswer: reading ? item.reading : item.word,
            explanation: '${item.word}（${item.reading}）',
          );
        }
      }
      actualMode = PracticeMode.writing;
    }

    if (actualMode == PracticeMode.koji) {
      final kojiPool = kojiForLevel(level);
      if (kojiPool.isEmpty) {
        actualMode = PracticeMode.writing;
      } else {
        final koji = kojiPool[random.nextInt(kojiPool.length)];
        final positions = [
          for (var i = 0; i < koji.phrase.length; i++)
            if (_kanjiChar.hasMatch(koji.phrase[i])) i,
        ];
        final index = positions[random.nextInt(positions.length)];
        return PracticeQuestion(
          source: question,
          actualMode: actualMode,
          prompt: koji.phrase.replaceRange(index, index + 1, '□'),
          instruction: '${koji.meaning}（${koji.reading}）\n□に入る漢字はどれ？',
          choices: kojiBlankChoices(koji.phrase, index, level, random),
          correctAnswer: koji.phrase[index],
          explanation: '正解: ${koji.phrase}（${koji.reading}）',
        );
      }
    }

    if (actualMode == PracticeMode.radicalName) {
      final choices = radicalNameChoices(question.kanji, random);
      if (choices == null) {
        actualMode = PracticeMode.writing;
      } else {
        return PracticeQuestion(
          source: question,
          actualMode: actualMode,
          prompt: question.kanji,
          instruction: 'この漢字の部首名はどれ？',
          choices: choices,
          correctAnswer: KanjiRadicalData.get(question.kanji)!.radicalName,
        );
      }
    }

    if (actualMode == PracticeMode.sanji) {
      final pool = sanjiForLevel(level);
      if (pool.isEmpty) {
        actualMode = PracticeMode.writing;
      } else {
        final s = pool[random.nextInt(pool.length)];
        final blank = sanjiBlank(s, random.nextInt(3), level, random);
        if (blank != null) {
          return PracticeQuestion(
            source: question,
            actualMode: actualMode,
            prompt: blank.prompt,
            instruction: '「${blank.prompt}」のカタカナを、漢字に直すと？',
            choices: blank.choices,
            correctAnswer: blank.answer,
            explanation: '正解: ${s.word}',
          );
        }
        actualMode = PracticeMode.writing;
      }
    }

    if (actualMode == PracticeMode.kanjiMaking) {
      final pool = kanjiMakingForLevel(level);
      if (pool.isEmpty) {
        actualMode = PracticeMode.writing;
      } else {
        final k = pool[random.nextInt(pool.length)];
        return PracticeQuestion(
          source: question,
          actualMode: actualMode,
          prompt: k.prompt,
          instruction: k.instruction,
          choices: [
            kanjiMakingChoiceText(k.answer),
            for (final w in k.wrong) kanjiMakingChoiceText(w),
          ]..shuffle(random),
          correctAnswer: kanjiMakingChoiceText(k.answer),
          explanation: '正解: ${kanjiMakingCompleted(k)}',
        );
      }
    }

    if (actualMode == PracticeMode.okurigana) {
      final pool = okuriganaForLevel(level);
      if (pool.isEmpty) {
        actualMode = PracticeMode.writing;
      } else {
        final o = pool[random.nextInt(pool.length)];
        return PracticeQuestion(
          source: question,
          actualMode: actualMode,
          prompt: o.reading,
          instruction: '「${o.reading}」を、漢字と送りがなで正しく書くと？',
          choices: [o.word, ...o.wrong]..shuffle(random),
          correctAnswer: o.word,
          explanation: '正解: ${o.word}（${o.reading}）',
        );
      }
    }

    if (actualMode == PracticeMode.errorCorrection) {
      final pool = errorCorrectionForLevel(level);
      if (pool.isEmpty) {
        actualMode = PracticeMode.writing;
      } else {
        final h = pool[random.nextInt(pool.length)];
        // 文には、正解ではない同じ読みの語を1つ入れる（＝誤字）。選択肢は、正解と、残りの誤答。
        final shown = h.wrong[random.nextInt(h.wrong.length)];
        final others = h.wrong.where((w) => w != shown).toList()..shuffle(random);
        return PracticeQuestion(
          source: question,
          actualMode: actualMode,
          prompt: h.sentence.replaceFirst('【${h.reading}】', '【$shown】'),
          instruction: '【 】の漢字は誤りです。正しい漢字は？',
          choices: [h.answer, ...others.take(3)]..shuffle(random),
          correctAnswer: h.answer,
          explanation: '正しい文: ${h.sentence.replaceFirst('【${h.reading}】', '【${h.answer}】')}',
        );
      }
    }

    if (actualMode == PracticeMode.homophone) {
      final pool = homophonesForLevel(level);
      if (pool.isEmpty) {
        actualMode = PracticeMode.writing;
      } else {
        final h = pool[random.nextInt(pool.length)];
        final choices = [h.answer, ...(List<String>.from(h.wrong)..shuffle(random)).take(3)]
          ..shuffle(random);
        return PracticeQuestion(
          source: question,
          actualMode: actualMode,
          prompt: h.sentence,
          instruction: h.kind == HomophoneKind.homophone
              ? '【 】のひらがなを漢字で書くと？'
              : '【 】のひらがなを、漢字と送りがなで書くと？',
          choices: choices,
          correctAnswer: h.answer,
          explanation: '正解: ${h.sentence.replaceFirst('【${h.reading}】', '【${h.answer}】')}',
        );
      }
    }

    if (actualMode == PracticeMode.antonym || actualMode == PracticeMode.synonym) {
      final kind = actualMode == PracticeMode.antonym
          ? WordRelationKind.antonym
          : WordRelationKind.synonym;
      final relations = wordRelationsForLevel(level, kind);
      if (relations.isNotEmpty) {
        final relation = relations[random.nextInt(relations.length)];
        final reversed = random.nextBool();
        final blank = wordRelationBlank(relation, reversed, level, random);
        if (blank != null) {
          return PracticeQuestion(
            source: question,
            actualMode: actualMode,
            prompt: '${blank.askWord}―${blank.partnerWithBlank}',
            instruction: kind == WordRelationKind.antonym
                ? '「${blank.askWord}（${blank.askReading}）」の対義語になるように、□に入る漢字はどれ？'
                : '「${blank.askWord}（${blank.askReading}）」の類義語になるように、□に入る漢字はどれ？',
            choices: blank.choices,
            correctAnswer: blank.answerChar,
            explanation: relationExplanation(relation, kind),
          );
        }
        final choices = wordRelationChoices(relation, reversed, level, random);
        if (choices != null) {
          final askWord = reversed ? relation.partner : relation.word;
          final askReading = reversed ? relation.partnerReading : relation.reading;
          final answer = reversed ? relation.word : relation.partner;
          return PracticeQuestion(
            source: question,
            actualMode: actualMode,
            prompt: askWord,
            instruction: kind == WordRelationKind.antonym
                ? '「$askWord（$askReading）」の対義語（反対の意味の言葉）はどれ？'
                : '「$askWord（$askReading）」の類義語（ほぼ同じ意味の言葉）はどれ？',
            choices: choices,
            correctAnswer: answer,
            explanation: relationExplanation(relation, kind),
          );
        }
      }
      actualMode = PracticeMode.writing;
    }

    if (actualMode == PracticeMode.compoundStructure) {
      if (compoundPool.isEmpty) {
        actualMode = PracticeMode.writing;
      } else {
        final compound = compoundPool[random.nextInt(compoundPool.length)];
        final choices = compoundStructureLabels.values.toList()..shuffle(random);

        return PracticeQuestion(
          source: question,
          actualMode: actualMode,
          prompt: '${compound.jukugo}（${compound.reading}）',
          instruction: 'この熟語の構成として正しいものはどれ？',
          choices: choices,
          correctAnswer: compound.correctLabel,
          explanation: '${compound.jukugo}は「${compound.correctLabel}」',
        );
      }
    }

    // 書き取り: 読み方を見て正しい漢字を選ぶ
    final prompt = (question.reading != null && question.reading!.isNotEmpty)
        ? question.reading!
        : question.kanji;
    return PracticeQuestion(
      source: question,
      actualMode: PracticeMode.writing,
      prompt: prompt,
      instruction: 'この読み方の漢字はどれ？',
      // Firestore上のchoicesは正解位置が問題ごとに固定されているため、
      // 同じ問題を再度出題した際に「位置で覚えてしまう」ことがないよう
      // 表示のたびにシャッフルする。
      choices: writingChoicesWithLookAlikes(question, level, random),
      correctAnswer: question.correctAnswer,
    );
  }).toList();
}

/// 間違いノートの「解き直す」用。非 null のあいだ、演習の出題はこの問題だけになる。
/// 通常の演習を始めるとき・解き直しから戻るときに null へ戻す。
final practiceRetryQuestionsProvider =
    StateProvider<List<PracticeQuestion>?>((ref) => null);

/// 間違いノートの1問 [target] を、既存の演習画面で出題できる形にする。
/// 選択肢の候補は [pool]（同じ級の問題）から作る。出題形式は読み取り→書き取りの順で選ぶ。
List<PracticeQuestion> buildRetryPracticeQuestions(
  KanjiQuestion target,
  List<KanjiQuestion> pool,
  String level,
) {
  final hasReading = target.reading != null && target.reading!.isNotEmpty;
  return _buildPracticeQuestions(
    [target],
    hasReading ? PracticeMode.reading : PracticeMode.writing,
    level,
    distractorPool: [target, ...pool.where((q) => q.id != target.id)],
  );
}

/// ながら学習（自動で進む読み上げ学習）の1回の問題数。子ども向けに短く区切る。
const int nagaraSessionSize = 10;

/// ながら学習用の問題を作る。選択式の「読み」「書き取り」だけ（手書き・部首・熟語の構成は含めない）。
/// 読みと書き取りを半々にまぜる。
List<PracticeQuestion> buildNagaraPracticeQuestions(
  List<KanjiQuestion> all,
  String level, {
  int size = nagaraSessionSize,
}) {
  final choice = all.where((q) => q.questionType == QuestionType.multipleChoice).toList();
  final levelKanji = LevelKanjiData.forLevel(level).toSet();
  final inLevel = levelKanji.isEmpty ? choice : choice.where((q) => levelKanji.contains(q.kanji)).toList();
  inLevel.shuffle();
  final selected = inLevel.take(size).toList();
  final half = (selected.length + 1) ~/ 2;
  final built = [
    ..._buildPracticeQuestions(selected.take(half).toList(), PracticeMode.reading, level, distractorPool: choice),
    ..._buildPracticeQuestions(selected.skip(half).toList(), PracticeMode.writing, level, distractorPool: choice),
  ]..shuffle();
  return built;
}

/// ながら学習の問題セット（その級の問題から。「覚えた」・マスター済みは除く）。
final nagaraQuestionsProvider =
    FutureProvider.autoDispose.family<List<PracticeQuestion>, String>((ref, level) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final uid = ref.watch(currentUserIdProvider);
  final user = await ref.watch(currentUserProvider.future);
  final all = await firestoreService.getQuestionsByLevel(
    level,
    limit: 100,
    uid: uid,
    profileId: user?.profileId ?? 'default',
    masteryThreshold: user?.masteryThreshold ?? 3,
  );
  return buildNagaraPracticeQuestions(all, level);
});

// 現在の問題セット（その級の問題からランダムに10問だけ出題する。
// 「覚えた」チェック済み・連続正解でマスター済みの問題は除外される）
final practiceQuestionsProvider =
    FutureProvider.family<List<PracticeQuestion>, String>((ref, level) async {
  final retry = ref.watch(practiceRetryQuestionsProvider);
  if (retry != null) return retry;
  final firestoreService = ref.watch(firestoreServiceProvider);
  final uid = ref.watch(currentUserIdProvider);
  final user = await ref.watch(currentUserProvider.future);
  final mode = ref.watch(practiceModeProvider);
  // その級で新しく習う漢字（公式級別漢字表の配当漢字）の問題だけに絞る。
  // 下の級の漢字が混ざらないようにするため。配当表が無い級は絞り込まない。
  final levelKanji = LevelKanjiData.forLevel(level);
  final List<KanjiQuestion> all;
  if (levelKanji.length > 100) {
    // limit(100) だとID順の先頭100字しか出ないため、級内の全字から
    // ランダムに選んだ字をID指定で取得する（読み取り量は数十件）。
    all = await firestoreService.getQuestionsByLevelSampled(
      level,
      levelKanji,
      need: practiceSessionSize,
      uid: uid,
      profileId: user?.profileId ?? 'default',
      masteryThreshold: user?.masteryThreshold ?? 3,
    );
  } else {
    all = await firestoreService.getQuestionsByLevel(
      level,
      limit: 100,
      uid: uid,
      profileId: user?.profileId ?? 'default',
      masteryThreshold: user?.masteryThreshold ?? 3,
    );
  }
  final levelSet = levelKanji.toSet();
  final inLevel = levelSet.isEmpty
      ? all
      : all.where((q) => levelSet.contains(q.kanji)).toList();
  inLevel.shuffle();
  final selected = inLevel.take(practiceSessionSize).toList();
  return _buildPracticeQuestions(selected, mode, level);
});

// 現在解いている問題インデックス
final currentQuestionIndexProvider = StateProvider<int>((ref) => 0);

// 正解数（セッション内）
final correctCountProvider = StateProvider<int>((ref) => 0);

// 回答済み問題数（セッション内）
final answeredCountProvider = StateProvider<int>((ref) => 0);

// 現在のコンボ数
final comboCountProvider = StateProvider<int>((ref) => 0);

// Aha Moment到達フラグ（初回3問正解）
final ahaMomentReachedProvider = StateProvider<bool>((ref) => false);

/// 答えた問題を、間違いノート・今日の復習（問題IDで漢字の問題を読み直す仕組み）に記録する出題形式か。
/// 熟語系の出題（四字熟語・故事・諺・対義語など）は、内部では適当な漢字の問題を土台にして作るので、
/// 土台の漢字を記録すると、間違いノートに関係のない漢字が出る。そのため記録しない
/// （間違えた問題そのものは、間隔反復の復習に、問題文と選択肢ごと残る）。
bool practiceModeRecordsKanjiHistory(PracticeMode mode) {
  switch (mode) {
    case PracticeMode.reading:
    case PracticeMode.writing:
    case PracticeMode.radical:
    case PracticeMode.radicalName:
    case PracticeMode.strokeCount:
    case PracticeMode.strokeOrder:
    case PracticeMode.okurigana:
      return true;
    default:
      return false;
  }
}

/// 熟語系の問題の、内容から決まる安定したID（間違いノート・復習の記録に使う）。
String contentIdOf(PracticeQuestion q) =>
    contentQuestionId(q.actualMode.name, q.prompt, q.correctAnswer);

/// 熟語系の問題の控え（間違いノートの表示・解き直し用）。
ContentMistakeSnapshot contentSnapshotOf(PracticeQuestion q, String level) => ContentMistakeSnapshot(
      id: contentIdOf(q),
      mode: q.actualMode.name,
      level: level,
      prompt: q.prompt,
      instruction: q.instruction,
      choices: q.choices,
      correctAnswer: q.correctAnswer,
      explanation: q.explanation,
    );

/// 控えから、解き直し用の問題を作る。土台の漢字は持たないので、IDを控えのIDにした仮の問題を入れる
/// （答えを記録する側は、IDが [contentQuestionIdPrefix] で始まる問題を、漢字の問題としては数えない）。
PracticeQuestion practiceQuestionFromSnapshot(ContentMistakeSnapshot s, Random random) {
  final mode = PracticeMode.values.firstWhere((m) => m.name == s.mode, orElse: () => PracticeMode.writing);
  return PracticeQuestion(
    source: KanjiQuestion(
      id: s.id,
      level: s.level,
      kanji: '',
      questionType: QuestionType.multipleChoice,
      choices: s.choices,
      correctAnswer: s.correctAnswer,
      version: 1,
    ),
    actualMode: mode,
    prompt: s.prompt,
    instruction: s.instruction,
    choices: List<String>.from(s.choices)..shuffle(random),
    correctAnswer: s.correctAnswer,
    explanation: s.explanation,
  );
}

class PracticeViewModel extends StateNotifier<PracticeState> {
  final Ref ref;

  PracticeViewModel(this.ref)
      : super(const PracticeState(
          isLoading: false,
          currentQuestion: null,
          lastAnswerIsCorrect: null,
          isAnswering: false,
        ));

  Future<void> answerQuestion(bool isCorrect) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    state = state.copyWith(isAnswering: true);

    try {
      final level = ref.read(currentLevelProvider);
      final questions = ref.read(practiceQuestionsProvider(level)).valueOrNull;
      final index = ref.read(currentQuestionIndexProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final user = await ref.read(currentUserProvider.future);

      final PracticeQuestion? question =
          (questions != null && index < questions.length) ? questions[index] : null;

      if (question != null) {
        // 間違いノートの解き直しで開いた熟語系の問題は、土台の漢字の問題ではない（仮のIDを持つ）ので、
        // 漢字の問題としての記録（答ログ・推しの成長・コイン）は付けない。
        final isRetrySource = question.source.id.startsWith(contentQuestionIdPrefix);
        // 熟語系の出題は、内容から決まるIDで、履歴・間隔反復に記録する（土台の漢字では記録しない）。
        final isContent = !practiceModeRecordsKanjiHistory(question.actualMode);
        final recordId = isContent ? contentIdOf(question) : question.source.id;
        // 答ログを保存
        final log = UserAnswerLog(
          id: '',
          uid: uid,
          profileId: user?.profileId ?? 'default',
          questionId: question.source.id,
          isCorrect: isCorrect,
          mode: AnswerMode.normal,
          answeredAt: DateTime.now(),
          level: level,
        );
        // 通信がないと Firestore の書き込みは完了しない。待つと機内モードで答えが進まなくなるので、
        // 待たずに書く(オフラインの間は端末内に溜まり、通信が戻ったら送られる)。
        if (!isRetrySource) {
          unawaited(firestoreService.addAnswerLog(log).catchError((_) {}));
        }

        // 推しの成長（網羅率）に使う、解いた問題IDの端末内記録。
        // 失敗しても学習フローは止めない。
        if (!isRetrySource) {
          try {
            await OshiProgressStore.markAnswered(
              profileId: user?.profileId ?? 'default',
              level: level,
              questionId: question.source.id,
            );
          } catch (_) {}
        }

        // 試験に向けて（10分プラン・書き出し）用の端末内の解答履歴。失敗しても止めない。
        // 今日の復習の予定にも同じ時刻で反映する（履歴より先に。履歴更新で復習の件数が作り直されるため）。
        final answeredAt = DateTime.now();
        if (!isContent) {
          await recordKankenReviewResult(question.source.id,
              correct: isCorrect, at: answeredAt);
        } else if (!isCorrect) {
          // 間違いノートで見せて解き直せるよう、問題の内容を控えておく。
          await ContentMistakeStore.save(contentSnapshotOf(question, level));
        }
        try {
          await ref.read(historyProvider.notifier).recordAnswer(
                questionId: recordId,
                level: level,
                correct: isCorrect,
                at: answeredAt,
              );
        } catch (_) {}

        // 学習コイン：初めて解く問題で付与（同じ問題は二度付与されない）。
        // コインは付加機能なので、未設定・失敗しても学習フローは止めない。
        if (!isRetrySource) {
          try {
            unawaited(ref
                .read(coinProvider.notifier)
                .grant(CoinEvent.newQuestion(question.source.id))
                .catchError((_) => null));
          } catch (_) {}
        }

        // 状態を更新
        if (isCorrect) {
          ref.read(correctCountProvider.notifier).state++;
          ref.read(comboCountProvider.notifier).state++;
        } else {
          ref.read(comboCountProvider.notifier).state = 0;
          // 誤答時のみ苦手漢字リストを再分析（次の問題表示をブロックしないよう
          // 完了を待たずバックグラウンドで実行）。
          ref
              .read(aiWeakAnalysisServiceProvider)
              .analyzeWeakKanjis(uid, profileId: user?.profileId ?? 'default')
              .catchError((_) {});

          // 不正解だった問題を間隔反復（スペースドリピティション）の
          // 復習リストに追加する（完了を待たずバックグラウンドで実行）。
          addToSpacedRepetitionWithRef(
            ref,
            questionId: recordId,
            kanji: question.source.kanji,
            category: question.actualMode.toString().split('.').last,
            question: question.instruction,
            options: question.choices,
            correctAnswer: question.correctAnswer,
          ).catchError((_) {});
        }

        ref.read(answeredCountProvider.notifier).state++;

        // 日次問題数の学習目標を1問分進める（完了を待たずバックグラウンドで実行）
        incrementDailyQuestionGoalFromRef(ref).catchError((_) {});

        // 級ごとの正答率集計を更新したので再取得させる
        // （次の級までのカウントダウン・クリア判定に使う）
        ref.invalidate(levelProgressProvider);
        ref.invalidate(correctQuestionIdsProvider);

        // 演習で1問以上回答した = 「今日学習した」とみなしストリークを更新
        // （完了を待たずバックグラウンドで実行）。
        recordStudyActivityWithRef(ref).catchError((_) {});

        // Aha Moment判定：初回3問正解
        final correctCount = ref.read(correctCountProvider);
        if (correctCount >= 3 && !ref.read(ahaMomentReachedProvider)) {
          ref.read(ahaMomentReachedProvider.notifier).state = true;
          // Analytics event: aha_moment_reached
        }

        state = state.copyWith(
          lastAnswerIsCorrect: isCorrect,
          isAnswering: false,
        );

        // 次の問題へ遷移（自動は呼ばない、UIが制御）
      }
    } catch (e) {
      state = state.copyWith(isAnswering: false);
      rethrow;
    }
  }

  void moveToNextQuestion() {
    final currentIndex = ref.read(currentQuestionIndexProvider);
    ref.read(currentQuestionIndexProvider.notifier).state = currentIndex + 1;
    state = state.copyWith(lastAnswerIsCorrect: null);
  }

  void reset() {
    ref.read(currentQuestionIndexProvider.notifier).state = 0;
    ref.read(correctCountProvider.notifier).state = 0;
    ref.read(answeredCountProvider.notifier).state = 0;
    ref.read(comboCountProvider.notifier).state = 0;
    ref.read(ahaMomentReachedProvider.notifier).state = false;
    // 次の練習の終了画面に、そのセッションの分だけコイン内訳が出るようにする。
    try {
      ref.read(coinProvider.notifier).takeRecent();
    } catch (_) {}
    state = const PracticeState(
      isLoading: false,
      currentQuestion: null,
      lastAnswerIsCorrect: null,
      isAnswering: false,
    );
  }
}

class PracticeState {
  final bool isLoading;
  final PracticeQuestion? currentQuestion;
  final bool? lastAnswerIsCorrect;
  final bool isAnswering;

  const PracticeState({
    required this.isLoading,
    required this.currentQuestion,
    required this.lastAnswerIsCorrect,
    required this.isAnswering,
  });

  PracticeState copyWith({
    bool? isLoading,
    PracticeQuestion? currentQuestion,
    bool? lastAnswerIsCorrect,
    bool? isAnswering,
  }) {
    return PracticeState(
      isLoading: isLoading ?? this.isLoading,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      lastAnswerIsCorrect: lastAnswerIsCorrect ?? this.lastAnswerIsCorrect,
      isAnswering: isAnswering ?? this.isAnswering,
    );
  }
}

final practiceViewModelProvider =
    StateNotifierProvider<PracticeViewModel, PracticeState>((ref) {
  return PracticeViewModel(ref);
});
