import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 熟語系の出題は土台の漢字を間違いノート・今日の復習に記録しない（関係のない漢字が出るため）。
void main() {
  test('漢字そのものを問う形式だけ、間違いノート・今日の復習に記録する', () {
    const recorded = {
      PracticeMode.reading,
      PracticeMode.writing,
      PracticeMode.radical,
      PracticeMode.radicalName,
      PracticeMode.strokeCount,
      PracticeMode.strokeOrder,
      PracticeMode.okurigana,
    };
    for (final m in PracticeMode.values) {
      expect(practiceModeRecordsKanjiHistory(m), recorded.contains(m), reason: '$m');
    }
  });

  test('熟語系の形式は記録しない', () {
    for (final m in [
      PracticeMode.yoji,
      PracticeMode.koji,
      PracticeMode.antonym,
      PracticeMode.synonym,
      PracticeMode.homophone,
      PracticeMode.errorCorrection,
      PracticeMode.kanjiMaking,
      PracticeMode.sanji,
      PracticeMode.compoundStructure,
      PracticeMode.wordReading,
      PracticeMode.wordWriting,
    ]) {
      expect(practiceModeRecordsKanjiHistory(m), isFalse, reason: '$m');
    }
  });
}
