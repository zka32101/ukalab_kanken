import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/bundled_questions.dart';
import 'package:kanken/data/koji_data.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';

/// 漢検の「故事・諺」（準1級・1級）に合わせた、空欄を埋める演習。
void main() {
  const levels = [
    'LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3',
    'LEVEL_2_PRE', 'LEVEL_2', 'LEVEL_1_PRE', 'LEVEL_1',
  ];
  final allKanji = <String>{for (final l in levels) ...LevelKanjiData.forLevel(l)};
  final kanji = RegExp(r'[一-鿿]');
  final hira = RegExp(r'^[ぁ-ゖー、]+$');

  test('データ: 読みはひらがな・意味あり・配当漢字だけ・重複なし', () {
    final seen = <String>{};
    for (final k in kKoji) {
      expect(hira.hasMatch(k.reading), isTrue, reason: '${k.phrase} ${k.reading}');
      expect(k.meaning.trim(), isNotEmpty, reason: k.phrase);
      expect(RegExp(r'[\[\]{}<>|]').hasMatch(k.meaning), isFalse, reason: k.phrase);
      final chars = k.phrase.split('').where(kanji.hasMatch);
      expect(chars.length, greaterThanOrEqualTo(2), reason: k.phrase);
      expect(allKanji.containsAll(chars), isTrue, reason: k.phrase);
      expect(seen.add(k.phrase), isTrue, reason: '${k.phrase} が重複');
    }
    expect(kKoji.length, greaterThanOrEqualTo(80));
  });

  test('故事・諺は準1級・1級だけに出る', () {
    for (final l in ['LEVEL_1_PRE', 'LEVEL_1']) {
      expect(availableModesForLevel(l), contains(PracticeMode.koji), reason: l);
      expect(kojiForLevel(l), isNotEmpty, reason: l);
    }
    for (final l in levels.sublist(0, 10)) {
      expect(availableModesForLevel(l), isNot(contains(PracticeMode.koji)), reason: l);
      expect(kojiForLevel(l), isEmpty, reason: l);
    }
    expect(kojiForLevel('LEVEL_1').length, kKoji.length);
    expect(kojiForLevel('LEVEL_1_PRE').length, lessThan(kKoji.length));
  });

  test('空欄の選択肢: 4つ・正解を含む・重複なし・語にある字は入らない', () {
    final random = Random(3);
    for (final k in kKoji) {
      for (var i = 0; i < k.phrase.length; i++) {
        if (!kanji.hasMatch(k.phrase[i])) continue;
        final choices = kojiBlankChoices(k.phrase, i, 'LEVEL_1', random);
        expect(choices, contains(k.phrase[i]), reason: k.phrase);
        expect(choices.toSet().length, choices.length, reason: k.phrase);
        expect(choices.length, 4, reason: '${k.phrase} $i');
        for (final c in choices) {
          if (c != k.phrase[i]) expect(k.phrase.contains(c), isFalse, reason: '${k.phrase} $c');
        }
      }
    }
  });

  test('演習の問題: □が1つ・答えは空欄の字・準1級・1級で作れる', () async {
    final b = BundledQuestions(loader: () async => File('assets/questions/kanken_questions.json').readAsString());
    final qs = await b.forLevel('LEVEL_2');
    for (final l in ['LEVEL_1_PRE', 'LEVEL_1']) {
      final built = buildKanjiPracticeQuestions(qs.take(40).toList(), PracticeMode.koji, l);
      expect(built, isNotEmpty);
      for (final q in built) {
        expect(q.actualMode, PracticeMode.koji, reason: l);
        expect('□'.allMatches(q.prompt).length, 1, reason: q.prompt);
        expect(q.choices, contains(q.correctAnswer), reason: q.prompt);
        // 空欄に答えを入れると、故事・諺の語になる
        final full = q.prompt.replaceFirst('□', q.correctAnswer);
        expect(kKoji.any((k) => k.phrase == full), isTrue, reason: full);
      }
    }
  });
}
