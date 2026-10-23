import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/local_exam_questions.dart';
import 'package:kanken/data/word_relation_data.dart';
import 'package:kanken/models/mock_exam_modes.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 対義語・類義語を、漢検の例題と同じ「集合−□散」の形（□に入る漢字を選ぶ）にする。
void main() {
  final knownWords = <String>{
    for (final r in kWordRelations) ...[r.word, r.partner],
  };

  group('□の問題', () {
    test('□は相手の語の1字・選択肢は4つで正解を含み重複しない', () {
      final random = Random(7);
      var made = 0;
      for (final level in ['LEVEL_8', 'LEVEL_6', 'LEVEL_5', 'LEVEL_2']) {
        for (final kind in WordRelationKind.values) {
          for (final r in wordRelationsForLevel(level, kind)) {
            for (final reversed in [false, true]) {
              final b = wordRelationBlank(r, reversed, level, random);
              if (b == null) continue;
              made++;
              final partner = reversed ? r.word : r.partner;
              final ask = reversed ? r.partner : r.word;
              expect(b.askWord, ask, reason: r.word);
              expect(b.partner, partner, reason: r.word);
              expect(b.partnerWithBlank.runes.length, 2, reason: r.word);
              expect('□'.allMatches(b.partnerWithBlank).length, 1, reason: r.word);
              // □に正解の字を入れると、相手の語になる。
              expect(b.partnerWithBlank.replaceFirst('□', b.answerChar), partner, reason: r.word);
              expect(b.choices.length, 4, reason: r.word);
              expect(b.choices.toSet().length, 4, reason: r.word);
              expect(b.choices, contains(b.answerChar), reason: r.word);
            }
          }
        }
      }
      expect(made, greaterThan(100));
    });

    test('正解以外の字を□に入れても、問いの語や、データにある別の語にならない', () {
      final random = Random(3);
      for (final level in ['LEVEL_8', 'LEVEL_5', 'LEVEL_2']) {
        for (final kind in WordRelationKind.values) {
          for (final r in wordRelationsForLevel(level, kind)) {
            final b = wordRelationBlank(r, false, level, random);
            if (b == null) continue;
            for (final c in b.choices.where((c) => c != b.answerChar)) {
              final candidate = b.partnerWithBlank.replaceFirst('□', c);
              expect(candidate, isNot(b.askWord), reason: '${r.word} に $c');
              expect(knownWords.contains(candidate), isFalse,
                  reason: '${r.word}―$candidate は、データにある語');
            }
          }
        }
      }
    });

    test('相手の語が2字でない組は、□の形にしない（語を選ぶ形に回す）', () {
      for (final r in kWordRelations.where((r) => r.partner.runes.length != 2)) {
        expect(wordRelationBlank(r, false, 'LEVEL_2', Random(1)), isNull, reason: r.partner);
      }
    });

    test('ほとんどの組で、□の形が作れる', () {
      final random = Random(5);
      for (final kind in WordRelationKind.values) {
        final rs = wordRelationsForLevel('LEVEL_5', kind);
        final ok = rs.where((r) => wordRelationBlank(r, false, 'LEVEL_5', random) != null).length;
        expect(ok / rs.length, greaterThan(0.8), reason: '$kind');
      }
    });
  });

  group('共通の選択肢の作り方', () {
    test('kanjiBlankChoices: 使えない字は選択肢に入らない・誤答が作れなければ null', () {
      final ch = kanjiBlankChoices('山', 'LEVEL_8', Random(1), isUsable: (c) => c != '川')!;
      expect(ch.length, 4);
      expect(ch, contains('山'));
      expect(ch, isNot(contains('川')));
      expect(kanjiBlankChoices('山', 'LEVEL_8', Random(1), isUsable: (_) => false), isNull);
    });

    test('四字熟語の空欄は、これまでどおり（4つ・正解を含む）', () {
      final ch = yojiBlankChoices('一石二鳥', 3, 'LEVEL_5', Random(2));
      expect(ch.length, 4);
      expect(ch, contains('鳥'));
    });
  });

  test('模擬試験の対義語・類義語も、□の形で作られる（作れない組は語を選ぶ形）', () {
    final qs = buildLocalExamQuestions(
        level: 5, categories: [ExamCategory.antonym, ExamCategory.synonym], count: 20, random: Random(4));
    expect(qs, isNotEmpty);
    expect(qs.any((q) => q.question.contains('□')), isTrue);
    for (final q in qs) {
      expect(q.options.toSet().length, q.options.length, reason: q.questionId);
      expect(q.options, contains(q.correctAnswer), reason: q.questionId);
    }
  });
}
