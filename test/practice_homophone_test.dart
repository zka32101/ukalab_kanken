import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/homophone_data.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 漢検の「同音・同訓異字」に合わせた演習。
void main() {
  const levels = ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2'];
  final allKanji = <String>{for (final l in levels) ...LevelKanjiData.forLevel(l)};
  final kanjiChar = RegExp(r'[一-鿿]');
  final hira = RegExp(r'^[ぁ-ゖー]+$');

  group('問題データ（レビューの機械チェック）', () {
    test('読みはひらがな・文に【読み】が1回だけ・正解と誤答が重複しない', () {
      for (final q in kHomophoneQuestions) {
        expect(hira.hasMatch(q.reading), isTrue, reason: q.reading);
        expect('【'.allMatches(q.sentence).length, 1, reason: q.sentence);
        expect(q.sentence.contains('【${q.reading}】'), isTrue, reason: q.sentence);
        expect(q.wrong, isNotEmpty, reason: q.sentence);
        expect(q.wrong.toSet().length, q.wrong.length, reason: q.sentence);
        expect(q.wrong, isNot(contains(q.answer)), reason: q.sentence);
      }
    });

    test('文と選択肢の字は、すべて10級〜2級の配当漢字', () {
      for (final q in kHomophoneQuestions) {
        final chars = (q.sentence + q.answer + q.wrong.join()).split('').where(kanjiChar.hasMatch);
        expect(allKanji.containsAll(chars), isTrue, reason: q.sentence);
      }
    });

    test('正解と誤答は、同じ種類（同音は漢字だけ・同訓は送り仮名つき）でそろっている', () {
      for (final q in kHomophoneQuestions) {
        final all = [q.answer, ...q.wrong];
        if (q.kind == HomophoneKind.homograph) {
          // 同訓異字: どれも「漢字＋送り仮名」の形で、最後はひらがな。
          for (final w in all) {
            expect(kanjiChar.hasMatch(w[0]) && hira.hasMatch(w.substring(w.length - 1)), isTrue,
                reason: '${q.sentence} $w');
          }
        } else {
          for (final w in all) {
            expect(w.split('').every(kanjiChar.hasMatch), isTrue, reason: '${q.sentence} $w');
          }
        }
      }
    });

    test('同じ文が重複しない', () {
      final seen = <String>{};
      for (final q in kHomophoneQuestions) {
        expect(seen.add(q.sentence), isTrue, reason: q.sentence);
      }
    });

    test('同じ読みの問題は、正解がそれぞれ別（同じ答えが複数の文に出ない）', () {
      final seen = <String>{};
      for (final q in kHomophoneQuestions) {
        expect(seen.add('${q.reading}/${q.answer}'), isTrue, reason: '${q.reading} ${q.answer}');
      }
    });
  });

  group('出す級', () {
    test('同音異字は8級〜2級、同訓異字は6級〜2級だけに出る', () {
      for (final l in ['LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) {
        expect(availableModesForLevel(l), contains(PracticeMode.homophone), reason: l);
        expect(homophonesForLevel(l), isNotEmpty, reason: l);
      }
      for (final l in ['LEVEL_10', 'LEVEL_9', 'LEVEL_1_PRE', 'LEVEL_1']) {
        expect(availableModesForLevel(l), isNot(contains(PracticeMode.homophone)), reason: l);
        expect(homophonesForLevel(l), isEmpty, reason: l);
      }
    });

    test('8級は、小3までの漢字だけの同音異字（1字の答え）。誤字訂正には出ない', () {
      final qs = homophonesForLevel('LEVEL_8');
      expect(qs.length, greaterThanOrEqualTo(30));
      expect(qs.every((q) => q.kind == HomophoneKind.homophone), isTrue);
      expect(qs.where((q) => q.answer.length == 1).length, greaterThanOrEqualTo(30));
      expect(qs.every((q) => q.wrong.isNotEmpty), isTrue);
      expect(qs.map((q) => q.reading).toSet().length, greaterThanOrEqualTo(10));
      expect(errorCorrectionForLevel('LEVEL_5').any((q) => q.answer.length == 1), isFalse);
    });

    test('7級は同音異字だけ。6級以上は同訓異字も出る', () {
      expect(homophonesForLevel('LEVEL_7').every((q) => q.kind == HomophoneKind.homophone), isTrue);
      expect(homophonesForLevel('LEVEL_6').any((q) => q.kind == HomophoneKind.homograph), isTrue);
    });

    test('級が上がるほど、出せる問題が増える', () {
      final counts = [for (final l in ['LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) homophonesForLevel(l).length];
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i], greaterThanOrEqualTo(counts[i - 1]));
      }
      expect(counts.first, greaterThanOrEqualTo(5));
    });
  });
}
