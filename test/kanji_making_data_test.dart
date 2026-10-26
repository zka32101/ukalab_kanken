import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_making_data.dart';

void main() {
  test('漢字作り: 誤答は正解と別で、重なりもない(各2組)', () {
    for (final q in kKanjiMaking) {
      expect(q.wrong.length, 2, reason: q.prompt);
      expect(q.wrong[0], isNot(equals(q.wrong[1])), reason: q.prompt);
      for (final w in q.wrong) {
        expect(w.length, q.answer.length, reason: q.prompt);
        expect(w, isNot(equals(q.answer)), reason: q.prompt);
      }
    }
  });

  test('漢字作り(共通の字型): 先頭の誤答は、正解の字を入れ替えたものが多い', () {
    final s = kKanjiMaking.where((q) => q.prompt.startsWith('A') && q.answer.length == 2);
    final swapped = s.where((q) =>
        q.wrong.any((w) => w[0] == q.answer[1] && w[1] == q.answer[0]));
    // 入れ替えると実在する熟語になる問題は、入れ替えを足していない。
    expect(swapped.length, greaterThan(s.length ~/ 2));
  });
}
