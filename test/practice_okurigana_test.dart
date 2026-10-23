import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_info_data.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/data/local_exam_questions.dart';
import 'package:kanken/data/okurigana_data.dart';
import 'package:kanken/models/mock_exam_modes.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 漢検の「送りがな」（正しい送りがなを3つから選ぶ）に合わせた演習。
void main() {
  const levels = ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2'];
  final hira = RegExp(r'^[ぁ-ゖー]+$');
  final kanjiChar = RegExp(r'[一-鿿]');

  // 配当漢字のどの字・どの読みでも成り立つ「正しい語」の全体（誤った形が、実は正しい語、でないことの確認用）。
  final validWords = <String>{};
  for (final l in levels) {
    for (final k in LevelKanjiData.forLevel(l)) {
      final info = KanjiInfoData.get(k);
      if (info == null) continue;
      for (final r in info.readings) {
        final m = RegExp(r'（([ぁ-ゖー]+)）').firstMatch(r);
        if (m != null) validWords.add('$k${m.group(1)}');
      }
      for (final e in info.examples) {
        final w = e.split('（').first;
        validWords.add(w);
      }
    }
  }

  group('問題データ（レビューの機械チェック）', () {
    test('語は「漢字1字＋ひらがなの送りがな」、読みはひらがな、読みの前が漢字だけで読む部分', () {
      expect(kOkurigana, isNotEmpty);
      for (final o in kOkurigana) {
        expect(kanjiChar.hasMatch(o.kanji) && o.kanji.runes.length == 1, isTrue, reason: o.word);
        expect(hira.hasMatch(o.okuri), isTrue, reason: o.word);
        expect(hira.hasMatch(o.stem), isTrue, reason: o.word);
        expect(o.stem.runes.length, greaterThanOrEqualTo(2), reason: o.word);
        expect(o.reading, '${o.stem}${o.okuri}', reason: o.word);
      }
    });

    test('誤った形は2つで、正しい形と別・互いに別・送りがなを足しすぎた形', () {
      for (final o in kOkurigana) {
        expect(o.wrong.length, 2, reason: o.word);
        expect(o.wrong.toSet().length, 2, reason: o.word);
        expect(o.wrong, isNot(contains(o.word)), reason: o.word);
        for (final w in o.wrong) {
          expect(w.startsWith(o.kanji) && w.endsWith(o.okuri), isTrue, reason: '${o.word} → $w');
          expect(w.runes.length, greaterThan(o.word.runes.length), reason: '${o.word} → $w');
        }
      }
    });

    test('誤った形が、実は正しい語（用例・別の読みの送りがな）になっていない', () {
      for (final o in kOkurigana) {
        for (final w in o.wrong) {
          expect(validWords.contains(w), isFalse, reason: '${o.word} の誤った形 $w は正しい語として存在する');
        }
      }
    });

    test('許容のある語や、読みだけでは漢字が決まらない語・数え方は出さない', () {
      final readings = <String, int>{};
      for (final o in kOkurigana) {
        expect(kOkuriganaAmbiguousWords.contains(o.word), isFalse, reason: o.word);
        expect(o.okuri == 'つ' || o.okuri == 'か', isFalse, reason: o.word);
        expect(o.stem.endsWith('っ'), isFalse, reason: o.word);
        readings.update(o.reading, (n) => n + 1, ifAbsent: () => 1);
      }
      for (final e in readings.entries) {
        expect(e.value, 1, reason: '読み ${e.key} が複数の字にある');
      }
    });

    test('語が重複しない', () {
      final seen = <String>{};
      for (final o in kOkurigana) {
        expect(seen.add(o.word), isTrue, reason: o.word);
      }
    });
  });

  group('出す級', () {
    test('送りがなは8級〜2級だけに出る', () {
      for (final l in ['LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) {
        expect(availableModesForLevel(l), contains(PracticeMode.okurigana), reason: l);
        expect(okuriganaForLevel(l), isNotEmpty, reason: l);
      }
      for (final l in ['LEVEL_10', 'LEVEL_9', 'LEVEL_1_PRE', 'LEVEL_1']) {
        expect(availableModesForLevel(l), isNot(contains(PracticeMode.okurigana)), reason: l);
        expect(okuriganaForLevel(l), isEmpty, reason: l);
      }
    });

    test('出せる語は、その級以下の字だけ。級が上がるほど増える', () {
      final order = {for (var i = 0; i < levels.length; i++) levels[i]: i};
      for (final l in ['LEVEL_8', 'LEVEL_5']) {
        for (final o in okuriganaForLevel(l)) {
          expect(order[o.level]!, lessThanOrEqualTo(order[l]!), reason: '$l ${o.word}');
        }
      }
      final counts = [for (final l in ['LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) okuriganaForLevel(l).length];
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i], greaterThanOrEqualTo(counts[i - 1]));
      }
      expect(counts.first, greaterThanOrEqualTo(30));
    });
  });

  test('模擬試験でも、8級〜2級に「送りがな」を作れる', () {
    for (final level in [8, 7, 6, 5, 4, 3, 25, 2]) {
      expect(localExamCategoriesForLevel(level), contains(ExamCategory.okurigana), reason: '$level');
      final qs = buildLocalExamQuestions(level: level, categories: [ExamCategory.okurigana], count: 10);
      expect(qs, isNotEmpty, reason: '$level');
      for (final q in qs) {
        expect(q.options.length, 3, reason: q.questionId);
        expect(q.options.toSet().length, 3, reason: q.questionId);
        expect(q.options, contains(q.correctAnswer), reason: q.questionId);
      }
    }
    expect(localExamCategoriesForLevel(10), isNot(contains(ExamCategory.okurigana)));
  });
}
