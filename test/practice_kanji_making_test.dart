import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/kanji_info_data.dart';
import 'package:kanken/data/kanji_making_data.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/data/local_exam_questions.dart';
import 'package:kanken/models/mock_exam_modes.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 漢検の「漢字作り」（公式の例題と同じ形）に合わせた演習。
void main() {
  const levels = ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2'];
  final allKanji = <String>{for (final l in levels) ...LevelKanjiData.forLevel(l)};
  final kanjiChar = RegExp(r'[一-鿿]');

  group('問題データ（レビューの機械チェック）', () {
    test('空欄の数と答え・誤答の数が合い、字は1字ずつ', () {
      expect(kKanjiMaking, isNotEmpty);
      for (final k in kKanjiMaking) {
        final blanks = 'ABC'.split('').where(k.prompt.contains).length;
        expect(k.answer.length, blanks, reason: k.prompt);
        expect(blanks, inInclusiveRange(2, 3), reason: k.prompt);
        expect(k.answer.every((c) => c.runes.length == 1), isTrue, reason: k.prompt);
        expect(k.wrong.length, 2, reason: k.prompt);
        for (final w in k.wrong) {
          expect(w.length, blanks, reason: k.prompt);
          expect(w.every((c) => c.runes.length == 1), isTrue, reason: k.prompt);
        }
      }
    });

    test('誤答の組み合わせは、正解と別・互いに別', () {
      for (final k in kKanjiMaking) {
        final texts = {
          kanjiMakingChoiceText(k.answer),
          for (final w in k.wrong) kanjiMakingChoiceText(w),
        };
        expect(texts.length, 3, reason: k.prompt);
      }
    });

    test('答えの字は重複しない（同じ字が2つの空欄の答えにならない）', () {
      for (final k in kKanjiMaking) {
        expect(k.answer.toSet().length, k.answer.length, reason: k.prompt);
      }
    });

    test('問題・答え・誤答の字は、すべて10級〜2級の配当漢字', () {
      for (final k in kKanjiMaking) {
        final chars = (k.prompt + k.answer.join() + k.wrong.expand((w) => w).join())
            .split('')
            .where(kanjiChar.hasMatch);
        expect(allKanji.containsAll(chars), isTrue, reason: k.prompt);
      }
    });

    test('同じ問題が重複しない', () {
      final seen = <String>{};
      for (final k in kKanjiMaking) {
        expect(seen.add(k.prompt), isTrue, reason: k.prompt);
      }
    });

    test('誤答の組み合わせを入れても、アプリの用例データにある実在の二字熟語にならない（公式の例題の「景色」を除く）', () {
      // 「A景・景B」の誤答に「色」を入れると「景色」になる、という公式の例題と同じ組だけは、そのまま残す。
      const allowed = {'景色'};
      final words = <String>{};
      for (final l in levels) {
        for (final k in LevelKanjiData.forLevel(l)) {
          final info = KanjiInfoData.get(k);
          if (info == null) continue;
          for (final e in info.examples) {
            final m = RegExp(r'^([^（）]{2})（').firstMatch(e);
            if (m != null) words.add(m.group(1)!);
          }
        }
      }
      for (final k in kKanjiMaking) {
        // 「A景・景B」型: 誤答 (x, y) → x景 と 景y
        final shared = RegExp(r'^A(.)・(.)B$').firstMatch(k.prompt);
        if (shared != null && shared.group(1) == shared.group(2)) {
          final s = shared.group(1)!;
          for (final w in k.wrong) {
            for (final cand in ['${w[0]}$s', '$s${w[1]}']) {
              if (allowed.contains(cand)) continue;
              expect(words.contains(cand), isFalse, reason: '${k.prompt} の誤答 ${w.join()} から実在語 $cand');
            }
          }
        }
      }
    });

    test('正解の字を入れると、問題の語がすべて漢字になる（A・B・C が残らない）', () {
      for (final k in kKanjiMaking) {
        var s = k.prompt;
        for (var i = 0; i < k.answer.length; i++) {
          s = s.replaceAll('ABC'[i], k.answer[i]);
        }
        expect('ABC'.split('').any(s.contains), isFalse, reason: k.prompt);
      }
    });
  });

  group('出す級・選択肢', () {
    test('漢字作りは7級〜2級だけに出る', () {
      for (final l in ['LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) {
        expect(availableModesForLevel(l), contains(PracticeMode.kanjiMaking), reason: l);
        expect(kanjiMakingForLevel(l), isNotEmpty, reason: l);
      }
      for (final l in ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_1_PRE', 'LEVEL_1']) {
        expect(availableModesForLevel(l), isNot(contains(PracticeMode.kanjiMaking)), reason: l);
        expect(kanjiMakingForLevel(l), isEmpty, reason: l);
      }
    });

    test('級が上がるほど、出せる問題が増える', () {
      final counts = [for (final l in ['LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) kanjiMakingForLevel(l).length];
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i], greaterThanOrEqualTo(counts[i - 1]));
      }
      expect(counts.first, greaterThanOrEqualTo(5));
    });

    test('選択肢の文字列の形', () {
      expect(kanjiMakingChoiceText(['件', '建', '検']), 'A件　B建　C検');
      expect(kanjiMakingChoiceText(['夜', '品']), 'A夜　B品');
    });
  });

  test('模擬試験でも、7級〜2級に「漢字作り」を作れる', () {
    for (final level in [7, 6, 5, 4, 3, 25, 2]) {
      expect(localExamCategoriesForLevel(level), contains(ExamCategory.kanjiMaking), reason: '$level');
      final qs = buildLocalExamQuestions(level: level, categories: [ExamCategory.kanjiMaking], count: 5);
      expect(qs, isNotEmpty, reason: '$level');
      for (final q in qs) {
        expect(q.options.length, 3, reason: q.questionId);
        expect(q.options.toSet().length, 3, reason: q.questionId);
        expect(q.options, contains(q.correctAnswer), reason: q.questionId);
      }
    }
    expect(localExamCategoriesForLevel(8), isNot(contains(ExamCategory.kanjiMaking)));
  });
}
