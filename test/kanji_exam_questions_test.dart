import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/bundled_questions.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/data/local_exam_questions.dart';
import 'package:kanken/models/index.dart';
import 'package:kanken/models/mock_exam_modes.dart';

/// 試験問題が無い級（10級・準1級・1級）や、オフラインでも、漢字の問題から模擬試験を作れる。
void main() {
  Future<List<KanjiQuestion>> bundled(String level) => BundledQuestions(
          loader: () async => File('assets/questions/kanken_questions.json').readAsString())
      .forLevel(level);

  test('10級: 読みと書き取りの試験問題を、指定の数だけ作る（重複なし・正解は選択肢に入る）', () async {
    final ks = await bundled('LEVEL_10');
    final qs = buildKanjiExamQuestions(level: 10, kanjiQuestions: ks, count: 40, random: Random(1));
    expect(qs.length, 40);
    expect(qs.map((q) => q.questionId).toSet().length, 40);
    expect(qs.where((q) => q.category == ExamCategory.reading).length, 20);
    expect(qs.where((q) => q.category == ExamCategory.writing).length, 20);
    final kanji = LevelKanjiData.forLevel('LEVEL_10').toSet();
    for (final q in qs) {
      expect(q.level, 10);
      expect(q.options, contains(q.correctAnswer), reason: q.questionId);
      expect(q.options.toSet().length, q.options.length, reason: q.questionId);
      expect(q.options.length, greaterThanOrEqualTo(3), reason: q.questionId);
      if (q.category == ExamCategory.reading) {
        expect(kanji.contains(q.kanji), isTrue, reason: q.questionId); // 大きい文字は問われる字（答えではない）
        expect(q.correctAnswer, isNot(q.kanji));
      } else {
        expect(kanji.contains(q.correctAnswer), isTrue, reason: q.questionId);
        expect(q.kanji, isNot(q.correctAnswer)); // 書き取りは、読みを出す（答えの字は出さない）
      }
    }
  });

  test('足りなければ作れる分だけ。準1級・1級（問題が無い・未対応の級）は空でも例外にしない', () async {
    final ks = await bundled('LEVEL_9');
    final few = buildKanjiExamQuestions(level: 9, kanjiQuestions: ks.take(5).toList(), count: 30, random: Random(2));
    expect(few.length, 5);
    expect(buildKanjiExamQuestions(level: 15, kanjiQuestions: const [], count: 10), isEmpty);
    expect(buildKanjiExamQuestions(level: 99, kanjiQuestions: ks, count: 10), isEmpty);
    expect(buildKanjiExamQuestions(level: 10, kanjiQuestions: ks, count: 0), isEmpty);
  });

  test('その級の配当漢字以外の問題は混ぜない', () async {
    final mixed = [...await bundled('LEVEL_9'), ...await bundled('LEVEL_10')];
    final qs = buildKanjiExamQuestions(level: 10, kanjiQuestions: mixed, count: 200, random: Random(3));
    expect(qs.length, 80);
    final kanji = LevelKanjiData.forLevel('LEVEL_10').toSet();
    for (final q in qs) {
      final src = q.category == ExamCategory.reading ? q.kanji : q.correctAnswer;
      expect(kanji.contains(src), isTrue, reason: q.questionId);
    }
  });
}
