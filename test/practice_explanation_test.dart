import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/bundled_questions.dart';
import 'package:kanken/data/kanji_making_data.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 熟語系の出題は、答えたあとに出す説明（正解の語など）を持つ。
void main() {
  late List<dynamic> seeds;

  setUpAll(() async {
    final b = BundledQuestions(loader: () async => File('assets/questions/kanken_questions.json').readAsString());
    seeds = await b.forLevel('LEVEL_2');
  });

  const cases = <(PracticeMode, String)>[
    (PracticeMode.yoji, 'LEVEL_2'),
    (PracticeMode.yoji, 'LEVEL_1'),
    (PracticeMode.koji, 'LEVEL_1'),
    (PracticeMode.antonym, 'LEVEL_2'),
    (PracticeMode.antonym, 'LEVEL_1'),
    (PracticeMode.synonym, 'LEVEL_2'),
    (PracticeMode.homophone, 'LEVEL_2'),
    (PracticeMode.errorCorrection, 'LEVEL_2'),
    (PracticeMode.wordReading, 'LEVEL_2'),
    (PracticeMode.wordWriting, 'LEVEL_1'),
    (PracticeMode.okurigana, 'LEVEL_5'),
    (PracticeMode.sanji, 'LEVEL_6'),
    (PracticeMode.kanjiMaking, 'LEVEL_6'),
    (PracticeMode.compoundStructure, 'LEVEL_4'),
  ];

  for (final c in cases) {
    test('${c.$1.name} ${c.$2}: 説明がある・正解の語を含む', () {
      final built = buildKanjiPracticeQuestions(List.from(seeds.take(40)), c.$1, c.$2);
      final own = built.where((q) => q.actualMode == c.$1).toList();
      expect(own, isNotEmpty);
      for (final q in own) {
        expect(q.explanation, isNotNull, reason: q.prompt);
        expect(q.explanation!.trim(), isNotEmpty, reason: q.prompt);
        if (c.$1 != PracticeMode.kanjiMaking && c.$1 != PracticeMode.compoundStructure &&
            c.$1 != PracticeMode.antonym && c.$1 != PracticeMode.synonym) {
          expect(q.explanation, contains(q.correctAnswer), reason: '${q.prompt} ${q.explanation}');
        }
      }
    });
  }

  test('漢字そのものを問う形式には、説明を付けない（土台の漢字の読み・用例を出す）', () {
    for (final m in [PracticeMode.reading, PracticeMode.writing, PracticeMode.strokeCount]) {
      final built = buildKanjiPracticeQuestions(List.from(seeds.take(20)), m, 'LEVEL_5');
      for (final q in built) {
        expect(q.explanation, isNull, reason: '$m');
      }
    }
  });

  test('漢字作りの説明は、問題のA・B・Cに正解を入れた形', () {
    final k = kKanjiMaking.firstWhere((x) => x.prompt == 'A景・景B');
    expect(kanjiMakingCompleted(k), '夜景・景品');
    final k3 = kKanjiMaking.firstWhere((x) => x.prompt == '条A・B設・C査');
    expect(kanjiMakingCompleted(k3), '条件・建設・検査');
  });
}
