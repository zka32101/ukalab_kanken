import 'package:app_common_kit/app_common_kit.dart';
import 'package:app_common_kit/hands_free_tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/kanji_question.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';
import 'package:kanken/widgets/hands_free_practice_body.dart';

/// ながら学習モード（app_common_kit）と漢検アプリの連携テスト。
PracticeQuestion _question(String prompt, String correct, List<String> choices) {
  final source = KanjiQuestion.fromJson({
    'id': prompt,
    'level': 'LEVEL_10',
    'kanji': prompt,
    'questionType': 'multipleChoice',
    'choices': choices,
    'correctAnswer': correct,
  });
  return PracticeQuestion(
    source: source,
    actualMode: PracticeMode.reading,
    prompt: prompt,
    instruction: 'この漢字の読み方は？',
    choices: choices,
    correctAnswer: correct,
  );
}

({ProviderContainer container, FakeSpeechBackend speech}) _setup() {
  final speech = FakeSpeechBackend();
  final container = ProviderContainer(overrides: [
    handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
    speechBackendProvider.overrideWithValue(speech),
  ]);
  addTearDown(container.dispose);
  return (container: container, speech: speech);
}

Widget _body(ProviderContainer container, PracticeQuestion q, int index, void Function(bool) onAnswer) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: HandsFreePracticeBody(question: q, index: index, total: 10, onAnswer: onAnswer),
        ),
      ),
    );

void main() {
  testWidgets('モードが有効なら、問題を自動で読み上げ、選択肢は大きなボタンで出る', (tester) async {
    final s = _setup();
    await s.container.read(handsFreeProvider.notifier).setEnabled(true);
    final q = _question('山', 'やま', ['やま', 'かわ', 'そら']);

    await tester.pumpWidget(_body(s.container, q, 0, (_) {}));
    await tester.pump();

    expect(s.speech.spoken.single, contains('山'));
    expect(s.speech.spoken.single, contains('ア、やま。イ、かわ。ウ、そら。'));
    expect(find.byType(HandsFreeChoiceTile), findsNWidgets(3));
    expect(tester.getSize(find.byType(HandsFreeChoiceTile).first).height >= 72, isTrue);
  });

  testWidgets('次の問題に進むと、また読み上げる。同じ問題の再描画では読み直さない', (tester) async {
    final s = _setup();
    await s.container.read(handsFreeProvider.notifier).setEnabled(true);

    await tester.pumpWidget(_body(s.container, _question('山', 'やま', ['やま', 'かわ']), 0, (_) {}));
    await tester.pump();
    await tester.pumpWidget(_body(s.container, _question('山', 'やま', ['やま', 'かわ']), 0, (_) {}));
    await tester.pump();
    expect(s.speech.spoken.length, 1);

    await tester.pumpWidget(_body(s.container, _question('川', 'かわ', ['やま', 'かわ']), 1, (_) {}));
    await tester.pump();
    expect(s.speech.spoken.length, 2);
    expect(s.speech.spoken.last, contains('川'));
  });

  testWidgets('「問題を読み上げる」をオフにすると自動では読まないが、読み上げボタンは読む', (tester) async {
    final s = _setup();
    await s.container.read(handsFreeProvider.notifier).setEnabled(true);
    await s.container.read(handsFreeProvider.notifier).setSpeakQuestion(false);

    await tester.pumpWidget(_body(s.container, _question('山', 'やま', ['やま', 'かわ']), 0, (_) {}));
    await tester.pump();
    expect(s.speech.spoken, isEmpty);

    await tester.tap(find.byType(ReadAloudButton));
    await tester.pump();
    expect(s.speech.spoken.single, contains('山'));
  });

  testWidgets('選択肢をタップすると、正解かどうかが渡る', (tester) async {
    final s = _setup();
    await s.container.read(handsFreeProvider.notifier).setEnabled(true);
    final answers = <bool>[];

    await tester.pumpWidget(_body(s.container, _question('山', 'やま', ['やま', 'かわ']), 0, answers.add));
    await tester.pump();
    await tester.tap(find.text('かわ'));
    await tester.tap(find.text('やま'));

    expect(answers, [false, true]);
  });

  test('設定は保存され、load で復元できる', () async {
    final store = InMemoryHandsFreeStore();
    final first = ProviderContainer(overrides: [handsFreeStoreProvider.overrideWithValue(store)]);
    addTearDown(first.dispose);
    await first.read(handsFreeProvider.notifier).setEnabled(true);

    final second = ProviderContainer(overrides: [handsFreeStoreProvider.overrideWithValue(store)]);
    addTearDown(second.dispose);
    await second.read(handsFreeProvider.notifier).load();

    expect(second.read(handsFreeProvider).enabled, isTrue);
  });

  test('読み上げの速さは flutter_tts の範囲（0.1〜1.0）に変換する', () {
    expect(FlutterTtsSpeechBackend.ttsRate(1.0), 0.5);
    expect(FlutterTtsSpeechBackend.ttsRate(0.5), 0.25);
    expect(FlutterTtsSpeechBackend.ttsRate(1.5), 0.75);
    expect(FlutterTtsSpeechBackend.ttsRate(0.0), 0.1);
    expect(FlutterTtsSpeechBackend.ttsRate(9.0), 1.0);
  });
}
