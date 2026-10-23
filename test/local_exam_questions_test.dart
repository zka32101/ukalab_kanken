import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/local_exam_questions.dart';
import 'package:kanken/models/mock_exam_modes.dart';

/// 模擬試験に、アプリの中で作る新しい出題分野（四字熟語・対義語・類義語 など）を混ぜる。
void main() {
  const examLevels = [10, 9, 8, 7, 6, 5, 4, 3, 25, 2, 15, 1];

  test('模擬試験の級（int）は、演習の級の文字列になる', () {
    expect(examLevelToLevelString(10), 'LEVEL_10');
    expect(examLevelToLevelString(5), 'LEVEL_5');
    expect(examLevelToLevelString(25), 'LEVEL_2_PRE');
    expect(examLevelToLevelString(15), 'LEVEL_1_PRE');
    expect(examLevelToLevelString(1), 'LEVEL_1');
    expect(examLevelToLevelString(0), isNull);
    expect(examLevelToLevelString(11), isNull);
  });

  test('作れる分野は、漢検でその級に出る分野だけ（演習の出題形式と同じ級）', () {
    expect(localExamCategoriesForLevel(10), isEmpty);
    expect(localExamCategoriesForLevel(9), isEmpty);
    expect(localExamCategoriesForLevel(8), containsAll([ExamCategory.antonym, ExamCategory.radicalName]));
    expect(localExamCategoriesForLevel(8), isNot(contains(ExamCategory.synonym)));
    expect(localExamCategoriesForLevel(7), contains(ExamCategory.homophone));
    expect(localExamCategoriesForLevel(6), contains(ExamCategory.synonym));
    expect(localExamCategoriesForLevel(6), isNot(contains(ExamCategory.yoji)));
    expect(
        localExamCategoriesForLevel(5),
        containsAll([ExamCategory.yoji, ExamCategory.errorCorrection, ExamCategory.synonym]));
    for (final l in [4, 3, 25, 2]) {
      expect(localExamCategoriesForLevel(l), contains(ExamCategory.yoji), reason: '$l');
      // 部首名は、公式の出題内容どおり8級〜2級に出る（4級〜2級の部首データができたため）。
      expect(localExamCategoriesForLevel(l), contains(ExamCategory.radicalName), reason: '$l');
    }
    expect(localExamCategoriesForLevel(15), isEmpty);
    expect(localExamCategoriesForLevel(1), isEmpty);
  });

  test('作った問題は、選択肢が重複せず正解を含み、級と分野が合っている', () {
    final random = Random(9);
    for (final level in examLevels) {
      final cats = localExamCategoriesForLevel(level);
      final qs = buildLocalExamQuestions(level: level, categories: cats, count: 30, random: random);
      if (cats.isEmpty) {
        expect(qs, isEmpty, reason: '$level');
        continue;
      }
      expect(qs, isNotEmpty, reason: '$level');
      final ids = <String>{};
      for (final q in qs) {
        expect(ids.add(q.questionId), isTrue, reason: '$level ${q.questionId} が重複');
        expect(q.level, level, reason: q.questionId);
        expect(cats, contains(q.category), reason: q.questionId);
        expect(q.question.trim(), isNotEmpty, reason: q.questionId);
        expect(q.options.length, inInclusiveRange(3, 4), reason: q.questionId);
        expect(q.options.toSet().length, q.options.length, reason: q.questionId);
        expect(q.options, contains(q.correctAnswer), reason: q.questionId);
        expect(q.explanation.trim(), isNotEmpty, reason: q.questionId);
      }
    }
  });

  test('画面の大きい枠に出る文字（kanji）が、答えを含まない（実機で、四字熟語の答えが丸見えだった）', () {
    // 問われている語そのものを出す分野（対義語・類義語・漢字作り・部首名）は、対象外。
    // それ以外は、答えの漢字（語）が kanji に入っていてはいけない。
    const hiding = [
      ExamCategory.homophone,
      ExamCategory.errorCorrection,
      ExamCategory.okurigana,
    ];
    for (final level in [8, 7, 6, 5, 4, 3, 25, 2]) {
      for (final c in hiding) {
        final qs = buildLocalExamQuestions(
            level: level, categories: [c], count: 200, random: Random(6));
        for (final q in qs) {
          expect(q.kanji.contains(q.correctAnswer), isFalse,
              reason: '$level ${c.name}: 「${q.kanji}」が答え「${q.correctAnswer}」を含む');
        }
      }
      // 四字熟語は、答えの字を□で伏せた形を出す（四苦八苦のように、同じ字が別の位置にもある語がある
      // ので、「答えの字を含まない」ではなく「□がある（完成した語ではない）」で確かめる）。
      final yoji = buildLocalExamQuestions(
          level: level, categories: [ExamCategory.yoji], count: 200, random: Random(6));
      for (final q in yoji) {
        expect(q.kanji.contains('□'), isTrue, reason: '$level 「${q.kanji}」は答えの字を伏せた形');
        expect(q.question.contains(q.kanji.replaceAll('□', q.correctAnswer)), isFalse,
            reason: '$level 問題文に完成した語が出ている');
      }
    }
  });

  test('分野は順番に回して出る（1分野に偏らない）', () {
    final qs = buildLocalExamQuestions(
        level: 5, categories: localExamCategoriesForLevel(5), count: 12, random: Random(2));
    expect(qs.map((q) => q.category).toSet().length, greaterThanOrEqualTo(4));
  });

  test('指定した分野以外・その級に無い分野は作らない', () {
    final onlyYoji = buildLocalExamQuestions(
        level: 5, categories: [ExamCategory.yoji, ExamCategory.reading], count: 10, random: Random(1));
    expect(onlyYoji.every((q) => q.category == ExamCategory.yoji), isTrue);
    expect(buildLocalExamQuestions(level: 10, categories: [ExamCategory.yoji], count: 5), isEmpty);
    expect(buildLocalExamQuestions(level: 5, categories: [ExamCategory.reading], count: 5), isEmpty);
    expect(buildLocalExamQuestions(level: 5, categories: ExamCategory.values, count: 0), isEmpty);
  });

  test('出題数が作れる数より多いときは、作れる分だけ（重複させない）', () {
    final qs = buildLocalExamQuestions(
        level: 7, categories: [ExamCategory.homophone], count: 500, random: Random(4));
    expect(qs.map((q) => q.questionId).toSet().length, qs.length);
    expect(qs.length, lessThan(500));
  });

  test('出題の並びは mixed が最後（カテゴリ選択の一覧は最後の mixed を除くため）', () {
    expect(ExamCategory.values.last, ExamCategory.mixed);
  });
}
