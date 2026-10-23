import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/kanji_question.dart';
import 'package:kanken/views/weak_kanji_mode_screen.dart';

/// 苦手集中トレーニングは、答えの漢字そのものを問題として出さない（読み方を出す）。
KanjiQuestion _q({String? reading}) => KanjiQuestion(
      id: 'LEVEL_10-五',
      level: 'LEVEL_10',
      kanji: '五',
      questionType: QuestionType.multipleChoice,
      choices: const ['出', '気', '手', '五'],
      correctAnswer: '五',
      version: 1,
      reading: reading,
    );

void main() {
  test('読み方があるときは、読み方を出して「この読み方の漢字はどれ？」と聞く', () {
    final q = _q(reading: 'ご');
    expect(weakKanjiPrompt(q), 'ご');
    expect(weakKanjiPrompt(q), isNot(q.kanji), reason: '答えの漢字を出さない');
    expect(weakKanjiPromptIsReading(q), isTrue);
    expect(weakKanjiInstruction(q), 'この読み方の漢字はどれ？');
  });

  test('読み方が無い問題は、漢字を出すしかない（指示文はそれに合わせる）', () {
    for (final r in [null, '']) {
      final q = _q(reading: r);
      expect(weakKanjiPrompt(q), '五');
      expect(weakKanjiPromptIsReading(q), isFalse);
      expect(weakKanjiInstruction(q), 'この漢字と同じものはどれ？');
    }
  });
}
