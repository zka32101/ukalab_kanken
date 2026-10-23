import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/data/yoji_jukugo_data.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 漢検の「四字熟語」に合わせた、空欄を埋める演習。
void main() {
  final allKanji = <String>{
    for (final l in [
      'LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5',
      'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2',
    ])
      ...LevelKanjiData.forLevel(l),
  };
  final hira = RegExp(r'^[ぁ-ゖー]+$');

  group('四字熟語データ（レビューの機械チェック）', () {
    test('語は4字・読みはひらがな・意味あり・重複なし・すべて10級〜2級の配当漢字', () {
      final seen = <String>{};
      for (final y in kYojiJukugo) {
        expect(y.word.runes.length, 4, reason: y.word);
        expect(allKanji.containsAll(y.word.split('')), isTrue, reason: y.word);
        expect(hira.hasMatch(y.reading), isTrue, reason: '${y.word} ${y.reading}');
        expect(y.meaning.trim(), isNotEmpty, reason: y.word);
        expect(seen.add(y.word), isTrue, reason: '${y.word} が重複');
      }
    });

    test('読みの長さが、語の長さ（4字）に見合っている（4〜12音）', () {
      for (final y in kYojiJukugo) {
        expect(y.reading.length, inInclusiveRange(4, 12), reason: y.word);
      }
    });

    test('level は、語の字のうち最も難しい級', () {
      const rank = {
        'LEVEL_10': 10, 'LEVEL_9': 9, 'LEVEL_8': 8, 'LEVEL_7': 7, 'LEVEL_6': 6,
        'LEVEL_5': 5, 'LEVEL_4': 4, 'LEVEL_3': 3, 'LEVEL_2_PRE': 2.5, 'LEVEL_2': 2,
      };
      for (final y in kYojiJukugo) {
        final hardest = y.word
            .split('')
            .map((c) => [
                  for (final e in rank.entries)
                    if (LevelKanjiData.forLevel(e.key).contains(c)) e.value
                ].first)
            .reduce(min);
        expect(rank[y.level], hardest, reason: y.word);
      }
    });
  });

  group('出す級と語数', () {
    test('四字熟語は5級〜2級だけに出る', () {
      for (final l in ['LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) {
        expect(availableModesForLevel(l), contains(PracticeMode.yoji), reason: l);
      }
      for (final l in ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_1_PRE', 'LEVEL_1']) {
        expect(availableModesForLevel(l), isNot(contains(PracticeMode.yoji)), reason: l);
        expect(yojiForLevel(l), isEmpty, reason: l);
      }
    });

    test('級が上がるほど、出せる語が増える（その級以下の字だけの語）', () {
      final counts = [
        for (final l in ['LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2'])
          yojiForLevel(l).length,
      ];
      expect(counts.first, greaterThanOrEqualTo(40));
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i], greaterThanOrEqualTo(counts[i - 1]));
      }
    });

    test('5級の語は、5級以下の字だけでできている', () {
      final upTo5 = <String>{
        for (final l in ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5'])
          ...LevelKanjiData.forLevel(l),
      };
      for (final y in yojiForLevel('LEVEL_5')) {
        expect(upTo5.containsAll(y.word.split('')), isTrue, reason: y.word);
      }
    });
  });

  group('空欄の選択肢', () {
    test('4つ・正解を含む・重複なし・語にある他の字や、別の四字熟語になる字は入らない', () {
      final random = Random(1);
      for (final level in ['LEVEL_5', 'LEVEL_4', 'LEVEL_2']) {
        for (final y in yojiForLevel(level)) {
          for (var i = 0; i < 4; i++) {
            final ch = yojiBlankChoices(y.word, i, level, random);
            expect(ch.length, 4, reason: '${y.word} $i');
            expect(ch.toSet().length, 4, reason: '${y.word} $i');
            expect(ch, contains(y.word[i]), reason: '${y.word} $i');
            for (final c in ch.where((c) => c != y.word[i])) {
              expect(y.word.contains(c), isFalse, reason: '${y.word} に $c');
              final cand = y.word.replaceRange(i, i + 1, c);
              expect(kYojiJukugo.any((z) => z.word == cand), isFalse, reason: cand);
            }
          }
        }
      }
    });
  });
}
