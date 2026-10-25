import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/bundled_questions.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';
import 'package:kanken/views/home_screen.dart';

/// 答えたあとに出す説明。以前は「いま答えた問題」を、どこでも入れない値（currentQuestion）から
/// 読んでいたため、読み方・用例も熟語系の説明も、一度も出なかった。
void main() {
  late List<PracticeQuestion> yoji;
  late List<PracticeQuestion> reading;

  setUpAll(() async {
    final b = BundledQuestions(loader: () async => File('assets/questions/kanken_questions.json').readAsString());
    final seeds = (await b.forLevel('LEVEL_2')).take(40).toList();
    yoji = buildKanjiPracticeQuestions(seeds, PracticeMode.yoji, 'LEVEL_5')
        .where((q) => q.actualMode == PracticeMode.yoji)
        .toList();
    reading = buildKanjiPracticeQuestions(seeds, PracticeMode.reading, 'LEVEL_2')
        .where((q) => q.actualMode == PracticeMode.reading)
        .toList();
  });

  test('答えた問題は、出題の一覧と今の番号から取る', () {
    expect(answeredPracticeQuestion(null, 0), isNull);
    expect(answeredPracticeQuestion(yoji, -1), isNull);
    expect(answeredPracticeQuestion(yoji, yoji.length), isNull);
    expect(answeredPracticeQuestion(yoji, 0), same(yoji.first));
    expect(answeredPracticeQuestion(yoji, yoji.length - 1), same(yoji.last));
  });

  test('熟語系は、問題ごとの説明（正解の語）を出し、土台の漢字の読み・用例は出さない', () {
    for (final q in yoji) {
      final e = practiceAnswerExplanation(q);
      expect(e, isNotNull);
      expect(e, q.explanation);
      expect(e, isNot(contains('読み方:')));
      expect(e, contains(q.correctAnswer));
    }
  });

  test('漢字そのものを問う形式は、その漢字の読み・用例を出す（あれば）', () {
    expect(reading, isNotEmpty);
    var shown = 0;
    for (final q in reading) {
      final e = practiceAnswerExplanation(q);
      if (q.source.reading != null && q.source.reading!.isNotEmpty) {
        expect(e, contains('読み方: ${q.source.reading}'));
        shown++;
      }
    }
    expect(shown, greaterThan(0));
  });

  test('問題が無いときは null', () {
    expect(practiceAnswerExplanation(null), isNull);
  });
}
