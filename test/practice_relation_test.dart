import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/data/word_relation_data.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 漢検の「対義語・類義語」に合わせた演習。
void main() {
  const levels = ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2'];
  final allKanji = <String>{for (final l in levels) ...LevelKanjiData.forLevel(l)};
  final hira = RegExp(r'^[ぁ-ゖー]+$');

  group('組のデータ（レビューの機械チェック）', () {
    test('2語とも2字以上・読みはひらがな・すべて10級〜2級の配当漢字', () {
      for (final r in kWordRelations) {
        for (final w in [r.word, r.partner]) {
          expect(w.runes.length, inInclusiveRange(2, 4), reason: w);
          expect(allKanji.containsAll(w.split('')), isTrue, reason: w);
        }
        expect(hira.hasMatch(r.reading), isTrue, reason: r.word);
        expect(hira.hasMatch(r.partnerReading), isTrue, reason: r.partner);
        expect(r.word, isNot(r.partner), reason: r.word);
      }
    });

    test('同じ種類で同じ組の重複がなく、対義語と類義語が同じ組にならない', () {
      final seen = <String, WordRelationKind>{};
      for (final r in kWordRelations) {
        final key = ([r.word, r.partner]..sort()).join('|');
        final kind = seen[key];
        expect(kind, isNull, reason: '${r.word}-${r.partner} が重複、または対義語と類義語の両方');
        seen[key] = r.kind;
      }
    });

    test('読みの長さが語に見合っている（語の字数以上、字数の4倍以下）', () {
      for (final r in kWordRelations) {
        expect(r.reading.length, inInclusiveRange(r.word.length, r.word.length * 4), reason: r.word);
        expect(r.partnerReading.length,
            inInclusiveRange(r.partner.length, r.partner.length * 4), reason: r.partner);
      }
    });
  });

  group('出す級', () {
    test('対義語は8級〜2級、類義語は6級〜2級だけに出る', () {
      for (final l in ['LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) {
        expect(availableModesForLevel(l), contains(PracticeMode.antonym), reason: l);
      }
      for (final l in ['LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2']) {
        expect(availableModesForLevel(l), contains(PracticeMode.synonym), reason: l);
      }
      for (final l in ['LEVEL_10', 'LEVEL_9', 'LEVEL_1_PRE', 'LEVEL_1']) {
        expect(availableModesForLevel(l), isNot(contains(PracticeMode.antonym)), reason: l);
        expect(wordRelationsForLevel(l, WordRelationKind.antonym), isEmpty, reason: l);
      }
      for (final l in ['LEVEL_8', 'LEVEL_7']) {
        expect(availableModesForLevel(l), isNot(contains(PracticeMode.synonym)), reason: l);
        expect(wordRelationsForLevel(l, WordRelationKind.synonym), isEmpty, reason: l);
      }
    });

    test('出せる組は、その級以下の字だけでできている', () {
      for (final l in ['LEVEL_8', 'LEVEL_6', 'LEVEL_5']) {
        final upTo = <String>{
          for (final x in levels.sublist(0, levels.indexOf(l) + 1)) ...LevelKanjiData.forLevel(x),
        };
        for (final kind in WordRelationKind.values) {
          for (final r in wordRelationsForLevel(l, kind)) {
            expect(upTo.containsAll((r.word + r.partner).split('')), isTrue, reason: '$l ${r.word}');
          }
        }
      }
    });
  });

  group('選択肢', () {
    test('4つ・正解を含む・重複なし・問いの語や、関係のある語は入らない', () {
      final random = Random(7);
      for (final level in ['LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_2']) {
        for (final kind in WordRelationKind.values) {
          for (final r in wordRelationsForLevel(level, kind)) {
            for (final reversed in [false, true]) {
              final ch = wordRelationChoices(r, reversed, level, random);
              if (ch == null) continue; // 候補が足りない組は出題しない（書き取りに回る）
              final ask = reversed ? r.partner : r.word;
              final answer = reversed ? r.word : r.partner;
              expect(ch.length, 4, reason: '${r.word}');
              expect(ch.toSet().length, 4, reason: '${r.word}');
              expect(ch, contains(answer), reason: '${r.word}');
              expect(ch, isNot(contains(ask)), reason: '${r.word}');
              final related = <String>{};
              for (final x in kWordRelations) {
                if ({x.word, x.partner}.any({ask, answer}.contains)) {
                  related..add(x.word)..add(x.partner);
                }
              }
              for (final c in ch.where((c) => c != answer)) {
                expect(related.contains(c), isFalse, reason: '${r.word} の選択肢に関係のある語 $c');
              }
            }
          }
        }
      }
    });

    test('5級以上では、ほとんどの組で選択肢が作れる（作れない組は少数）', () {
      final random = Random(3);
      for (final kind in WordRelationKind.values) {
        final rs = wordRelationsForLevel('LEVEL_5', kind);
        final ok = rs.where((r) => wordRelationChoices(r, false, 'LEVEL_5', random) != null).length;
        expect(ok / rs.length, greaterThan(0.9), reason: '$kind');
      }
    });
  });
}
