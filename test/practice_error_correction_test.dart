import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 漢検の「誤字訂正」に合わせた演習（同音・同訓異字の問題から作る）。
void main() {
  test('誤字訂正は5級〜2級だけに出る', () {
    for (final l in ['LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) {
      expect(availableModesForLevel(l), contains(PracticeMode.errorCorrection), reason: l);
      expect(errorCorrectionForLevel(l), isNotEmpty, reason: l);
    }
    for (final l in ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_1_PRE', 'LEVEL_1']) {
      expect(availableModesForLevel(l), isNot(contains(PracticeMode.errorCorrection)), reason: l);
      expect(errorCorrectionForLevel(l), isEmpty, reason: l);
    }
  });

  test('出せる問題は誤答が3つ以上（文に誤答を1つ入れても、選択肢が3つ以上残る）', () {
    for (final l in ['LEVEL_5', 'LEVEL_2']) {
      for (final q in errorCorrectionForLevel(l)) {
        expect(q.wrong.length, greaterThanOrEqualTo(3), reason: q.sentence);
        for (final shown in q.wrong) {
          final choices = [q.answer, ...q.wrong.where((w) => w != shown)];
          expect(choices.length, greaterThanOrEqualTo(3), reason: q.sentence);
          expect(choices.toSet().length, choices.length, reason: q.sentence);
          expect(choices.contains(shown), isFalse, reason: q.sentence);
        }
      }
    }
  });

  test('誤字訂正の問題は、同音・同訓異字の問題の一部（同じ級以下の字だけ）', () {
    expect(errorCorrectionForLevel('LEVEL_5').length,
        lessThanOrEqualTo(homophonesForLevel('LEVEL_5').length));
    expect(errorCorrectionForLevel('LEVEL_2').length,
        greaterThanOrEqualTo(errorCorrectionForLevel('LEVEL_5').length));
  });
}
