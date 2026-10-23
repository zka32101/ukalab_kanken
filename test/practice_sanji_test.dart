import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/data/local_exam_questions.dart';
import 'package:kanken/data/sanji_jukugo_data.dart';
import 'package:kanken/models/mock_exam_modes.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 三字熟語（1字をカタカナにして、その漢字を選ぶ）。漢検の「三字熟語」（7級・6級）。
/// 公式の例題は確認できなかったので、複数の練習サイトで共通する形に合わせている。
void main() {
  const levels = ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2'];
  final allKanji = <String>{for (final l in levels) ...LevelKanjiData.forLevel(l)};
  final katakana = RegExp(r'^[ァ-ヶー]+$');

  group('三字熟語データ（レビューの機械チェック）', () {
    test('3字・読みは3つともカタカナ・すべて10級〜2級の配当漢字・重複なし', () {
      final seen = <String>{};
      for (final s in kSanjiJukugo) {
        expect(s.word.runes.length, 3, reason: s.word);
        expect(s.readings.length, 3, reason: s.word);
        expect(s.readings.every(katakana.hasMatch), isTrue, reason: s.word);
        expect(allKanji.containsAll(s.word.split('')), isTrue, reason: s.word);
        expect(seen.add(s.word), isTrue, reason: '${s.word} が重複');
      }
    });

    test('level は、語の字のうち最も難しい級', () {
      const rank = {
        'LEVEL_10': 10, 'LEVEL_9': 9, 'LEVEL_8': 8, 'LEVEL_7': 7, 'LEVEL_6': 6,
        'LEVEL_5': 5, 'LEVEL_4': 4, 'LEVEL_3': 3, 'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2,
      };
      for (final s in kSanjiJukugo) {
        final hardest = s.word
            .split('')
            .map((c) => [
                  for (final e in rank.entries)
                    if (LevelKanjiData.forLevel(e.key).contains(c)) e.value
                ].first)
            .reduce(min);
        expect(rank[s.level], hardest, reason: s.word);
      }
    });
  });

  group('出す級', () {
    test('三字熟語は7級・6級だけに出る（公式の出題内容に合わせる）', () {
      for (final l in ['LEVEL_7', 'LEVEL_6']) {
        expect(availableModesForLevel(l), contains(PracticeMode.sanji), reason: l);
        expect(sanjiForLevel(l), isNotEmpty, reason: l);
      }
      for (final l in ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1']) {
        expect(availableModesForLevel(l), isNot(contains(PracticeMode.sanji)), reason: l);
        expect(sanjiForLevel(l), isEmpty, reason: l);
      }
    });

    test('6級は7級より語が多く、どちらも十分にある', () {
      expect(sanjiForLevel('LEVEL_6').length, greaterThanOrEqualTo(sanjiForLevel('LEVEL_7').length));
      expect(sanjiForLevel('LEVEL_7').length, greaterThanOrEqualTo(15));
    });

    test('出せる語は、その級以下の字だけ', () {
      final upTo7 = <String>{
        for (final l in ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7']) ...LevelKanjiData.forLevel(l),
      };
      for (final s in sanjiForLevel('LEVEL_7')) {
        expect(upTo7.containsAll(s.word.split('')), isTrue, reason: s.word);
      }
    });
  });

  group('問題', () {
    test('カタカナにした1字の読みが入り、選択肢は4つで正解を含み、別の三字熟語になる字は入らない', () {
      final random = Random(5);
      var made = 0;
      for (final level in ['LEVEL_7', 'LEVEL_6']) {
        for (final s in sanjiForLevel(level)) {
          for (var i = 0; i < 3; i++) {
            final b = sanjiBlank(s, i, level, random);
            if (b == null) continue;
            made++;
            expect(b.answer, s.word[i], reason: s.word);
            expect(b.prompt.contains(s.readings[i]), isTrue, reason: s.word);
            expect(b.prompt.replaceFirst(s.readings[i], b.answer), s.word, reason: s.word);
            expect(b.choices.length, 4, reason: s.word);
            expect(b.choices.toSet().length, 4, reason: s.word);
            expect(b.choices, contains(b.answer), reason: s.word);
            for (final c in b.choices.where((c) => c != b.answer)) {
              final cand = s.word.replaceRange(i, i + 1, c);
              expect(kSanjiJukugo.any((x) => x.word == cand), isFalse, reason: '${s.word} に $c');
              expect(s.word.contains(c), isFalse, reason: '${s.word} に $c');
            }
          }
        }
      }
      expect(made, greaterThan(60));
    });
  });

  test('模擬試験でも、7級・6級に「三字熟語」を作れる', () {
    for (final level in [7, 6]) {
      expect(localExamCategoriesForLevel(level), contains(ExamCategory.sanji), reason: '$level');
      final qs = buildLocalExamQuestions(level: level, categories: [ExamCategory.sanji], count: 10);
      expect(qs, isNotEmpty, reason: '$level');
      for (final q in qs) {
        expect(q.options.length, 4, reason: q.questionId);
        expect(q.options, contains(q.correctAnswer), reason: q.questionId);
        // 問題の上の大きい枠に、完成した語（答え）を出さない。
        expect(kSanjiJukugo.any((s) => s.word == q.kanji), isFalse, reason: '${q.kanji} は完成した語');
      }
    }
    expect(localExamCategoriesForLevel(5), isNot(contains(ExamCategory.sanji)));
    expect(localExamCategoriesForLevel(8), isNot(contains(ExamCategory.sanji)));
  });
}
