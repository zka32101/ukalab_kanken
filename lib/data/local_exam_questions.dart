import 'dart:math';

import '../models/mock_exam_modes.dart';
import '../viewmodels/practice_viewmodel.dart';
import 'homophone_data.dart';
import 'kanji_radical_data.dart';
import 'level_kanji_data.dart';
import 'word_relation_data.dart';

/// 模擬試験の級（int。準2級=25、準1級=15）を、演習で使う級の文字列にする。
/// 知らない級は null。
String? examLevelToLevelString(int level) {
  if (level == 25) return 'LEVEL_2_PRE';
  if (level == 15) return 'LEVEL_1_PRE';
  if (level >= 1 && level <= 10) return 'LEVEL_$level';
  return null;
}

/// アプリの中で（Firestore の問題データではなく）その場で作る、模擬試験の出題分野。
/// 演習の出題形式（四字熟語・対義語・類義語・同音・同訓異字・誤字訂正・部首名）と同じ元データを使う。
const List<ExamCategory> kLocalExamCategories = [
  ExamCategory.yoji,
  ExamCategory.antonym,
  ExamCategory.synonym,
  ExamCategory.homophone,
  ExamCategory.errorCorrection,
  ExamCategory.radicalName,
];

/// 指定の級で、その場で作れる分野（漢検でその級に出る分野だけ）。
List<ExamCategory> localExamCategoriesForLevel(int level) {
  final l = examLevelToLevelString(level);
  if (l == null) return const [];
  return [
    for (final c in kLocalExamCategories)
      if (_poolSize(c, l) > 0) c,
  ];
}

int _poolSize(ExamCategory c, String level) {
  switch (c) {
    case ExamCategory.yoji:
      return yojiForLevel(level).length;
    case ExamCategory.antonym:
      return wordRelationsForLevel(level, WordRelationKind.antonym).length;
    case ExamCategory.synonym:
      return wordRelationsForLevel(level, WordRelationKind.synonym).length;
    case ExamCategory.homophone:
      return homophonesForLevel(level).where((h) => h.wrong.length >= 2).length;
    case ExamCategory.errorCorrection:
      return errorCorrectionForLevel(level).length;
    case ExamCategory.radicalName:
      return availableModesForLevel(level).contains(PracticeMode.radicalName)
          ? LevelKanjiData.forLevel(level)
              .where((k) => KanjiRadicalData.get(k) != null)
              .length
          : 0;
    default:
      return 0;
  }
}

EnhancedExamQuestion _make({
  required int level,
  required ExamCategory category,
  required String id,
  required String kanji,
  required String question,
  required List<String> options,
  required String answer,
  required String explanation,
}) =>
    EnhancedExamQuestion(
      questionId: 'local-${category.name}-$id',
      kanji: kanji,
      questionType: category.name,
      question: question,
      options: options,
      correctAnswer: answer,
      explanation: explanation,
      level: level,
      difficulty: ExamDifficulty.medium,
      category: category,
      averageTimeSeconds: 30,
      correctnessRate: 0,
      userAttempts: 0,
      commonMistakes: const [],
    );

/// [level]（模擬試験の級）の、その場で作る問題を [count] 問まで作る。[categories] のうち、
/// その級で作れる分野を順番に回して出す（同じ問題は重複させない。足りなければ少なくなる）。
List<EnhancedExamQuestion> buildLocalExamQuestions({
  required int level,
  required Iterable<ExamCategory> categories,
  required int count,
  Random? random,
}) {
  final rnd = random ?? Random();
  final levelString = examLevelToLevelString(level);
  if (levelString == null || count <= 0) return const [];
  final cats = [
    for (final c in categories)
      if (kLocalExamCategories.contains(c) && _poolSize(c, levelString) > 0) c,
  ];
  if (cats.isEmpty) return const [];

  // 分野ごとに、重複しない問題の並びを作っておく。
  final queues = <ExamCategory, List<EnhancedExamQuestion>>{
    for (final c in cats)
      c: _buildAll(c, level, levelString, rnd)..shuffle(rnd),
  };
  final out = <EnhancedExamQuestion>[];
  var i = 0;
  var emptyRounds = 0;
  while (out.length < count && emptyRounds < cats.length) {
    final c = cats[i % cats.length];
    i++;
    final q = queues[c]!;
    if (q.isEmpty) {
      emptyRounds++;
      continue;
    }
    emptyRounds = 0;
    out.add(q.removeLast());
  }
  return out;
}

List<EnhancedExamQuestion> _buildAll(
    ExamCategory c, int level, String l, Random rnd) {
  switch (c) {
    case ExamCategory.yoji:
      final out = <EnhancedExamQuestion>[];
      for (final y in yojiForLevel(l)) {
        final index = rnd.nextInt(4);
        out.add(_make(
          level: level,
          category: c,
          id: y.word,
          kanji: y.word,
          question: '${y.meaning}（${y.reading}）\n'
              '「${y.word.replaceRange(index, index + 1, '□')}」の□に入る漢字はどれ？',
          options: yojiBlankChoices(y.word, index, l, rnd),
          answer: y.word[index],
          explanation: '${y.word}（${y.reading}）: ${y.meaning}',
        ));
      }
      return out;
    case ExamCategory.antonym:
    case ExamCategory.synonym:
      final kind = c == ExamCategory.antonym
          ? WordRelationKind.antonym
          : WordRelationKind.synonym;
      final out = <EnhancedExamQuestion>[];
      for (final r in wordRelationsForLevel(l, kind)) {
        final reversed = rnd.nextBool();
        final choices = wordRelationChoices(r, reversed, l, rnd);
        if (choices == null) continue;
        final ask = reversed ? r.partner : r.word;
        final askReading = reversed ? r.partnerReading : r.reading;
        final answer = reversed ? r.word : r.partner;
        final isAntonym = kind == WordRelationKind.antonym;
        out.add(_make(
          level: level,
          category: c,
          id: '${r.word}-${r.partner}',
          kanji: ask,
          question: isAntonym
              ? '「$ask（$askReading）」の対義語（反対の意味の言葉）はどれ？'
              : '「$ask（$askReading）」の類義語（ほぼ同じ意味の言葉）はどれ？',
          options: choices,
          answer: answer,
          explanation:
              '$ask と $answer は、${isAntonym ? '反対の意味' : 'ほぼ同じ意味'}の言葉です。',
        ));
      }
      return out;
    case ExamCategory.homophone:
      return [
        // 模擬試験は3択以上にする（誤答が1つだけの組は、2択になるので除く）。
        for (final h in homophonesForLevel(l))
          if (h.wrong.length >= 2)
            _make(
              level: level,
              category: c,
              id: '${h.reading}-${h.answer}',
              kanji: h.answer,
              question: '${h.sentence}\n'
                  '${h.kind == HomophoneKind.homophone ? '【 】のひらがなを漢字で書くと？' : '【 】のひらがなを、漢字と送りがなで書くと？'}',
              options: [
                h.answer,
                ...(List<String>.from(h.wrong)..shuffle(rnd)).take(3)
              ]..shuffle(rnd),
              answer: h.answer,
              explanation: '正しくは「${h.answer}」です。',
            ),
      ];
    case ExamCategory.errorCorrection:
      final out = <EnhancedExamQuestion>[];
      for (final h in errorCorrectionForLevel(l)) {
        final shown = h.wrong[rnd.nextInt(h.wrong.length)];
        final others = h.wrong.where((w) => w != shown).toList()..shuffle(rnd);
        out.add(_make(
          level: level,
          category: c,
          id: '${h.reading}-${h.answer}',
          kanji: h.answer,
          question: '${h.sentence.replaceFirst('【${h.reading}】', '【$shown】')}\n'
              '【 】の漢字は誤りです。正しい漢字は？',
          options: [h.answer, ...others.take(3)]..shuffle(rnd),
          answer: h.answer,
          explanation: '正しくは「${h.answer}」です。',
        ));
      }
      return out;
    case ExamCategory.radicalName:
      final out = <EnhancedExamQuestion>[];
      final kanji = LevelKanjiData.forLevel(l)
          .where((k) => KanjiRadicalData.get(k) != null)
          .toList()
        ..shuffle(rnd);
      for (final k in kanji.take(40)) {
        final choices = radicalNameChoices(k, rnd);
        if (choices == null) continue;
        final info = KanjiRadicalData.get(k)!;
        out.add(_make(
          level: level,
          category: c,
          id: k,
          kanji: k,
          question: '「$k」の部首名はどれ？',
          options: choices,
          answer: info.radicalName,
          explanation: '「$k」の部首は「${info.radical}」、部首名は「${info.radicalName}」です。',
        ));
      }
      return out;
    default:
      return const [];
  }
}
